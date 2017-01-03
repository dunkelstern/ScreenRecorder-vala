using Json;
using Gdk;
using ScreenRec;

namespace ScreenRec {

    class AudioConfig : Config {
        public string device;
        public string encoder;
        public int samplerate;
        public int channels;
        public int bitrate;

        public AudioConfig() {
            this.device = this.default_device();
            this.encoder = this.available_encoders()[0];
            this.samplerate = 48000;
            this.channels = 2;
            this.bitrate = 128;
        }

        public void serialize() {

        }

        public void deserialize(Json.Node json) {

        }

        public string default_device() {
            return ""; // FIXME: fetch default pulseaudio device
        }

        public string[] available_encoders() {
            return {
                // FIXME: make dynamic list
                "aac",
                "mp3",
                "opus",
                "speex",
                "vorbis"
            };
        }
    }
}
