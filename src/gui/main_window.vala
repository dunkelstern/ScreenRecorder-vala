using Gtk;
using ScreenRec;

namespace ScreenRec {

    class MainWindow: Gtk.Window {
        private HeaderBar header;
        private Button record_button;
        private Button config_button;
        private Box button_box;

        public MainWindow() {
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
            build_source_buttons();

            // show the lot
            this.show_all();
        }

        private void on_record(Button button) {

        }

        private void on_config(Button button) {

        }

        private void on_stream(Button button) {

        }

        private void build_source_buttons() {
            var config = ConfigFile.instance();
            foreach(var button in config.buttons) {
                stdout.printf("Adding button %s of type %s\n", button.title, button.button_type.to_string());
            }
        }
    }
}
