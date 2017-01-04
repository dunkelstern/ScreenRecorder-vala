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
        private string? path;

        public ConfigFile(string? config_path = null) {
            this.path = config_path;
            if (this.path == null) {
                var builder = new StringBuilder(Environment.get_user_config_dir());
                builder.append("/ScreenRecorder/default.json");
                this.path = builder.str;
            }
            var file = File.new_for_path(this.path);

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
                this.rec_settings.deserialize(root.get_object_member("rec_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse recording settings: %s\n", e.message);
            }
            try {
                this.stream_settings.deserialize(root.get_object_member("stream_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse streaming settings: %s\n", e.message);
            }
            try {
                this.audio_settings.deserialize(root.get_object_member("audio_settings"));
            } catch (Error e) {
                stderr.printf("Unable to parse audio settings: %s\n", e.message);
            }

            var buttons = root.get_array_member("buttons");
            foreach (var element in buttons.get_elements()) {
                var button = element.get_object();
                var conf = ButtonConfigFactory.deserialize(button);
                if (conf != null) {
                    this.buttons += conf;
                }
            }
        }

        public void save() {
            var root = new Json.Object();

            root.set_object_member("rec_settings", this.rec_settings.serialize());
            root.set_object_member("stream_settings", this.stream_settings.serialize());
            root.set_object_member("audio_settings", this.audio_settings.serialize());

            var buttons = new Json.Array();
            foreach(var button in this.buttons) {
                buttons.add_object_element(button.serialize());
            }

            root.set_array_member("buttons", buttons);

            var generator = new Json.Generator();
            var node = new Json.Node(NodeType.OBJECT);
            node.set_object(root);
            generator.indent = 4;
            generator.indent_char = 32;
            generator.pretty = true;
            generator.root = node;

            var str = generator.to_data(null);
            var file = File.new_for_path(this.path);
            try {
                file.replace(null, false, FileCreateFlags.PRIVATE).write(str.data);
            } catch (Error e) {
                stderr.printf("Error writing config file: %s\n", e.message);
            }
        }
    }
}
