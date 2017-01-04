using Json;
using ScreenRec;

namespace ScreenRec {

    class ConfigFile : GLib.Object {
        private static GLib.Once<ConfigFile> _instance;

        public static unowned ConfigFile instance () {
            return _instance.once(() => { return new ConfigFile(); });
        }

        public ButtonConfig[] buttons;
        public RecorderConfig rec_settings;
        public StreamConfig stream_settings;
        public AudioConfig audio_settings;

        public ConfigFile(string? config_path = null) {
            string? path = config_path;
            if (path == null) {
                var builder = new StringBuilder(Environment.get_user_config_dir());
                builder.append("/ScreenRecorder/default.json");
                path = builder.str;
            }
            var file = File.new_for_path(path);

            this.buttons = {};
            this.rec_settings = new RecorderConfig();
            this.stream_settings = new StreamConfig();
            this.audio_settings = new AudioConfig();

            Json.Parser parser = new Json.Parser ();
            try {
                parser.load_from_stream(file.read());
            } catch (Error e) {
                stderr.printf("Unable to parse config from file '%s': %s\n", path, e.message);
                return;
            }

            var root = parser.get_root().get_object();
            try {
                stderr.printf("Deserializing rec_settings\n");
                this.rec_settings.deserialize(root.get_object_member("rec_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse recording settings: %s\n", e.message);
            }
            try {
                stderr.printf("Deserializing stream_settings\n");
                this.stream_settings.deserialize(root.get_object_member("stream_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse streaming settings: %s\n", e.message);
            }
            try {
                stderr.printf("Deserializing audio_settings\n");
                this.audio_settings.deserialize(root.get_object_member("audio_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse audio settings: %s\n", e.message);
            }

            stderr.printf("Deserializing buttons\n");
            var buttons = root.get_array_member("buttons");
            foreach (var element in buttons.get_elements()) {
                var button = element.get_object();
                var conf = ButtonConfigFactory.deserialize(button);
                if (conf != null) {
                    this.buttons += conf;
                }
            }
            stderr.printf("%d Buttons\n", this.buttons.length);
        }
    }
}
