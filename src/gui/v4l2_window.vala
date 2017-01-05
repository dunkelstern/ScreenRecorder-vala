using Gtk;
using Gdk;
using Gst;
using ScreenRec;

namespace ScreenRec {

    class V4l2Window: PlaybackWindow {
        private V4l2ButtonConfig config;
        private Button settings_button;
        private Button focus_button;

        public V4l2Window(V4l2ButtonConfig config) {
            base();
            this.config = config;
            this.title = config.title;

            settings_button = new Gtk.Button();
            var icon = new ThemedIcon("preferences-system");
            var image = new Image.from_gicon(icon, IconSize.BUTTON);
            settings_button.image = image;
            settings_button.clicked.connect(on_settings);
            header.pack_end(settings_button);

            focus_button = new Gtk.Button();
            icon = new ThemedIcon("video-display-symbolic");
            image = new Image.from_gicon(icon, IconSize.BUTTON);
            focus_button.image = image;
            focus_button.clicked.connect(on_focus);
            header.pack_end(focus_button);

            this.setup((int)config.width / 2, (int)config.height / 2, true);
        }

        protected override void stop() {
            base.stop();
            this.hide();
        }

        private void on_focus(Button source) {

        }

        private void on_settings(Button source) {
            string[] settings_apps = {
                "/usr/bin/qv4l2",
                "/usr/bin/v4l2ucp"
            };

            foreach(var app in settings_apps) {
                var file = File.new_for_path(app);
                if (file.query_exists()) {
                    try {
                        var launcher = new SubprocessLauncher(SubprocessFlags.NONE);
                        launcher.spawnv({app});
                        break;
                    } catch (Error e) {
                        stderr.printf("Could not launch config tool: %s", e.message);
                    }
                }
            }
        }
    }
}
