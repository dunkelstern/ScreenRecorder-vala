using Json;
using ScreenRec;

namespace ScreenRec {

    class ConfigFile : GLib.Object {
        public ButtonConfig[] buttons;
        public RecorderConfig rec_settings;
        public StreamConfig stream_settings;
        public AudioConfig audio_settings;

        public ConfigFile(string path = "~/.config/ScreenRecorder/default.json") {

        }
    }
}
