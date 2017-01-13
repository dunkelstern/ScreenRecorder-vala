using PulseAudio;
using Gee;
using ScreenRec;

namespace ScreenRec {

    class PulseAudioContext : GLib.Object {
        private static GLib.Once<PulseAudioContext> _instance;

        public static unowned PulseAudioContext instance () {
            return _instance.once(() => { return new PulseAudioContext(); });
        }

        private GLibMainLoop loop;
        private Context context;

        public HashMap<string, string> audio_sources;

        public PulseAudioContext() {
            this.audio_sources = new HashMap<string, string>();
            this.loop = new GLibMainLoop();
            this.context = new Context(loop.get_api(), null);
            this.context.set_state_callback(this.cstate_cb);

            if (this.context.connect(null, Context.Flags.NOFAIL, null) < 0) {
                stderr.printf("pa_context_connect() failed: %s\n", PulseAudio.strerror(context.errno()));
            }
        }

        private void cstate_cb(Context context) {
            Context.State state = context.get_state();
            if (state == Context.State.UNCONNECTED) { stderr.printf("state UNCONNECTED\n"); }
            if (state == Context.State.CONNECTING) { stderr.printf("state CONNECTING\n"); }
            if (state == Context.State.AUTHORIZING) { stderr.printf("state AUTHORIZING,\n"); }
            if (state == Context.State.SETTING_NAME) { stderr.printf("state SETTING_NAME\n"); }
            if (state == Context.State.READY) { stderr.printf("state READY\n"); }
            if (state == Context.State.FAILED) { stderr.printf("state FAILED,\n"); }
            if (state == Context.State.TERMINATED) { stderr.printf("state TERMINATED\n"); }

            if (state == Context.State.READY) {
                this.context.get_source_info_list((ctx, info, eol) => {
                    if (info != null) {
                        audio_sources.set(info.name, info.description);
                        stderr.printf("Source %s: %s\n", info.name, info.description);
                    }
                });
            }
        }
    }
}