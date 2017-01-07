using Gtk;
using ScreenRec;

namespace ScreenRec {

    class MainWindow: Gtk.Window {
        private HeaderBar header;
        private Button record_button;
        private Button config_button;
        private Box button_box;
        private PlaybackWindow[] windows = {};

        public MainWindow() {
            // window settings
            this.title = "Screen Recorder";
            this.set_default_size (200, 200);
            this.destroy.connect (Gtk.main_quit);
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

        private void on_record(Button button) {

        }

        private void on_config(Button button) {

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
    }
}
