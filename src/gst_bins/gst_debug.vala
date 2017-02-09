
// dump a GStreamer pipeline/Bin recursively
public void dump_pipeline(Gst.Bin pipeline, int indent = 0) {
    string indent_str = "";
    for(var i = 0; i < indent; i++) {
        indent_str = indent_str + "    ";
    }

    if (indent == 0) {
        stderr.puts("----------------------------------------------\n");
    }

    stderr.puts("\n");

    var iterator = pipeline.iterate_sorted();
    Value item;
    while (iterator.next(out item) != Gst.IteratorResult.DONE) {
        var element = item as Gst.Element;

        Gst.State st = Gst.State.NULL;
        Gst.State pend = Gst.State.NULL;
        element.get_state(out st, out pend, 0);

        stderr.printf("\n%s%s (name: %s, state: %s, pending: %s):\n", indent_str, element.get_type().name(), element.name, st.to_string(), pend.to_string());

        var sub_iterator = element.iterate_src_pads();
        Value src;
        while (sub_iterator.next(out src) != Gst.IteratorResult.DONE) {
            var sub_element = src as Gst.Pad;

            if ((sub_element.get_peer() != null) && (sub_element.get_peer().get_parent_element() != null)) {
                stderr.printf(
                    "%s - %s connected to %s\n",
                    indent_str, 
                    sub_element.name,
                    sub_element.get_peer().get_parent_element().name
                );
            } else {
                stderr.printf(
                    "%s - %s UNCONNECTED\n",
                    indent_str, 
                    sub_element.name
                );                
            }
            stderr.printf(
                "%s   caps: %s\n",
                indent_str, 
                sub_element.get_current_caps().to_string()
            );
        }

        sub_iterator = element.iterate_sink_pads();
        Value sink;
        while (sub_iterator.next(out sink) != Gst.IteratorResult.DONE) {
            var sub_element = sink as Gst.Pad;
            if ((sub_element.get_peer() != null) && (sub_element.get_peer().get_parent_element() != null)) {
                stderr.printf(
                    "%s - %s connected to %s\n",
                    indent_str, 
                    sub_element.name,
                    sub_element.get_peer().get_parent_element().name
                );
            } else {
                stderr.printf(
                    "%s - %s UNCONNECTED\n",
                    indent_str, 
                    sub_element.name
                );                
            }
            stderr.printf(
                "%s   caps: %s\n",
                indent_str,
                sub_element.get_current_caps().to_string()
            );
        }

        if (element is Gst.Bin) {
            dump_pipeline(element as Gst.Bin, indent + 1);
        }
    }
}