using Json;
using Gdk;

namespace ScreenRec {

    class RecorderConfig : Config {
        public int screen;
        public string encoder;
        public string filename;
        public int width;
        public int height;
        public int scale_width;
        public int scale_height;
        public int fps;

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

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

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
