using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class PlaybackBin: GLib.Object {

        public static Gst.Bin make(string hwaccel, bool sync = true) {
            var sink = new Gst.Bin("playback_sink");

            switch (hwaccel) {
                case "vaapi": {
                    var uploader = Gst.ElementFactory.make("vaapipostproc", "postproc");
                    var output = Gst.ElementFactory.make("vaapisink", "output");
                    output.set("sync", sync);

                    sink.add(uploader);
                    sink.add(output);

                    uploader.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", uploader.get_static_pad("sink"));
                    sink.add_pad(ghost_sink);
                    break;
                }
                case "opengl": {
                    var bin = Gst.ElementFactory.make("glsinkbin", "glbin");
                    bin.set("sync", sync);
                    sink.add(bin);

                    var ghost_sink = new Gst.GhostPad("sink", bin.get_static_pad("sink"));
                    sink.add_pad(ghost_sink);
                    break;
                }
                case "xvideo": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    var output = Gst.ElementFactory.make("xvimagesink", "output");
                    output.set("sync", sync);
                    output.set("colorkey", 0x000000);
                    sink.add(convert);
                    sink.add(output);

                    convert.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", convert.get_static_pad("sink"));
                    sink.add_pad(ghost_sink);
                    break;
                }
                case "ximage": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    var output = Gst.ElementFactory.make("ximagesink", "output");
                    output.set("sync", sync);
                    sink.add(convert);
                    sink.add(output);

                    convert.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", convert.get_static_pad("sink"));
                    sink.add_pad(ghost_sink);
                    break;
                }
                default:
                    stderr.printf("Error: unknown hwaccel '%s'\n", hwaccel);
                    break;
            }            
            return sink;
        }

        public static string[] available_hwaccels() {
            return {
                // TODO: make dynamic, only return available ones
                "vaapi",
                "opengl",
                "xvideo",
                "ximage"
            };
        }
    }
}
