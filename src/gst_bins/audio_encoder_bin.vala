using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class AudioEncoderBin: GLib.Object {

        public static Gst.Bin? make() {
            var config = ConfigFile.instance().audio_settings;

            // input part of pipeline
            var bin = new Gst.Bin("audio_encoder_bin");

            // input format filter           
            var cap_string_builder = new StringBuilder("");
            cap_string_builder.printf(
                "audio/x-raw,format=S16LE,rate=%d,channels=%d",
                (int)config.samplerate,
                (int)config.channels
            );
            var caps = Gst.Caps.from_string(cap_string_builder.str);
            var filter = Gst.ElementFactory.make("capsfilter", "input_capsfilter");
            filter.set_property("caps", caps);

            // queue to decouple
            var queue = Gst.ElementFactory.make("queue", "encoder_input_queue");
            queue.set("max-size-buffers", 200);
            queue.set("max-size-bytes", 10485760);  // 1 MB
            queue.set("max-size-time", 10000000000);  // 10 sec

            bin.add(filter);
            bin.add(queue);
            filter.link(queue);

            // scaler/encoder part of pipeline
            Gst.Element encoder;
            switch (config.encoder) {
                case "aac": {
                    encoder = Gst.ElementFactory.make("faac", "encoder");
                    encoder.set("bitrate", config.bitrate * 1000);
                    break;
                }
                case "mp3": {
                    encoder = Gst.ElementFactory.make("lamemp3enc", "encoder");
                    encoder.set("bitrate", config.bitrate);
                    encoder.set("cbr", true);
                    break;
                }
                case "opus": {
                    encoder = Gst.ElementFactory.make("opusenc", "encoder");
                    encoder.set("bitrate", config.bitrate * 1000);
                    encoder.set("bitrate-type", 0); // cbr
                    break;
                }
                case "speex": {
                    encoder = Gst.ElementFactory.make("speexenc", "encoder");
                    encoder.set("bitrate", config.bitrate * 1000);
                    encoder.set("abr", true);
                    break;
                }
                case "vorbis": {
                    encoder = Gst.ElementFactory.make("vorbisenc", "encoder");
                    encoder.set("bitrate", config.bitrate * 1000);
                    encoder.set("managed", true);
                    break;
                }
                default:
                    stderr.printf("Error: unknown encoder '%s'\n", config.encoder);
                    return null;
            }
            bin.add(encoder);
            queue.link(encoder);

            // make source and sink public
            var ghost_src = new Gst.GhostPad("src", encoder.get_static_pad("src"));
            var ghost_sink = new Gst.GhostPad("sink", filter.get_static_pad("sink"));
            bin.add_pad(ghost_sink);
            bin.add_pad(ghost_src);

            return bin;
        }

        public static HashMap<string,string> available_encoders() {
            var result = new HashMap<string,string>();
            result.set("aac", "AAC");
            result.set("mp3", "MP3");
            result.set("opus", "Opus");
            result.set("speex", "Speex");
            result.set("vorbis", "Vorbis");
            return result; // TODO: filter for availability
        }
    }
}
