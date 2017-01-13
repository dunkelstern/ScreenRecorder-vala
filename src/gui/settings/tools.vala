using Gtk;
using Gee;

namespace ScreenRec {

    delegate void UpdateIntFunc(int value);
    delegate void UpdateStringFunc(string value);

    Label make_label(Grid parent, Widget? top, string title, SizeGroup? left) {
        var label = new Label(title);
        label.halign = Align.END;
        label.xalign = 0;
        label.vexpand = false;
        label.justify = Justification.LEFT;
        parent.attach_next_to(label, top, PositionType.BOTTOM, 1, 1);
        if (left != null) {
            left.add_widget(label);
        }
    
        return label;        
    }

    Widget add_spin_widget(
        Grid parent,
        Widget? top,
        owned UpdateIntFunc callback,
        string title,
        int min,
        int max,
        int default,
        SizeGroup? left,
        SizeGroup? right) {

        var label = make_label(parent, top, title, left);

        var adj = new Adjustment(default, min, max, 1, 80, 0);
        var spinner = new SpinButton(adj, 1, 0);
        spinner.value = default;
        spinner.hexpand = true;
        spinner.value_changed.connect((spin) => { callback((int)spin.value); });
        parent.attach_next_to(spinner, label, PositionType.RIGHT, 1, 1);
        if (right != null) {
            right.add_widget(spinner);
        }

        return label;
    }

    Widget add_textinput_widget(
        Grid parent,
        Widget? top,
        owned UpdateStringFunc callback,
        string title,
        string default,
        SizeGroup? left,
        SizeGroup? right) {

        var label = make_label(parent, top, title, left);

        var textbox = new Entry();
        textbox.text = default;
        textbox.hexpand = true;
        textbox.changed.connect((txt) => { callback(txt.get_chars()); });
        parent.attach_next_to(textbox, label, PositionType.RIGHT, 1, 1);
        if (right != null) {
            right.add_widget(textbox);
        }

        return label;
    }

    Widget add_dropdown_widget(
        Grid parent,
        Widget? top,
        owned UpdateStringFunc callback,
        string title,
        HashMap<string,string> options,
        string default,
        SizeGroup? left,
        SizeGroup? right) {

        var label = make_label(parent, top, title, left);

        var list_store = new Gtk.ListStore(2, typeof(string), typeof(string));
        TreeIter iter;

        int active = 0;

        int i = 0;
        var it = options.map_iterator ();
        for (var has_next = it.next (); has_next; has_next = it.next ()) {
            list_store.append (out iter);
            list_store.set (iter, 0, it.get_value(), 1, it.get_key());
            if (it.get_key() == default) {
                active = i;
            }
            i++;
        }

        var combobox = new ComboBox.with_model(list_store);
        var renderer_text = new CellRendererText();
        combobox.pack_start(renderer_text, true);
        combobox.add_attribute(renderer_text, "text", 0);
        combobox.active = active;
        combobox.hexpand = true;

        combobox.changed.connect(() => {
            TreeIter selected;
            Value value;
            combobox.get_active_iter(out selected);
            list_store.get_value(selected, 1, out value);
            stderr.printf("Selected %s\n", (string)value);
            callback((string)value);
        });
        parent.attach_next_to(combobox, label, PositionType.RIGHT, 1, 1);
        if (right != null) {
            right.add_widget(combobox);
        }

        return label;
    }
}