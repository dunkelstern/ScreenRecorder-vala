using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class MuxerBin: Gst.Bin {
        private string muxer;
        private Gst.Element filesink;
        private Gst.Element out_queue;
        private Gst.Element used_muxer;

        public MuxerBin(string muxer) {
            GLib.Object(name: "muxer");
            this.muxer = muxer;

            // output part of pipeline
            out_queue = Gst.ElementFactory.make("multiqueue", "out_queue");
            this.add(out_queue);
            out_queue.pad_added.connect(mux_pad_added);

            switch(muxer) {
                case "mpegts":
                    used_muxer = Gst.ElementFactory.make("mpegtsmux", "muxer");
                    break;
                case "mkv":
                    used_muxer = Gst.ElementFactory.make("matroskamux", "muxer");
                    break;
                case "mp4":
                    used_muxer = Gst.ElementFactory.make("mp4mux", "muxer");
                    break;
                default:
                    stderr.printf("Error: unknown muxer '%s'\n", muxer);
                    return;
            }
            this.add(used_muxer);

            filesink = Gst.ElementFactory.make("filesink", "filesink");
            filesink.set("sync", false);
            this.add(filesink);
            used_muxer.link(filesink);
        }

        private void mux_pad_added(Gst.Element src, Gst.Pad pad) {
            stderr.printf("Pad added: %s -> %s (caps: %s)\n", src.name, pad.name, pad.get_current_caps().to_string());
            PadLinkReturn result;
            if ((src == this.out_queue) && (pad.direction == PadDirection.SRC)) {
                switch(this.muxer) {
                    case "mpegts": {
                        var mux_pad = used_muxer.get_request_pad("sink_%d");
                        result = pad.link(mux_pad);
                        break;      
                    }                  
                    case "mkv":
                    case "mp4": {
                        string sink_name = "audio_%u";
                        if (pad.name == "src_0") {
                            sink_name = "video_%u";
                        }
                        var mux_pad = used_muxer.get_request_pad(sink_name);
                        result = pad.link(mux_pad);
                        break;      
                    }
                    default:
                        return;
                }
                if (result != PadLinkReturn.OK) {
                    stderr.printf("Could not link pad to muxer: %s", result.to_string());
                }
            }
        }

        public void multi_link(Gst.Element? audio, Gst.Element video) {
            PadLinkReturn result;
            var gvideo_in_pad = out_queue.get_request_pad("sink_%u");
            var ghost_video_sink = new Gst.GhostPad("video_sink", gvideo_in_pad);
            this.add_pad(ghost_video_sink);

            var video_in_pad = this.get_static_pad("video_sink");
            var video_out_pad = video.get_static_pad("src");
            result = video_out_pad.link(video_in_pad);
            if (result != PadLinkReturn.OK) {
                stderr.printf("Could not link video pad to muxer: %s", result.to_string());
            }

            // make sink public
            if (audio != null) {
                var gaudio_in_pad = out_queue.get_request_pad("sink_%u");
                var ghost_audio_sink = new Gst.GhostPad("audio_sink", gaudio_in_pad);
                this.add_pad(ghost_audio_sink);

                var audio_in_pad = this.get_static_pad("audio_sink");
                var audio_out_pad = audio.get_static_pad("src");
                result = audio_out_pad.link(audio_in_pad);
                if (result != PadLinkReturn.OK) {
                    stderr.printf("Could not link audio pad to muxer: %s", result.to_string());
                }
            }
        }

        public void set_destination(string path) {
            this.filesink.set("location", path);
        }

        public static HashMap<string,string> available_muxers() {
            var result = new HashMap<string,string>();
            result.set("mpegts", "MPEG TS");
            result.set("mkv", "Matroska");
            result.set("mp4", "MPEG 4");
            return result; // TODO: filter for availability
        }
    }
}
