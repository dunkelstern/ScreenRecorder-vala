using Json;
using Gdk;
using ScreenRec;

namespace ScreenRec {

    enum ButtonType {
        VIDEO4LINUX,
        RTMP_STREAM,
        MJPEG_PIPE,
        VIDEO_PLAYER
    }

    interface ButtonConfig : Config {
        public abstract ButtonType button_type { get; }
        public abstract string title { get; set; }
        public abstract string id { get; set; }
    }

    class ButtonConfigFactory : GLib.Object {
        public static ButtonConfig? make_button_of_type(ButtonType type) {
            switch (type) {
                case ButtonType.VIDEO4LINUX:
                    return new V4l2ButtonConfig();
                case ButtonType.RTMP_STREAM:
                    return new RtmpButtonConfig();
                case ButtonType.MJPEG_PIPE:
                    return new MjpegButtonConfig();
                case ButtonType.VIDEO_PLAYER:
                    return new PlayerButtonConfig();
                default:
                    return null;
            }
        }

        public static ButtonConfig? deserialize(Json.Object object) {
            var type_string = object.get_string_member("button_type");
            ButtonType type;
            switch (type_string) {
                case "v4l2":
                    type = ButtonType.VIDEO4LINUX;
                    break;
                case "rtmp":
                    type = ButtonType.RTMP_STREAM;
                    break;
                case "mjpeg":
                    type = ButtonType.MJPEG_PIPE;
                    break;
                case "player":
                    type = ButtonType.VIDEO_PLAYER;
                    break;
                default:
                    return null;
            }
            ButtonConfig result = ButtonConfigFactory.make_button_of_type(type);
            try {
                result.deserialize(object);
            } catch (Error e) {
                stderr.printf("Could not parse button config: %s\n", e.message);
                return null;
            }
            return result;
        }
    }

    class V4l2ButtonConfig : GLib.Object, Config, ButtonConfig {
        public ButtonType button_type { get { return ButtonType.VIDEO4LINUX; } }
        private string _title;
        public string title {
            get { return _title; }
            set { _title = value; }
        }
        private string _id;
        public string id {
            get { return _id; }
            set { _id = value; }
        }

        public string device;
        public string format;
        public int64 width;
        public int64 height;
        public int64 framerate;
        public string hwaccel;

        public V4l2ButtonConfig() {
            this.title = "V4L2 Source";
            var raw_id = new uint8[16];
            var textual_id = new char[36];
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.device = "/dev/video0";
            this.format = "image/jpeg";
            this.width = 1280;
            this.height = 720;
            this.framerate = 30;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_string_member("id", this.id);
            object.set_string_member("title", this.title);
            object.set_string_member("button_type", "v4l2");
            object.set_string_member("device", this.device);
            object.set_string_member("format", this.format);
            object.set_int_member("width", this.width);
            object.set_int_member("height", this.height);
            object.set_int_member("framerate", this.framerate);
            object.set_string_member("hwaccel", this.hwaccel);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            var type = object.get_string_member("button_type");
            if (type != "v4l2") {
                throw new ConfigParseError.WRONG_TYPE("Wrong config type");
            }
            this.id = object.get_string_member("id");
            this.title = object.get_string_member("title");
            this.device = object.get_string_member("device");
            this.format = object.get_string_member("format");
            this.width = object.get_int_member("width");
            this.height = object.get_int_member("height");
            this.framerate = object.get_int_member("framerate");
            this.hwaccel = object.get_string_member("hwaccel");
        }
    }

    class RtmpButtonConfig : GLib.Object, Config, ButtonConfig {
        public ButtonType button_type { get { return ButtonType.RTMP_STREAM; } }
        private string _title;
        public string title {
            get { return _title; }
            set { _title = value; }
        }
        private string _id;
        public string id {
            get { return _id; }
            set { _id = value; }
        }

        public string url;
        public int64 max_width;
        public int64 max_height;
        public string hwaccel;

        public RtmpButtonConfig() {
            this.title = "RTMP Stream Source";
            var raw_id = new uint8[16];
            var textual_id = new char[36];
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.url = "rtmp://127.0.0.1:1935/live/stream";
            this.max_width = 1280;
            this.max_height = 720;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_string_member("id", this.id);
            object.set_string_member("title", this.title);
            object.set_string_member("button_type", "rtmp");
            object.set_string_member("url", this.url);
            object.set_int_member("max_width", this.max_width);
            object.set_int_member("max_height", this.max_height);
            object.set_string_member("hwaccel", this.hwaccel);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            var type = object.get_string_member("button_type");
            if (type != "rtmp") {
                throw new ConfigParseError.WRONG_TYPE("Wrong config type");
            }
            this.id = object.get_string_member("id");
            this.title = object.get_string_member("title");
            this.url = object.get_string_member("url");
            this.max_width = object.get_int_member("max_width");
            this.max_height = object.get_int_member("max_height");
            this.hwaccel = object.get_string_member("hwaccel");
        }
    }

    class MjpegButtonConfig : GLib.Object, Config, ButtonConfig {
        public ButtonType button_type { get { return ButtonType.MJPEG_PIPE; } }
        private string _title;
        public string title {
            get { return _title; }
            set { _title = value; }
        }
        private string _id;
        public string id {
            get { return _id; }
            set { _id = value; }
        }

        public string command;
        public int64 width;
        public int64 height;
        public string hwaccel;

        public MjpegButtonConfig() {
            this.title = "MJPEG Pipe Source";
            var raw_id = new uint8[16];
            var textual_id = new char[36];
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.command = "gphoto2 --stdout --capture-movie";
            this.width = 1045;
            this.height = 704;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_string_member("id", this.id);
            object.set_string_member("title", this.title);
            object.set_string_member("button_type", "mjpeg");
            object.set_string_member("command", this.command);
            object.set_int_member("width", this.width);
            object.set_int_member("height", this.height);
            object.set_string_member("hwaccel", this.hwaccel);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            var type = object.get_string_member("button_type");
            if (type != "mjpeg") {
                throw new ConfigParseError.WRONG_TYPE("Wrong config type");
            }
            this.id = object.get_string_member("id");
            this.title = object.get_string_member("title");
            this.command = object.get_string_member("command");
            this.width = object.get_int_member("width");
            this.height = object.get_int_member("height");
            this.hwaccel = object.get_string_member("hwaccel");
        }
    }

    class PlayerButtonConfig : GLib.Object, Config, ButtonConfig {
        public ButtonType button_type { get { return ButtonType.VIDEO_PLAYER; } }
        private string _title;
        public string title {
            get { return _title; }
            set { _title = value; }
        }
        private string _id;
        public string id {
            get { return _id; }
            set { _id = value; }
        }

        public string filename;
        public bool auto_play;
        public bool restart_on_deactivate;
        public bool seek_bar;
        public string hwaccel;

        public PlayerButtonConfig() {
            this.title = "RTMP Stream Source";
            var raw_id = new uint8[16];
            var textual_id = new char[36];
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.filename = "~/Movies/movie.mp4";
            this.auto_play = false;
            this.restart_on_deactivate = false;
            this.seek_bar = false;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_string_member("id", this.id);
            object.set_string_member("title", this.title);
            object.set_string_member("button_type", "player");
            object.set_string_member("filename", this.filename);
            object.set_boolean_member("auto_play", this.auto_play);
            object.set_boolean_member("restart_on_deactivate", this.restart_on_deactivate);
            object.set_boolean_member("seek_bar", this.seek_bar);
            object.set_string_member("hwaccel", this.hwaccel);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            var type = object.get_string_member("button_type");
            if (type != "player") {
                throw new ConfigParseError.WRONG_TYPE("Wrong config type");
            }
            this.id = object.get_string_member("id");
            this.title = object.get_string_member("title");
            this.filename = object.get_string_member("filename");
            this.auto_play = object.get_boolean_member("auto_play");
            this.restart_on_deactivate = object.get_boolean_member("restart_on_deactivate");
            this.seek_bar = object.get_boolean_member("seek_bar");
            this.hwaccel = object.get_string_member("hwaccel");
        }
   }
}
