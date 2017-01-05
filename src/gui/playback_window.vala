using Gtk;
using Gdk;
using ScreenRec;
using Gst;

namespace ScreenRec {

    class PlaybackWindow: Gtk.Window {
        protected HeaderBar header;
        private Button zoom_button;
        private DrawingArea video_area;

        private uint* xid;

        protected Gst.Bus? bus;
        protected Pipeline? pipeline;
        protected bool auto_start = false;

        public PlaybackWindow() {
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

            // Zoom Button
            zoom_button = new Button();
            var icon = new ThemedIcon("zoom-fit-symbolic");
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            zoom_button.image = image;
            zoom_button.clicked.connect(on_zoom);
            header.pack_end(zoom_button);

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

            // show the lot
            this.show_all();
        }

        protected void setup(int width = 640, int height = 480, bool fixed = false) {
            this.show_all();

            this.xid = (uint*)((Gdk.X11.Window)this.video_area.get_window()).get_xid();
            this.set_default_size(width, height);
            this.video_area.set_size_request(width, height);
            if (fixed) {
                this.resizable = false;
            }

            this.play();
            this.delete_event.connect(() => {
                this.stop();
                return true;
            });
        }

        protected virtual void play() {
            if (this.pipeline == null) {
                return;
            }

            this.bus = this.pipeline.get_bus();
            this.bus.add_signal_watch();
            this.bus.enable_sync_message_emission();

            this.bus.message.connect(on_message);
            this.bus.connect("sync-message::element", on_sync_message);
            this.pipeline.set_state(Gst.State.PLAYING);
        }

        protected virtual void stop() {
            if (this.pipeline != null) {
                this.pipeline.set_state(Gst.State.NULL);
            }
        }

        protected virtual void on_zoom(Button source) {
            // overridden
        }

        protected virtual void on_message(Gst.Bus bus, Gst.Message message) {
            if (message.type == Gst.MessageType.ERROR) {
                Error err;
                string debug;
                message.parse_error(out err, out debug);

                stderr.printf("ERROR: %s\n", err.message);
                if (this.pipeline != null) {
                    this.pipeline.set_state(Gst.State.NULL);
                }
            }
        }

        protected virtual void on_sync_message(Gst.Bus bus, Gst.Message message) {
            if(Gst.Video.is_video_overlay_prepare_window_handle_message (message)) {
                var image_sink = message.src as Gst.Video.Overlay;
                image_sink.set_window_handle(this.xid);
            }
        }
    }
}
