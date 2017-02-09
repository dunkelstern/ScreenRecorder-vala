using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class VideoEncoderBin: Gst.Bin, ManualVideoRoutingSink {
        private Gst.App.Src appsrc;
        private ManualVideoRoutingSrc? current_source;

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

            appsrc = Gst.ElementFactory.make("appsrc", "appsrc") as Gst.App.Src;
            appsrc.set_property("is-live", true);
            appsrc.set_property("do-timestamp", true);
            appsrc.set_max_bytes(1920*1080*4*4*2); // 2 4K RGBx frames                
            appsrc.set_caps(this.get_input_caps());
            this.add(appsrc);

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
                    scale_cap_string_builder.printf(
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
                    scale_cap_string_builder.printf(
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

            appsrc.link(src);

            // output part of pipeline
            var parser = Gst.ElementFactory.make("h264parse", "out_parser");
            this.add(parser);
            output.link(parser);

            // usually you would see something like this:

            // var ghost_sink = new Gst.GhostPad("sink", input_filter.get_static_pad("sink"));
            // this.add_pad(ghost_sink);

            // but we are routing manually, so no traditional sink

            // make src public
            var ghost_src = new Gst.GhostPad("src", parser.get_static_pad("src"));
            this.add_pad(ghost_src);
        }

        public bool consume_sample(Sample buffer) {
            var result = this.appsrc.push_sample(buffer);
            if (result != FlowReturn.OK) {
                stderr.printf("Failed to push sample into video encoder, result = %s\n", result.to_string());
                return false;
            }
            return true;
        }

        public void shutdown_with_eos() {
            this.appsrc.end_of_stream();
        }

        public Caps get_input_caps() {
            var config = ConfigFile.instance().rec_settings;
            var scale_width = config.scale_width;
            var scale_height = config.scale_height;
            if (scale_width == 0) {
                scale_width = config.width;
            }
            if (scale_height == 0) {
                scale_height = config.height;
            }

            var cap_string_builder = new StringBuilder("");
            cap_string_builder.printf(
                "video/x-raw,format=I420,width=%d,height=%d,framerate=%d/1",
                (int)scale_width,
                (int)scale_height,
                (int)config.fps
            );
            var caps = Gst.Caps.from_string(cap_string_builder.str);

            stderr.printf("input caps: %s\n", caps.to_string());
            return caps;
        }

        public void connect_to_source(ManualVideoRoutingSrc src) {
            if (this.current_source != null) {
                this.current_source.stop_emitting_buffers();
            }
            this.current_source = src;
            this.current_source.start_emitting_buffers(this);
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
