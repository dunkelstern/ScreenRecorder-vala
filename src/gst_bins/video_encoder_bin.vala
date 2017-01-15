using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class VideoEncoderBin: Gst.Bin {

        public VideoEncoderBin() {
            // input part of pipeline
            GLib.Object(name: "video_encoder_sink");

            var config = ConfigFile.instance().rec_settings;
            var scale_width = config.scale_width;
            var scale_height = config.scale_height;
            if (scale_width == 0) {
                scale_width = config.width;
            }
            if (scale_height == 0) {
                scale_height = config.height;
            }

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

            this.add(queue);
            this.add(videorate);
            this.add(filter);
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
                    this.add(scaler);

                    var encoder = Gst.ElementFactory.make("vaapih264enc", "encoder");
                    this.add(encoder);

                    scaler.link(encoder);
                    src = scaler;
                    output = encoder;
                    break;
                }
                case "x264": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    this.add(convert);

                    var scaler = Gst.ElementFactory.make("videoscale", "scaler");
                    this.add(scaler);

                    var scale_cap_string_builder = new StringBuilder("");
                    cap_string_builder.printf(
                        "video/x-raw,width=%d,height=%d",
                        (int)scale_width,
                        (int)scale_height
                    );
                    var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
                    var scale_filter = Gst.ElementFactory.make("capsfilter", "scale_filter");
                    scale_filter.set_property("caps", scale_caps);
                    this.add(scale_filter);

                    var encoder = Gst.ElementFactory.make("x264enc", "encoder");
                    encoder.set("speed-preset", "veryfast");
                    //encoder.set("tune", 4)  # zero latency
                    this.add(encoder);

                    convert.link(scaler);
                    scaler.link(scale_filter);
                    scale_filter.link(encoder);

                    src = convert;
                    output = encoder;
                    break;
                }
                case "openh264": {
                    var convert = Gst.ElementFactory.make("autovideoconvert", "convert");
                    this.add(convert);

                    var scaler = Gst.ElementFactory.make("videoscale", "scaler");
                    this.add(scaler);

                    var scale_cap_string_builder = new StringBuilder("");
                    cap_string_builder.printf(
                        "video/x-raw,width=%d,height=%d",
                        (int)scale_width,
                        (int)scale_height
                    );
                    var scale_caps = Gst.Caps.from_string(scale_cap_string_builder.str);
                    var scale_filter = Gst.ElementFactory.make("capsfilter", "scale_filter");
                    scale_filter.set_property("caps", scale_caps);
                    this.add(scale_filter);

                    var encoder = Gst.ElementFactory.make("openh264enc", "encoder");
                    encoder.set("complexity", 0);
                    this.add(encoder);

                    convert.link(scaler);
                    scaler.link(scale_filter);
                    scale_filter.link(encoder);

                    src = convert;
                    output = encoder;
                    break;
                }
                default:
                    stderr.printf("Error: unknown encoder '%s'\n", config.encoder);
                    return;
            }

            filter.link(src);

            // output part of pipeline
            var parser = Gst.ElementFactory.make("h264parse", "out_parser");
            this.add(parser);
            output.link(parser);

            // make sink public
            var ghost_sink = new Gst.GhostPad("sink", queue.get_static_pad("sink"));
            var ghost_src = new Gst.GhostPad("src", parser.get_static_pad("src"));
            this.add_pad(ghost_sink);
            this.add_pad(ghost_src);
        }

        public static HashMap<string,string> available_encoders() {
            var result = new HashMap<string,string>();
            result.set("vaapi", "Intel VAAPI (Hardware)");
            result.set("x264", "x264 (Software)");
            result.set("openh264", "Open H.264 (Software)");
            return result; // TODO: filter for availability
        }
    }
}
