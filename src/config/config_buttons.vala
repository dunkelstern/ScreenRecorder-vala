using Json;
using Gdk;

namespace ScreenRec {

    enum ButtonType {
        VIDEO4LINUX,
        RTMP_STREAM,
        MJPEG_PIPE,
        VIDEO_PLAYER
    }

    interface ButtonConfig : GLib.Object, Config {
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

        public static ButtonConfig deserialize(Json.Node node) {
            ButtonType type = ButtonType.VIDEO_PLAYER; // TODO: read from json node
            ButtonConfig result = ButtonConfigFactory.make_button_of_type(type);
            result.deserialize(node);
            return result;
        }
    }

    class V4l2ButtonConfig : GLib.Object, ButtonConfig, Config {
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
        public int width;
        public int height;
        public int framerate;
        public string hwaccel;

        public V4l2ButtonConfig() {
            this.title = "V4L2 Source";
            uint8 raw_id[16] = {0};
            char[] textual_id = {};
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

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

        }
    }

    class RtmpButtonConfig : GLib.Object, ButtonConfig, Config {
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
        public int max_width;
        public int max_height;
        public string hwaccel;

        public RtmpButtonConfig() {
            this.title = "RTMP Stream Source";
            uint8 raw_id[16] = {0};
            char[] textual_id = {};
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.url = "rtmp://127.0.0.1:1935/live/stream";
            this.max_width = 1280;
            this.max_height = 720;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

        }
    }

    class MjpegButtonConfig : GLib.Object, ButtonConfig, Config {
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
        public int width;
        public int height;
        public string hwaccel;

        public MjpegButtonConfig() {
            this.title = "MJPEG Pipe Source";
            uint8 raw_id[16] = {0};
            char[] textual_id = {};
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.command = "gphoto2 --stdout --capture-movie";
            this.width = 1045;
            this.height = 704;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

        }
    }

    class PlayerButtonConfig : GLib.Object, ButtonConfig,Config {
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
            uint8 raw_id[16] = {0};
            char[] textual_id = {};
            UUID.generate_random(raw_id);
            UUID.unparse(raw_id, textual_id);
            this.id = (string)textual_id;
            this.filename = "~/Movies/movie.mp4";
            this.auto_play = false;
            this.restart_on_deactivate = false;
            this.seek_bar = false;
            this.hwaccel = "opengl"; // TODO: make dynamic query
        }

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

        }
   }
}
