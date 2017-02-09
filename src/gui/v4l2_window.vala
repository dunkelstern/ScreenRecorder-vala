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
        private Gst.Element pre_scaler_object;

        public V4l2Window(V4l2ButtonConfig config, MainWindow main_window) {
            base(config, main_window);

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

            // tee to exclusively record

            tee = Gst.ElementFactory.make("tee", "tee");

            var template = new Gst.PadTemplate("src_%u", PadDirection.SRC, PadPresence.REQUEST, new Caps.any());
            var tee_src1 = tee.request_pad(template, null, null);
            var tee_src2 = tee.request_pad(template, null, null);

            appsink = Gst.ElementFactory.make("appsink", "appsink") as Gst.App.Sink;
            appsink.new_preroll.connect(new_preroll);
            appsink.new_sample.connect(new_sample);
            appsink.drop = true;
            appsink.emit_signals = true;

            // scaler
            var scaler = new Gst.Bin("scaler");
            Element videoscale;
            if (this._config.hwaccel == "vaapi") {
                // hardware accelerated scaler
                videoscale = Gst.ElementFactory.make("vaapipostproc", "scaler");
                videoscale.set("scale-method", 2);
            } else {
                // software scaling
                videoscale = Gst.ElementFactory.make("videoscale", "scaler");
            }
            scaler.add(videoscale);
            this.pre_scaler_object = videoscale;

            var scale_cap_string_builder = new StringBuilder("");
            scale_cap_string_builder.printf(
                "video/x-raw,width=%d,height=%d",
                (int)this._config.width/2,
                (int)this._config.height/2
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

            // output stage
            var sink = new PlaybackBin(this._config.hwaccel, false);

            var tee_queue1 = Gst.ElementFactory.make("queue", "tee_queue1");
            var tee_queue2 = Gst.ElementFactory.make("queue", "tee_queue2");

            var convert = Gst.ElementFactory.make("autovideoconvert", "encoder_convert");
            var record_caps = Gst.ElementFactory.make("capsfilter", "encoder_capsfilter");
            record_caps.set("caps", main_window.video_encoder.get_input_caps());

            // assemble pipeline
            this.pipeline = new Gst.Pipeline("playback");
            this.pipeline.add(src);
            this.pipeline.add(tee);
            this.pipeline.add(tee_queue1);
            this.pipeline.add(tee_queue2);
            this.pipeline.add(convert);
            this.pipeline.add(record_caps);
            this.pipeline.add(appsink);
            this.pipeline.add(scaler);
            this.pipeline.add(sink);
            src.link(tee);
            tee_src1.link(tee_queue1.get_static_pad("sink"));
            tee_src2.link(tee_queue2.get_static_pad("sink"));
            tee_queue1.link(scaler);
            tee_queue2.link(convert);
            convert.link(record_caps);
            record_caps.link(appsink);
            scaler.link(sink);

            stderr.puts("V4l2 Pipeline:");
            dump_pipeline(this.pipeline);
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

        protected override void on_zoom(Button source) {
            this.zoomed = !this.zoomed;
            var pad = this.pre_scaler_object.get_static_pad("src");
            pad.add_probe(PadProbeType.BLOCK_DOWNSTREAM, this.block_input);
        }

        private PadProbeReturn block_input(Pad pad, PadProbeInfo info) {
            pad.remove_probe(info.id);

            // change scale
            int divisor;
            if (this.zoomed) {
                divisor = 1;
            } else {
                divisor = 2;
            }

            int width = (int)this._config.width / divisor;
            int height = (int)this._config.height / divisor;

            stderr.printf("On Zoom, %d, %d\n", width, height);

            var scale_cap_string_builder = new StringBuilder("");
            scale_cap_string_builder.printf(
                "video/x-raw,width=%d,height=%d",
                width,
                height
            );
            var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
            this.scaler_object.set("caps", scale_caps);

            this.video_area.set_size_request(width, height);
            this.set_default_size(width, height);
            this.resize(width, height);

            return PadProbeReturn.OK;
        }
    }
}
