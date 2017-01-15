using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class PlaybackBin: Gst.Bin {

        public PlaybackBin(string hwaccel, bool sync = true) {
            GLib.Object(name: "playback_sink");

            switch (hwaccel) {
                case "vaapi": {
                    var uploader = Gst.ElementFactory.make("vaapipostproc", "postproc");
                    var output = Gst.ElementFactory.make("vaapisink", "output");
                    output.set("sync", sync);

                    this.add(uploader);
                    this.add(output);

                    uploader.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", uploader.get_static_pad("sink"));
                    this.add_pad(ghost_sink);
                    break;
                }
                case "opengl": {
                    var bin = Gst.ElementFactory.make("glsinkbin", "glbin");
                    bin.set("sync", sync);
                    this.add(bin);

                    var ghost_sink = new Gst.GhostPad("sink", bin.get_static_pad("sink"));
                    this.add_pad(ghost_sink);
                    break;
                }
                case "xvideo": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    var output = Gst.ElementFactory.make("xvimagesink", "output");
                    output.set("sync", sync);
                    output.set("colorkey", 0x000000);
                    this.add(convert);
                    this.add(output);

                    convert.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", convert.get_static_pad("sink"));
                    this.add_pad(ghost_sink);
                    break;
                }
                case "ximage": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    var output = Gst.ElementFactory.make("ximagesink", "output");
                    output.set("sync", sync);
                    this.add(convert);
                    this.add(output);

                    convert.link(output);

                    var ghost_sink = new Gst.GhostPad("sink", convert.get_static_pad("sink"));
                    this.add_pad(ghost_sink);
                    break;
                }
                default:
                    stderr.printf("Error: unknown hwaccel '%s'\n", hwaccel);
                    break;
            }            
        }

        public static HashMap<string,string> available_hwaccels() {
            var result = new HashMap<string,string>();
            result.set("vaapi", "Intel VAAPI (Hardware)");
            result.set("opengl", "OpenGL (Hardware)");
            result.set("xvideo", "XVideo (Overlay)");
            result.set("ximage", "X11 (Software)");
            return result; // TODO: filter for availability
        }
    }
}
