using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class PlayerWindow: PlaybackWindow {
        private PlayerButtonConfig _config;
        public override ButtonConfig config {
            get {
                return _config;
            }
            set {
                _config = value as PlayerButtonConfig;
            }
        }

        private Button play_button;
        private Scale seek_bar;

        public PlayerWindow(PlayerButtonConfig config, MainWindow main_window) {
            base(config, main_window);
            this.auto_start = _config.auto_play;
            var icon_name = "media-playback-start-symbolic";
            if (auto_start) {
                icon_name = "media-playback-pause-symbolic";
            }

            // play/pause button
            play_button = new Gtk.Button();
            var icon = new ThemedIcon(icon_name);
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            play_button.image = image;
            play_button.clicked.connect(on_play);
            header.pack_start(play_button);

            if (config.seek_bar) {
                // only include the seek bar if it's enabled in the first place
                seek_bar = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.001);
                seek_bar.set_draw_value(false);
                seek_bar.set_hexpand(true);
                seek_bar.change_value.connect(on_seek);
                this.header.set_custom_title(seek_bar);
            }

            build_pipeline();
            this.setup(960, 540, true);
        }

        private void build_pipeline() {
            // playback element
            var src = Gst.ElementFactory.make("playbin", "source");
            src.set("uri", "file://" + this._config.filename);

            // output stage
            var sink = new PlaybackBin(this._config.hwaccel, true);
            src.set("video-sink", sink);

            // assemble pipeline
            this.pipeline = new Gst.Pipeline("playback");
            this.pipeline.add(src);

            // on end of file put the play/pause button back into play state
            this.pipeline.get_bus().message.connect((bus, message) => {
               if (message.type == Gst.MessageType.EOS) {
                    var icon_name = "media-playback-start-symbolic";
                    var icon = new ThemedIcon(icon_name);
                    var image = new Image.from_gicon(icon, IconSize.BUTTON);
                    play_button.image = image;
               }
            });
        }

        protected override void stop() {
            base.stop();
            this.hide();
        }

        private void on_play(Button source) {
            Gst.State state;
            Gst.State pending;
            this.pipeline.get_state(out state, out pending, 0);

            // set the play/pause button to display the correct symbol
            var icon_name = "media-playback-start-symbolic";
            if (state == Gst.State.PLAYING) {
                if (this._config.seek_bar) {
                    this.pipeline.set_state(Gst.State.PAUSED);
                } else {
                    this.pipeline.set_state(Gst.State.READY);                    
                }
            } else {
                if (this._config.seek_bar) {
                    icon_name = "media-playback-pause-symbolic";
                } else {
                    icon_name = "media-playback-stop-symbolic";
                }
                this.pipeline.set_state(Gst.State.PLAYING);

                // when playing start updating the seek bar
                if (this._config.seek_bar) {
                    Timeout.add(50, () => {
                        Gst.State pipeline_state;
                        Gst.State pipeline_pending;
                        this.pipeline.get_state(out pipeline_state, out pipeline_pending, 0);
                        // exit this timer when the pipeline switches to another state than play
                        if (pipeline_state != Gst.State.PLAYING) {
                            return false;
                        }

                        // set seek bar to display position (update max value too)
                        int64 duration = 0;
                        int64 current = 0;
                        this.pipeline.query_duration(Gst.Format.TIME, out duration);
                        this.pipeline.query_position(Gst.Format.TIME, out current);
                        this.seek_bar.set_range(0, duration);
                        this.seek_bar.set_value(current);

                        return true;
                    });
                }
            }

            // update button icon
            var icon = new ThemedIcon(icon_name);
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            play_button.image = image;
        }

        private bool on_seek(ScrollType source, double new_value) {
            // save pipeline state
            Gst.State pipeline_state;
            Gst.State pipeline_pending;
            this.pipeline.get_state(out pipeline_state, out pipeline_pending, 0);

            // seek to the correct position
            int64 duration = 0;
            int64 current = 0;
            this.pipeline.query_duration(Gst.Format.TIME, out duration);
            this.pipeline.query_position(Gst.Format.TIME, out current);
            this.pipeline.seek(1.0, Gst.Format.TIME, Gst.SeekFlags.FLUSH, Gst.SeekType.SET, (int64)new_value, Gst.SeekType.NONE, duration);

            // restore pipeline state
            this.pipeline.set_state(pipeline_state);

            // do not bubble up the event
            return false;
        }
    }
}
