using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class MjpegWindow: PlaybackWindow {
        private MjpegButtonConfig _config;
        public override ButtonConfig config {
            get {
                return _config;
            }
            set {
                _config = value as MjpegButtonConfig;
            }
        }

        private Gst.Element scaler_object;
        private Gst.Element pipesrc;
        private Pid subprocess;

        public MjpegWindow(MjpegButtonConfig config) {
            base(config);
            build_pipeline();
            this.setup((int)config.width / 2, (int)config.height / 2, true);
        }

        private void build_pipeline() {
            var src = new Gst.Bin("src");

            // pipe input
            this.pipesrc = Gst.ElementFactory.make("fdsrc", "source");
            src.add(this.pipesrc);

            var src_queue = Gst.ElementFactory.make("queue", "src_queue");
            src.add(src_queue);
            pipesrc.link(src_queue);

            // stream config
            var caps = Gst.Caps.from_string("image/jpeg,framerate=0/1");
            var filter = Gst.ElementFactory.make("capsfilter", "input_filter");
            filter.set("caps", caps);
            src.add(filter);
            src_queue.link(filter);

            // parser
            var parser = Gst.ElementFactory.make("jpegparse", "parser");
            src.add(parser);
            filter.link(parser);

            // decoder
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

            // create ghost pad
            var src_ghost_src = new Gst.GhostPad("src", decoder_queue.get_static_pad("src"));
            src.add_pad(src_ghost_src);

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
            var sink = PlaybackBin.make(this._config.hwaccel, false);

            // assemble pipeline
            this.pipeline = new Gst.Pipeline("playback");
            this.pipeline.add(src);
            this.pipeline.add(scaler);
            this.pipeline.add(sink);
            src.link(scaler);
            scaler.link(sink);
        }

        protected override void stop() {
            Posix.kill(this.subprocess, 9); // Kill subprocess
            Process.close_pid(this.subprocess);
            base.stop();
            this.hide();
        }

        protected override void play() {
            try {

                // prepare subprocess
                string[]? args = null;
                Shell.parse_argv (this._config.command, out args);
                string[] env = Environ.get();
                string workdir = Environment.get_current_dir();

                int std_in = -1;
                int std_out = -1;
                int std_err = -1;

                if (args != null) {
                    // run subprocess
                    Process.spawn_async_with_pipes(
                        workdir,
                        args,
                        env,
                        SpawnFlags.SEARCH_PATH,
                        null,
                        out this.subprocess,
                        out std_in,
                        out std_out,
                        out std_err
                    );

                    // all messages from stderr will be copied to our stderr
                    IOChannel error = new IOChannel.unix_new(std_err);
                    error.add_watch(IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                        try {
                            string line;
                            channel.read_line(out line, null, null);
                            if (line != null) {
                                stderr.puts(line);
                                } else {
                                    return false;
                                }
                        } catch (Error e) {
                            stderr.printf("IOChannel Error: %s\n", e.message);
                            return false;
                        }
                        return true;
                    });
                }
    
                // stdout will be connected to the pipeline
                this.pipesrc.set("fd", std_out);

                // now run the thing
                base.play();
            } catch (Error e) {
                stderr.printf("Error starting MJPEG pipe source: %s\n", e.message);
            }
        }
    }
}
