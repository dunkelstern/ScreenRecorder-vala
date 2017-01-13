using Gtk;
using ScreenRec;

namespace ScreenRec {

    class MainWindow: Gtk.Window, SettingsWindowDelegate {
        private HeaderBar header;
        private Button record_button;
        private Button config_button;
        private Box button_box;
        private PlaybackWindow[] windows = {};

        private MuxerBin muxer;
        private Gst.Pipeline? pipeline = null;

        public MainWindow() {
            // window settings
            this.title = "Screen Recorder";
            this.set_default_size (200, 200);
            this.destroy.connect(quit);
            this.border_width = 0;
            this.resizable = false;

            // Header bar
            header = new HeaderBar();
            header.set_show_close_button(true);
            header.title = "Screen Recorder";
            this.set_titlebar(header);

            // Record Button
            record_button = new Button();
            var icon = new ThemedIcon("media-record");
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            record_button.image = image;
            record_button.clicked.connect(on_record);
            header.pack_end(record_button);

            // Config Button
            config_button = new Button();
            icon = new ThemedIcon("preferences-system");
            image = new Image.from_gicon(icon, IconSize.BUTTON);
            config_button.image = image;
            config_button.clicked.connect(on_config);
            header.pack_end(config_button);

            // Button box
            button_box = new Box(Gtk.Orientation.VERTICAL, 10);
            this.add(button_box);

            // Fill button box
            build_source_buttons(button_box);

            // show the lot
            this.show_all();
        }

        private void create_recorder() {
            var config = ConfigFile.instance();

            var video_src = Gst.ElementFactory.make("ximagesrc", "video_src");
            video_src.set("display-name", ":0." + config.rec_settings.screen.to_string());
            video_src.set("use-damage", 0);
            video_src.set("startx", 0);
            video_src.set("starty", 0);
            video_src.set("endx", config.rec_settings.width - 1);
            video_src.set("endy", config.rec_settings.height - 1);
            video_src.set("do-timestamp", true);

            var audio_src = Gst.ElementFactory.make("pulsesrc", "audio_src");
            audio_src.set("device", config.audio_settings.device);
            audio_src.set("client-name", "ScreenRec");
            audio_src.set("do-timestamp", true);

            var video_encoder = VideoEncoderBin.make();
            var audio_encoder = AudioEncoderBin.make();
            this.muxer = new MuxerBin("mpegts");

            this.pipeline = new Gst.Pipeline("record");
            this.pipeline.add(video_src);
            this.pipeline.add(audio_src);
            this.pipeline.add(video_encoder);
            this.pipeline.add(audio_encoder);
            this.pipeline.add(this.muxer.bin);

            video_src.link(video_encoder);
            audio_src.link(audio_encoder);
            this.muxer.link(audio_encoder, video_encoder);

            dump_pipeline(this.pipeline);
        }

        private void on_record(Button button) {
            if (this.pipeline == null) {
                // create recorder if not existing
                this.create_recorder();
            }

            Gst.State state;
            Gst.State pending;
            this.pipeline.get_state(out state, out pending, 0);

            // set the record button to display the correct symbol
            var icon_name = "media-record";
            if (state == Gst.State.PLAYING) {
                var eos = new Gst.Event.eos();
                this.pipeline.send_event(eos);
                //this.pipeline.set_state(Gst.State.NULL);
            } else {
                icon_name = "media-playback-stop-symbolic";
                var path = "/home/dark/Capture/output.ts";
                this.muxer.set_destination(path);
                this.pipeline.set_state(Gst.State.PLAYING);
            }

            // update button icon
            var icon = new ThemedIcon(icon_name);
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            record_button.image = image;
        }

        private void on_config(Button button) {
            var settings = new SettingsWindow(this);
        }

        public void update_callback() {

        }

        private void on_source_button(Button source) {
            var config = ConfigFile.instance();

            // find button
            ButtonConfig? slot = null;
            foreach(var button in config.buttons) {
                if (source.name == button.id) {
                    slot = button;
                    break;
                }
            }

            // not found, cancel
            if (slot == null) {
                return; // wat?
            }

            // try to find the window
            foreach(var window in this.windows) {
                if (window.config.id == source.name) {
                    // found: show and raise
                    window.show_all();
                    window.present();
                    return;
                }
            }

            // run the correct playback window
            switch(slot.button_type) {
                case ButtonType.VIDEO4LINUX:
                    var window = new V4l2Window(slot as V4l2ButtonConfig);
                    this.windows += window;
                    break;
                case ButtonType.VIDEO_PLAYER:
                    var window = new PlayerWindow(slot as PlayerButtonConfig);
                    this.windows += window;
                    break;
                case ButtonType.MJPEG_PIPE:
                    var window = new MjpegWindow(slot as MjpegButtonConfig);
                    this.windows += window;
                    break;
                case ButtonType.RTMP_STREAM:
                    var window = new RtmpWindow(slot as RtmpButtonConfig);
                    this.windows += window;
                    break;
                default:
                    // not implemented
                    stderr.printf("Button %s pressed, button type not implemented\n", slot.title);
                    break;
            }
        }

        private void build_source_buttons(Box box) {

            // remove all buttons that are already there
            var children = box.get_children();
            foreach(var child in children) {
                box.remove(child);
            }

            // add new buttons
            var config = ConfigFile.instance();
            foreach(var button in config.buttons) {
                var ui_button = new Gtk.Button();
                ui_button.label = button.title;
                ui_button.name = button.id;
                ui_button.clicked.connect(on_source_button);
                box.pack_start(ui_button, true, true, 0);
            }

            box.show_all();
        }

        private void quit() {
            if (this.pipeline != null) {
                Gst.State state;
                Gst.State pending;
                this.pipeline.get_state(out state, out pending, 0);
                if (state == Gst.State.PLAYING) {
                    var eos = new Gst.Event.eos();
                    this.pipeline.send_event(eos);
                    this.pipeline.set_state(Gst.State.NULL);
                }
            }
            Gtk.main_quit();
        }
    }
}
