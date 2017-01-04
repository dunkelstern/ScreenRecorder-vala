using Json;
using Gdk;
using ScreenRec;

namespace ScreenRec {

    class AudioConfig : GLib.Object, Config {
        public string device;
        public string encoder;
        public int64 samplerate;
        public int64 channels;
        public int64 bitrate;

        public AudioConfig() {
            this.device = this.default_device();
            this.encoder = this.available_encoders()[0];
            this.samplerate = 48000;
            this.channels = 2;
            this.bitrate = 128;
        }

        public Json.Object serialize() {
            var object = new Json.Object();
            object.set_string_member("device", this.device);
            object.set_string_member("encoder", this.encoder);
            object.set_int_member("samplerate", this.samplerate);
            object.set_int_member("channels", this.channels);
            object.set_int_member("bitrate", this.bitrate);
            return object;
        }

        public void deserialize(Json.Object object) throws ConfigParseError {
            this.device = object.get_string_member("device");
            this.encoder = object.get_string_member("encoder");
            this.samplerate = object.get_int_member("samplerate");
            this.channels = object.get_int_member("channels");
            this.bitrate = object.get_int_member("bitrate");
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
