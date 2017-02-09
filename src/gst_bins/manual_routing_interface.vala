using Gst;

namespace ScreenRec {
    interface ManualVideoRoutingSink : GLib.Object {
        public abstract bool consume_sample(Sample buffer);
        public abstract Caps get_input_caps();
        public abstract void shutdown_with_eos();
        public abstract void connect_to_source(ManualVideoRoutingSrc src);
    }

    interface ManualVideoRoutingSrc : GLib.Object {
        public abstract void start_emitting_buffers(ManualVideoRoutingSink sink);
        public abstract void stop_emitting_buffers();
    }
}