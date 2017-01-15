using Json;
using Gdk;

namespace ScreenRec {

    class StreamConfig : GLib.Object, Config {
        public int64 screen;
        public string encoder;
        public string url;
        public int64 width;
        public int64 height;
        public int64 scale_width;
        public int64 scale_height;
        public int64 fps;
        public int64 bitrate;

        public StreamConfig() {
            var monitor = Display.get_default().get_monitor(0).geometry;
            this.screen = 0;
            this.encoder = this.available_encoders()[0];
            this.url = "rtmp://127.0.0.1:1935/live/stream";
            this.width = monitor.width;
            this.height = monitor.height;
            this.scale_width = 0;
            this.scale_height = 0;
            this.fps = 30;
            this.bitrate = 2000;
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_int_member("screen", this.screen);
            object.set_string_member("url", this.url);
            object.set_string_member("encoder", this.encoder);
            object.set_int_member("width", this.width);
            object.set_int_member("height", this.height);
            object.set_int_member("scale_width", this.scale_width);
            object.set_int_member("scale_height", this.scale_height);
            object.set_int_member("fps", this.fps);
            object.set_int_member("bitrate", this.bitrate);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            this.screen = object.get_int_member("screen");
            this.url = object.get_string_member("url");
            this.encoder = object.get_string_member("encoder");
            this.width = object.get_int_member("width");
            this.height = object.get_int_member("height");
            this.scale_width = object.get_int_member("scale_width");
            this.scale_height = object.get_int_member("scale_height");
            this.fps = object.get_int_member("fps");
            this.bitrate = object.get_int_member("bitrate");
        }

        public string[] available_encoders() {
            return {
                "x264",
                "vaapi",
                "openh264"
            };
        }
    }
}
