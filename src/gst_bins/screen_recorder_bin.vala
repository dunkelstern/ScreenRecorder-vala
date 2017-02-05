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
        private bool caps_set;

        public ScreenRecorderBin() {
            GLib.Object(name: "screen_recorder_src");
            this.sink = null;
            this.caps_set = false;

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

            appsink = Gst.ElementFactory.make("appsink", "appsink") as Gst.App.Sink;
            appsink.new_preroll.connect(new_preroll);
            appsink.new_sample.connect(new_sample);

            this.add(appsink);
            video_src.link(appsink);

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
            var sample = appsink.pull_sample();
            if (this.sink != null) {
                if (sample != null) {
                    if (!this.caps_set) {
                        var pad = video_src.get_static_pad("src");
                        var caps = pad.get_current_caps();
                        this.appsink.set_caps(caps);
                        this.sink.set_input_caps(caps);
                        this.caps_set = true;
                    }

                    this.sink.consume_sample(sample);

                    Gst.State st = Gst.State.NULL;
                    Gst.State pend = Gst.State.NULL;
                    this.sink.get_state(out st, out pend, 0);
                    if (st != Gst.State.PLAYING) {
                        stderr.printf("Sink consumed sample, status = %s, pending = %s\n", st.to_string(), pend.to_string());
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
            this.caps_set = false;
            appsink.set_emit_signals(true);
        }

        public void stop_emitting_buffers() {
            appsink.set_emit_signals(false);
            this.sink = null;
        }
    }
}