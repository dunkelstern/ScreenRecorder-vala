using Gst;

namespace ScreenRec {
    interface ManualVideoRoutingSink : Gst.Bin {
        public abstract void consume_sample(Sample buffer);
        public abstract void set_input_caps(Caps caps);
        public abstract void shutdown_with_eos();
        public abstract void connect_to_source(ManualVideoRoutingSrc src);
    }

    interface ManualVideoRoutingSrc : Gst.Bin {
        public abstract void start_emitting_buffers(ManualVideoRoutingSink sink);
        public abstract void stop_emitting_buffers();
    }
}