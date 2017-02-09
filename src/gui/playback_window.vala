using Gtk;
using Gdk;
using ScreenRec;
using Gst;

namespace ScreenRec {

    class PlaybackWindow: Gtk.Window, ManualVideoRoutingSrc {
        private ButtonConfig _config;
        public virtual ButtonConfig config {
            get {
                return _config;
            }
            set {
                _config = value;
            }
        }

        private Button zoom_button;
        private Button exclusive_button;
        private ulong sync_handler;
        private ulong message_handler;
        protected MainWindow main_window;

        private uint* xid;

        protected DrawingArea video_area;
        protected HeaderBar header;
        protected Gst.Bus? bus;
        protected Pipeline? pipeline;
        protected bool auto_start = true;
        protected bool zoomed = false;
        protected Gst.App.Sink appsink;
        protected Gst.Element tee;

        private ManualVideoRoutingSink? sink;

        public PlaybackWindow(ButtonConfig config, MainWindow main_window) {
            this.config = config;
            this.main_window = main_window;

            // window settings
            this.title = config.title;
            this.set_default_size (200, 200);
            this.destroy.connect (Gtk.main_quit);
            this.border_width = 0;
            this.resizable = false;

            // Header bar
            header = new HeaderBar();
            header.set_show_close_button(true);
            header.title = config.title;
            this.set_titlebar(header);

            // Zoom Button
            zoom_button = new Button();
            var icon = new ThemedIcon("zoom-fit-symbolic");
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            zoom_button.image = image;
            zoom_button.clicked.connect(on_zoom);
            header.pack_end(zoom_button);

            // Exclusive Button
            exclusive_button = new Button();
            exclusive_button.label = "Exclusive";
            exclusive_button.clicked.connect(on_exclusive);
            header.pack_end(exclusive_button);

            // Debug Button
            var debug_button = new Button();
            debug_button.label = "Debug";
            debug_button.clicked.connect(on_debug);
            header.pack_end(debug_button);

            // Video area
            video_area = new Gtk.DrawingArea();
            video_area.draw.connect((context) => {

                // paint it black
                int height = video_area.get_allocated_height();
			    int width = video_area.get_allocated_width();
                context.set_source_rgba(0, 0, 0, 1.0);
                context.rectangle(0, 0, width, height);
                context.fill();

                return true;
            });
            this.add(video_area);
        }

        protected void setup(int width = 640, int height = 480, bool fixed = false) {
            // setup function to be called after setting up all widgets
            this.set_default_size(width, height);
            this.video_area.set_size_request(width, height);
            if (fixed) {
                this.resizable = false;
            }

            // connect play and stop actions
            this.show.connect(play);
            this.hide.connect(stop);
            this.delete_event.connect(() => {
                this.stop();
                return true;
            });

            // show the window
            this.show_all();
        }

        protected virtual void play() {
            // aquire the XID of the video area
            uint val = 0;
            this.xid = &val;
            this.xid = (uint*)((Gdk.X11.Window)this.video_area.get_window()).get_xid();
            stderr.printf("XID: %p\n", this.xid);

            // if there's no pipeline there's not point int trying anything
            stderr.printf("%s: play\n", this.config.title);
            if (this.pipeline == null) {
                return;
            }

            // fetch bus, add signal watchers
            this.bus = this.pipeline.get_bus();
            this.bus.add_signal_watch();
            this.bus.enable_sync_message_emission();

            // this is used for reparenting the overlay window into our target
            this.sync_handler = this.bus.sync_message.connect((bus,message) => {
                if(Gst.Video.is_video_overlay_prepare_window_handle_message (message)) {
                    stderr.printf("Setting xid\n");
                    var overlay = message.src as Gst.Video.Overlay;
                    assert(overlay != null);
                    overlay.set_window_handle(this.xid);
                }
            });

            // on error stop the pipeline and log the error
            this.message_handler = this.bus.message.connect((bus, message) => {
               if (message.type == Gst.MessageType.ERROR) {
                    Error err;
                    string debug;
                    message.parse_error(out err, out debug);

                    stderr.printf("ERROR: %s\n", err.message);
                    if (this.pipeline != null) {
                        this.pipeline.set_state(Gst.State.NULL);
                    }
                }
            });

            // when we should autostart go into playing state immediately
            if (this.auto_start) {
                this.pipeline.set_state(Gst.State.PLAYING);
            } else {
                // else just start and pause the pipeline
                this.pipeline.set_state(Gst.State.PAUSED);
            }
        }

        protected virtual void stop() {
            // stop would only work if the window is actually visible
            if (this.visible) {
                stderr.printf("%s: stop\n", this.config.title);
                if (this.pipeline != null) {
                    // disconnect the message handlers
                    this.bus.disconnect(this.sync_handler);
                    this.bus.disconnect(this.message_handler);

                    // stop the pipeline and free resources
                    this.pipeline.set_state(Gst.State.NULL);
                }
            }
        }

        protected virtual void on_debug(Button source) {
            dump_pipeline(this.pipeline);
        }

        private void on_exclusive(Button source) {
            if (main_window.video_encoder != null) {
                main_window.video_encoder.connect_to_source(this);
            }
        }

        protected FlowReturn new_preroll() {
            appsink.pull_preroll();
            return FlowReturn.OK;
        }

        protected FlowReturn new_sample() {
            var sample = appsink.pull_sample();

            if (this.sink != null) {
                if (sample != null) {
                    var result = this.sink.consume_sample(sample);
                    if (result == false) {
                        this.stop_emitting_buffers();
                    }
                }
            }

            if (appsink.eos) {
                stderr.printf("End of stream in screen recorder\n");
            }
            return FlowReturn.OK;
        }

        public void start_emitting_buffers(ManualVideoRoutingSink sink) {
            this.sink = sink;
        }

        public void stop_emitting_buffers() {
            this.sink = null;
        }

        protected virtual void on_zoom(Button source) {
            // overridden
        }
    }
}
