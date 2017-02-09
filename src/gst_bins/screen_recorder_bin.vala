using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class ScreenRecorderBin: Gst.Bin, ManualVideoRoutingSrc {
        private Gst.Element video_src;
        private Gst.App.Sink appsink;
        private ManualVideoRoutingSink? sink;

        public ScreenRecorderBin(VideoEncoderBin encoder) {
            GLib.Object(name: "screen_recorder_src");
            this.sink = null;

            var config = ConfigFile.instance().rec_settings;

            video_src = Gst.ElementFactory.make("ximagesrc", "video_src");
            video_src.set("display-name", ":0." + config.screen.to_string());
            video_src.set("use-damage", 0);
            video_src.set("startx", 0);
            video_src.set("starty", 0);
            video_src.set("endx", config.width - 1);
            video_src.set("endy", config.height - 1);
            video_src.set("do-timestamp", true);

            this.add(video_src);

            var convert = Gst.ElementFactory.make("autovideoconvert", "encoder_convert");
            var record_caps = Gst.ElementFactory.make("capsfilter", "encoder_capsfilter");
            record_caps.set("caps", encoder.get_input_caps());
            this.add(convert);
            this.add(record_caps);

            appsink = Gst.ElementFactory.make("appsink", "appsink") as Gst.App.Sink;
            appsink.new_preroll.connect(new_preroll);
            appsink.new_sample.connect(new_sample);
            this.add(appsink);

            video_src.link(convert);
            convert.link(record_caps);
            record_caps.link(appsink);

            appsink.set_emit_signals(true);

            // no usual src as we're using appsink

            // var ghost_src = new Gst.GhostPad("src", video_src.get_static_pad("src"));
            // this.add_pad(ghost_src);
        }

        private FlowReturn new_preroll() {
            stderr.printf("New preroll sample from Screen Recorder\n");
            appsink.pull_preroll();
            return FlowReturn.OK;
        }

        private FlowReturn new_sample() {
            stderr.printf("New sample from Screen Recorder\n");

            var sample = appsink.pull_sample();
            if (this.sink != null) {
                if (sample != null) {
                    var result = this.sink.consume_sample(sample);
                    if (result == false) {
                        this.stop_emitting_buffers();
                    }
                }
            }

            if (appsink.eos) {
                stderr.printf("End of stream in screen recorder\n");
            }
            return FlowReturn.OK;
        }

        public void start_emitting_buffers(ManualVideoRoutingSink sink) {
            this.sink = sink;
        }

        public void stop_emitting_buffers() {
            this.sink = null;
        }
    }
}