using Json;
using Gdk;

namespace ScreenRec {

    class StreamConfig : Config {
        public int screen;
        public string encoder;
        public string url;
        public int width;
        public int height;
        public int scale_width;
        public int scale_height;
        public int fps;

        public StreamConfig() {
            this.screen = 0;
            this.encoder = this.available_encoders()[0];
            this.url = "rtmp://127.0.0.1:1935/live/stream";
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
