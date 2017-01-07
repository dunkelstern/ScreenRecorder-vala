using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class MuxerBin: GLib.Object {
        private Gst.Bin bin;
        private Gst.Element filesink;

        public MuxerBin(string muxer) {
            this.bin = MuxerBin.make(muxer, out this.filesink);
        }

        public void connect(Gst.Element audio, Gst.Element video) {
            var audio_in_pad = this.bin.get_static_pad("audio_sink");
            var audio_out_pad = audio.get_static_pad("src");
            var video_in_pad = this.bin.get_static_pad("video_sink");
            var video_out_pad = audio.get_static_pad("src");
            audio_out_pad.link(audio_in_pad);
            video_out_pad.link(video_in_pad);
        }

        public void set_destination(string path) {
            this.filesink.set("location", path);
        }

        public void set_state(Gst.State state) {
            this.bin.set_state(state);
        }

        public void sync_state_with_parent() {
            this.bin.sync_state_with_parent();
        }

        private static Gst.Bin? make(string muxer, out Gst.Element filesink) {
            var bin = new Gst.Bin("muxer");

            // output part of pipeline
            var out_queue = Gst.ElementFactory.make("multiqueue", "out_queue");
            bin.add(out_queue);

            var audio_out_pad = out_queue.get_request_pad("src_%u");
            var video_out_pad = out_queue.get_request_pad("src_%u");

            Gst.Element used_muxer;
            switch(muxer) {
                case "mpegts":
                    used_muxer = Gst.ElementFactory.make("mpegtsmux", "muxer");
                    bin.add(used_muxer);
                    var mux_audio_pad = used_muxer.get_request_pad("sink_%d");
                    var mux_video_pad = used_muxer.get_request_pad("sink_%d");
                    audio_out_pad.link(mux_audio_pad);
                    video_out_pad.link(mux_video_pad);
                    break;
                case "mkv":
                    used_muxer = Gst.ElementFactory.make("matroskamux", "muxer");
                    bin.add(used_muxer);
                    var mux_audio_pad = used_muxer.get_request_pad("audio_%u");
                    var mux_video_pad = used_muxer.get_request_pad("video_%u");
                    audio_out_pad.link(mux_audio_pad);
                    video_out_pad.link(mux_video_pad);
                    break;
                case "mp4":
                    used_muxer = Gst.ElementFactory.make("mp4mux", "muxer");
                    bin.add(used_muxer);
                    var mux_audio_pad = used_muxer.get_request_pad("audio_%u");
                    var mux_video_pad = used_muxer.get_request_pad("video_%u");
                    audio_out_pad.link(mux_audio_pad);
                    video_out_pad.link(mux_video_pad);
                    break;
                default:
                    stderr.printf("Error: unknown muxer '%s'\n", muxer);
                    return null;
            }

            filesink = Gst.ElementFactory.make("filesink", "filesink");
            filesink.set("sync", false);
            bin.add(filesink);
            used_muxer.link(filesink);

            // make sink public
            var audio_in_pad = out_queue.get_request_pad("sink_%u");
            var video_in_pad = out_queue.get_request_pad("sink_%u");
            var ghost_audio_sink = new Gst.GhostPad("audio_sink", audio_in_pad);
            var ghost_video_sink = new Gst.GhostPad("video_sink", video_in_pad);
            bin.add_pad(ghost_audio_sink);
            bin.add_pad(ghost_video_sink);

            return bin;
        }

        public static string[] available_muxers() {
            return {
                // TODO: make dynamic, only return available ones
                "mpegts",
                "mkv",
                "mp4"
            };
        }
    }
}
