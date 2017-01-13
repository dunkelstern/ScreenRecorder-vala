using Gtk;
using ScreenRec;

namespace ScreenRec {
    Widget make_button_config(ButtonConfig[] buttons, SizeGroup left, SizeGroup right) {
        var container = new Grid();
        container.set_column_homogeneous(false);

        return container;
    }
}