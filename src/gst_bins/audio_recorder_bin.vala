using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class AudioRecorderBin: GLib.Object {

        public static Gst.Bin make() {
            var config = ConfigFile.instance().audio_settings;

            var src = new Gst.Bin("audio_recorder_src");

            var audio_src = Gst.ElementFactory.make("pulsesrc", "audio_src");
            audio_src.set("device", config.device);
            audio_src.set("client-name", "ScreenRec");
            audio_src.set("do-timestamp", true);

            src.add(audio_src);
            var ghost_src = new Gst.GhostPad("src", audio_src.get_static_pad("src"));
            src.add_pad(ghost_src);

            return src;
        }
    }
}