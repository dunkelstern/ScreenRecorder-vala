using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class V4l2Window: PlaybackWindow {
        private V4l2ButtonConfig _config;
        public override ButtonConfig config {
            get {
                return _config;
            }
            set {
                _config = value as V4l2ButtonConfig;
            }
        }

        private Button settings_button;
        private Button focus_button;
        private Gst.Element scaler_object;

        public V4l2Window(V4l2ButtonConfig config) {
            base(config);

            // button to open v4l2 configuration panel
            settings_button = new Gtk.Button();
            var icon = new ThemedIcon("preferences-system");
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            settings_button.image = image;
            settings_button.clicked.connect(on_settings);
            header.pack_end(settings_button);

            // button to re-focus the camera
            focus_button = new Gtk.Button();
            icon = new ThemedIcon("video-display-symbolic");
            image = new Image.from_gicon(icon, IconSize.BUTTON);
            focus_button.image = image;
            focus_button.clicked.connect(on_focus);
            header.pack_end(focus_button);

            build_pipeline();
            this.setup((int)config.width / 2, (int)config.height / 2, true);
        }

        private void build_pipeline() {
            var src = new Gst.Bin("src");

            // v4l2 input
            var v4lsrc = Gst.ElementFactory.make("v4l2src", "source");
            v4lsrc.set("device", this._config.device);
            src.add(v4lsrc);

            var src_queue = Gst.ElementFactory.make("queue", "src_queue");
            src.add(src_queue);
            v4lsrc.link(src_queue);

            // camera config
            var cap_string_builder = new StringBuilder("");
            cap_string_builder.printf(
                "%s,width=%d,height=%d,framerate=%d/1",
                this._config.format,
                (int)this._config.width,
                (int)this._config.height,
                (int)this._config.framerate
            );
            var caps = Gst.Caps.from_string(cap_string_builder.str);
            var filter = Gst.ElementFactory.make("capsfilter", "input_filter");
            filter.set("caps", caps);
            src.add(filter);
            src_queue.link(filter);

            // decoder
            if (this._config.format == "image/jpeg") {
                // jpeg decoder
                var parser = Gst.ElementFactory.make("jpegparse", "parser");
                src.add(parser);
                filter.link(parser);

                Gst.Element decoder;
                if (this._config.hwaccel == "vaapi") {
                    decoder = Gst.ElementFactory.make("vaapijpegdec", "decoder");
                } else {
                    decoder = Gst.ElementFactory.make("jpegdec", "decoder");
                }

                src.add(decoder);
                parser.link(decoder);

                var decoder_queue = Gst.ElementFactory.make("queue", "decoder_queue");
                src.add(decoder_queue);
                decoder.link(decoder_queue);

                var ghost_src = new Gst.GhostPad("src", decoder_queue.get_static_pad("src"));
                src.add_pad(ghost_src);
            } else {
                // no decoder needed
                var ghost_src = new Gst.GhostPad("src", filter.get_static_pad("src"));
                src.add_pad(ghost_src);
            }

            // scaler
            var scaler = new Gst.Bin("scaler");
            if (this._config.hwaccel == "vaapi") {
                // hardware accelerated scaler
                this.scaler_object = Gst.ElementFactory.make("vaapipostproc", "scaler");
                this.scaler_object.set("width", this._config.width / 2);
                this.scaler_object.set("height", this._config.height / 2);
                this.scaler_object.set("scale-method", 2);
                scaler.add(this.scaler_object);

                var ghost_sink = new Gst.GhostPad("sink", this.scaler_object.get_static_pad("sink"));
                var ghost_src = new Gst.GhostPad("src", this.scaler_object.get_static_pad("src"));
                scaler.add_pad(ghost_sink);
                scaler.add_pad(ghost_src);
            } else {
                // software scaling
                var videoscale = Gst.ElementFactory.make("videoscale", "scaler");
                scaler.add(videoscale);

                var scale_cap_string_builder = new StringBuilder("");
                scale_cap_string_builder.printf(
                    "video/x-raw,width=%d,height=%d",
                    (int)this._config.width,
                    (int)this._config.height
                );
                var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
                this.scaler_object = Gst.ElementFactory.make("capsfilter", "scaler_filter");
                this.scaler_object.set("caps", scale_caps);
                scaler.add(this.scaler_object);

                videoscale.link(this.scaler_object);

                var ghost_sink = new Gst.GhostPad("sink", videoscale.get_static_pad("sink"));
                var ghost_src = new Gst.GhostPad("src", this.scaler_object.get_static_pad("src"));
                scaler.add_pad(ghost_sink);
                scaler.add_pad(ghost_src);
            }

            // output stage
            var sink = new PlaybackBin(this._config.hwaccel, false);

            // assemble pipeline
            this.pipeline = new Gst.Pipeline("playback");
            this.pipeline.add(src);
            this.pipeline.add(scaler);
            this.pipeline.add(sink);
            src.link(scaler);
            scaler.link(sink);
        }

        protected override void stop() {
            base.stop();
            this.hide();
        }

        private void on_focus(Button source) {
            try {
                // turn on auto focusing
                var launcher = new SubprocessLauncher(SubprocessFlags.NONE);
                launcher.spawnv({ "/usr/bin/v4l2-ctl", "-d", this._config.device, "-c", "focus_auto=1" });
                
                // after 8 seconds turn of focusing (yes some cameras are that slow!)
                Timeout.add_seconds(8, () => {
                    try {
                        launcher.spawnv({ "/usr/bin/v4l2-ctl", "-d", this._config.device, "-c", "focus_auto=1" });
                    } catch (Error e) {
                        // nothing
                    }
                    return false;
                });
            } catch (Error e) {
                stderr.printf("Could not run focus command: %s", e.message);
            }
        }

        private void on_settings(Button source) {
            string[] settings_apps = {
                "/usr/bin/qv4l2",
                "/usr/bin/v4l2ucp"
            };

            // try all known apps that work to set camera settings without displaying
            // a output window
            foreach(var app in settings_apps) {
                var file = File.new_for_path(app);

                // check if the tool is installed
                if (file.query_exists()) {
                    try {
                        // try launching the tool, if successful break the loop
                        var launcher = new SubprocessLauncher(SubprocessFlags.NONE);
                        launcher.spawnv({app});
                        break;
                    } catch (Error e) {
                        stderr.printf("Could not launch config tool: %s", e.message);
                    }
                }
            }
        }
    }
}
