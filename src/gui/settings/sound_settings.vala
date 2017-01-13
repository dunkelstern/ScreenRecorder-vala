using Gtk;
using ScreenRec;

namespace ScreenRec {
    Widget make_sound_config(AudioConfig config, SizeGroup left, SizeGroup right) {
            var container = new Grid();
            container.set_column_homogeneous(false);
            container.row_spacing = 10;
            container.column_spacing = 10;
            container.border_width = 10;

            Widget prev;
            
            prev = add_dropdown_widget(
                container, null,
                (device) => { config.device = device; },
                "Device",
                PulseAudioContext.instance().audio_sources,
                config.device,
                left, right
            );
            
            prev = add_dropdown_widget(
                container, prev,
                (encoder) => { config.encoder = encoder; },
                "Encoder",
                AudioEncoderBin.available_encoders(),
                config.encoder,
                left, right
            );

            prev = add_spin_widget(
                container, prev,
                (bitrate) => { config.bitrate = bitrate; },
                "Bitrate",
                64,
                256,
                (int)config.bitrate,
                left, right
            );

            return container;
    }
}