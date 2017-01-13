using Gtk;
using ScreenRec;

namespace ScreenRec {

    interface SettingsWindowDelegate : Gtk.Window {
        public abstract void update_callback();
    }

    class SettingsWindow: Gtk.Window {
        private HeaderBar header;
        private Button close_button;
        private StackSwitcher stack_switcher;
        private Stack stack;
        private SizeGroup size_group_left;
        private SizeGroup size_group_right;
        private Widget rec_config;
        private Widget sound_config;
        private Widget button_config;
        private SettingsWindowDelegate delegate;

        public SettingsWindow(SettingsWindowDelegate parent) {
            var config = ConfigFile.instance();
            this.delegate = parent;

            // window settings
            this.title = "Settings - Screen Recorder";
            this.set_default_size (400, 400);
            this.border_width = 0;
            this.resizable = false;

            // Header bar
            header = new HeaderBar();
            header.set_show_close_button(false);
            header.title = "Settings - Screen Recorder";
            this.set_titlebar(header);

            // Save Button
            close_button = new Button();
            close_button.label = "Save";
            close_button.clicked.connect(on_close);
            var context = close_button.get_style_context();
            context.add_class("suggested-action");
            header.pack_end(close_button);

            // Stack switcher
            stack_switcher = new StackSwitcher();
            header.set_custom_title(stack_switcher);

            // Stack
            stack = new Stack();
            stack_switcher.set_stack(stack);
            this.add(stack);

            // Config section
            size_group_left = new SizeGroup(SizeGroupMode.HORIZONTAL);
            size_group_right = new SizeGroup(SizeGroupMode.HORIZONTAL);

            // -> Recording
            rec_config = make_recorder_config(config.rec_settings, size_group_left, size_group_right);
            stack.add_titled(rec_config, "rec_config", "Recording");

            // -> Sound
            sound_config = make_sound_config(config.audio_settings, size_group_left, size_group_right);
            stack.add_titled(sound_config, "sound_config", "Sound");

            // -> Source Buttons
            button_config = make_button_config(config.buttons, size_group_left, size_group_right);
            stack.add_titled(button_config, "button_config", "Buttons");

            // show the lot
            this.show_all();
            this.set_transient_for(parent);
            this.modal = true;
            this.destroy_with_parent = true;
        }

        private void on_close(Button button) {
            var config = ConfigFile.instance();
            config.save();
            this.delegate.update_callback();
            this.destroy();
        }

    }
}
