using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class RtmpWindow: PlaybackWindow {
        private RtmpButtonConfig _config;
        public override ButtonConfig config {
            get {
                return _config;
            }
            set {
                _config = value as RtmpButtonConfig;
            }
        }

        private Gst.Element src;
        private Gst.Element parser;
        private Gst.Element decoder;
        private Gst.Element sink;
        private Gst.Element fake_sink;

        public RtmpWindow(RtmpButtonConfig config, MainWindow main_window) {
            base(config, main_window);
            this.auto_start = true;
            build_pipeline();
            this.setup((int)config.max_width / 2, (int)config.max_height / 2, true);
        }

        private void build_pipeline() {
            // uri parser
            src = Gst.ElementFactory.make("urisourcebin", "source");
            src.set("uri", this._config.url);
            src.pad_added.connect(pad_added);

            // parser bin
            parser = Gst.ElementFactory.make("parsebin", "parser");
            parser.pad_added.connect(pad_added);

            // decoder
            decoder = Gst.ElementFactory.make("avdec_h264", "decoder");

            // sink
            sink = new PlaybackBin(this._config.hwaccel, false);
            fake_sink = Gst.ElementFactory.make("fakesink", "audiosink");

            // assemble pipeline
            this.pipeline = new Gst.Pipeline("playback");
            this.pipeline.add(src);

            // connection happens in pad_added
        }

        private void pad_added(Gst.Element src, Gst.Pad pad) {
            if ((src == this.src) && (pad.get_name() == "src_0")) {
                this.pipeline.add(parser);
                pad.link(this.parser.get_static_pad("sink"));
                this.parser.sync_state_with_parent();
            }

            if (src == this.parser) {
                if (pad.get_current_caps().to_string().has_prefix("audio")) {
                    this.pipeline.add(this.fake_sink);
                    pad.link(this.fake_sink.get_static_pad("sink"));
                    this.fake_sink.sync_state_with_parent();
                    return;
                }

                this.pipeline.add(this.decoder);
                pad.link(this.decoder.get_static_pad("sink"));
                this.pipeline.add(this.sink);
                this.decoder.link(this.sink);
                this.decoder.sync_state_with_parent();
                this.sink.sync_state_with_parent();
                dump_pipeline(this.pipeline);
            }
        }

        protected override void stop() {
            base.stop();
            this.hide();
        }
    }
}
