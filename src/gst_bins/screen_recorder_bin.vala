using Gtk;
using Gdk;
using Gst;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class ScreenRecorderBin: Gst.Bin {

        public ScreenRecorderBin() {
            GLib.Object(name: "screen_recorder_src");

            var config = ConfigFile.instance().rec_settings;

            var video_src = Gst.ElementFactory.make("ximagesrc", "video_src");
            video_src.set("display-name", ":0." + config.screen.to_string());
            video_src.set("use-damage", 0);
            video_src.set("startx", 0);
            video_src.set("starty", 0);
            video_src.set("endx", config.width - 1);
            video_src.set("endy", config.height - 1);
            video_src.set("do-timestamp", true);

            this.add(video_src);

            var ghost_src = new Gst.GhostPad("src", video_src.get_static_pad("src"));
            this.add_pad(ghost_src);
        }
    }
}