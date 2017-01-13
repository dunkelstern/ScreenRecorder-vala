using Gtk;
using ScreenRec;

namespace ScreenRec {

    Widget make_recorder_config(owned RecorderConfig config, SizeGroup left, SizeGroup right) {
        var container = new Grid();
        container.set_column_homogeneous(false);
        container.row_spacing = 10;
        container.column_spacing = 10;
        container.border_width = 10;

        Widget prev;

        prev = add_spin_widget(
            container, null,
            (screen) => { config.screen = screen; },
            "Screen",
            0,
            16,
            (int)config.screen,
            left, right
        );
        
        prev = add_dropdown_widget(
            container, prev,
            (encoder) => { config.encoder = encoder; },
            "Encoder",
            VideoEncoderBin.available_encoders(),
            config.encoder,
            left, right
        );
        
        prev = add_textinput_widget(
            container, prev,
            (filename) => { config.filename = filename; },
            "Filename",
            config.filename,
            left, right
        );

        prev = add_spin_widget(
            container, prev,
            (width) => { config.width = width; },
            "Width",
            0,
            Gdk.Screen.width(),
            (int)config.width,
            left, right
        );

        prev = add_spin_widget(
            container, prev,
            (height) => { config.height = height; },
            "Height",
            0,
            Gdk.Screen.height(),
            (int)config.height,
            left, right
        );

        prev = add_spin_widget(
            container, prev,
            (fps) => { config.fps = fps; },
            "Framerate",
            1,
            120,
            (int)config.fps,
            left, right
        );

        prev = add_spin_widget(
            container, prev,
            (scale_width) => { config.scale_width = scale_width; },
            "Scale Width",
            0,
            Gdk.Screen.width(),
            (int)config.scale_width,
            left, right
        );

        prev = add_spin_widget(
            container, prev,
            (scale_height) => { config.scale_height = scale_height; },
            "Scale Height",
            0,
            Gdk.Screen.height(),
            (int)config.scale_height,
            left, right
        );

        return container;
    }
}
