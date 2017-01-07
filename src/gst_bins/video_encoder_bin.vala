using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class VideoEncoderBin: GLib.Object {

        public static Gst.Bin? make() {
            var config = ConfigFile.instance().rec_settings;
            var scale_width = config.scale_width;
            var scale_height = config.scale_height;
            if (scale_width == 0) {
                scale_width = config.width;
            }
            if (scale_height == 0) {
                scale_height = config.height;
            }

            // input part of pipeline
            var sink = new Gst.Bin("video_encoder_sink");

            // queue to decouple
            var queue = Gst.ElementFactory.make("queue", "encoder_input_queue");
            queue.set("max-size-buffers", 200);
            queue.set("max-size-bytes", 104857600);  // 10 MB
            queue.set("max-size-time", 10000000000);  // 10 sec
            
            // smooth videorate, last chance to drop frames on overload
            var videorate = Gst.ElementFactory.make("videorate", "videorate");
            var cap_string_builder = new StringBuilder("");
            cap_string_builder.printf(
                "video/x-raw,framerate=%d/1",
                (int)config.fps
            );
            var caps = Gst.Caps.from_string(cap_string_builder.str);
            var filter = Gst.ElementFactory.make("capsfilter", "rate_capsfilter");
            filter.set_property("caps", caps);

            sink.add(queue);
            sink.add(videorate);
            sink.add(filter);
            queue.link(videorate);
            videorate.link(filter);

            // scaler/encoder part of pipeline
            Gst.Element src;
            Gst.Element output;
            switch (config.encoder) {
                case "vaapi": {
                    var scaler = Gst.ElementFactory.make("vaapipostproc", "scaler");
                    scaler.set("width", scale_width);
                    scaler.set("height", scale_height);                   
                    scaler.set("scale-method", 2);
                    sink.add(scaler);

                    var encoder = Gst.ElementFactory.make("vaapih264enc", "encoder");
                    sink.add(encoder);

                    scaler.link(encoder);
                    src = scaler;
                    output = encoder;
                    break;
                }
                case "x264": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    sink.add(convert);

                    var scaler = Gst.ElementFactory.make("videoscale", "scaler");
                    sink.add(scaler);

                    var scale_cap_string_builder = new StringBuilder("");
                    cap_string_builder.printf(
                        "video/x-raw,width=%d,height=%d",
                        (int)scale_width,
                        (int)scale_height
                    );
                    var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
                    var scale_filter = Gst.ElementFactory.make("capsfilter", "scale_filter");
                    scale_filter.set_property("caps", scale_caps);
                    sink.add(scale_filter);

                    var encoder = Gst.ElementFactory.make("x264enc", "encoder");
                    encoder.set("speed-preset", "veryfast");
                    //encoder.set("tune", 4)  # zero latency
                    sink.add(encoder);

                    convert.link(scaler);
                    scaler.link(scale_filter);
                    scale_filter.link(encoder);

                    src = convert;
                    output = encoder;
                    break;
                }
                case "openh264": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    sink.add(convert);

                    var scaler = Gst.ElementFactory.make("videoscale", "scaler");
                    sink.add(scaler);

                    var scale_cap_string_builder = new StringBuilder("");
                    cap_string_builder.printf(
                        "video/x-raw,width=%d,height=%d",
                        (int)scale_width,
                        (int)scale_height
                    );
                    var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
                    var scale_filter = Gst.ElementFactory.make("capsfilter", "scale_filter");
                    scale_filter.set_property("caps", scale_caps);
                    sink.add(scale_filter);

                    var encoder = Gst.ElementFactory.make("openh264enc", "encoder");
                    encoder.set("complexity", 0);
                    sink.add(encoder);

                    convert.link(scaler);
                    scaler.link(scale_filter);
                    scale_filter.link(encoder);

                    src = convert;
                    output = encoder;
                    break;
                }
                default:
                    stderr.printf("Error: unknown encoder '%s'\n", config.encoder);
                    return null;
            }

            filter.link(src);

            // output part of pipeline
            var parser = Gst.ElementFactory.make("h264parse", "out_parser");
            sink.add(parser);
            output.link(parser);

            // make sink public
            var ghost_sink = new Gst.GhostPad("sink", queue.get_static_pad("sink"));
            var ghost_src = new Gst.GhostPad("src", parser.get_static_pad("src"));
            sink.add_pad(ghost_sink);
            sink.add_pad(ghost_src);

            return sink;
        }

        public static string[] available_encoders() {
            return {
                // TODO: make dynamic, only return available ones
                "vaapi",
                "x264",
                "openh264"
            };
        }
    }
}
