using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class AudioRecorderBin: Gst.Bin {

        public AudioRecorderBin() {
            GLib.Object(name: "audio_recorder_src");

            var config = ConfigFile.instance().audio_settings;

            var audio_src = Gst.ElementFactory.make("pulsesrc", "audio_src");
            audio_src.set("device", config.device);
            audio_src.set("client-name", "ScreenRec");
            audio_src.set("do-timestamp", true);

            this.add(audio_src);
            var ghost_src = new Gst.GhostPad("src", audio_src.get_static_pad("src"));
            this.add_pad(ghost_src);
        }
    }
}