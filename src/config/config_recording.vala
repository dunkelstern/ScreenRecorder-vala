using Json;
using Gdk;

namespace ScreenRec {

    class RecorderConfig : GLib.Object, Config {
        public int64 screen;
        public string encoder;
        public string filename;
        public int64 width;
        public int64 height;
        public int64 scale_width;
        public int64 scale_height;
        public int64 fps;

        public RecorderConfig() {
            this.screen = 0;
            this.encoder = this.available_encoders()[0];
            this.filename = "~/Capture/cap-%Y-%m-%d_%H-%M-%S.ts";
            this.width = Screen.width();
            this.height = Screen.height();
            this.scale_width = 0;
            this.scale_height = 0;
            this.fps = 30;
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_int_member("screen", this.screen);
            object.set_string_member("filename", this.filename);
            object.set_string_member("encoder", this.encoder);
            object.set_int_member("width", this.width);
            object.set_int_member("height", this.height);
            object.set_int_member("scale_width", this.scale_width);
            object.set_int_member("scale_height", this.scale_height);
            object.set_int_member("fps", this.fps);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            this.screen = object.get_int_member("screen");
            this.filename = object.get_string_member("filename");
            this.encoder = object.get_string_member("encoder");
            this.width = object.get_int_member("width");
            this.height = object.get_int_member("height");
            this.scale_width = object.get_int_member("scale_width");
            this.scale_height = object.get_int_member("scale_height");
            this.fps = object.get_int_member("fps");
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
