bin_PROGRAMS = screenrec

screenrec_SOURCES = \
	main.vala \
	config/configfile.vala \
	config/config.vala \
	config/config_audio.vala \
	config/config_recording.vala \
	config/config_streaming.vala \
	config/config_buttons.vala \
	gst_bins/gst_debug.vala \
	gst_bins/audio_encoder_bin.vala \
	gst_bins/video_encoder_bin.vala \
	gst_bins/muxer_bin.vala \
	gst_bins/playback_bin.vala \
	gst_bins/screen_recorder_bin.vala \
	gst_bins/audio_recorder_bin.vala \
	gst_bins/manual_routing_interface.vala \
	gui/main_window.vala \
	gui/playback_window.vala \
	gui/v4l2_window.vala \
	gui/rtmp_window.vala \
	gui/mjpeg_pipe_window.vala \
	gui/player_window.vala \
	gui/settings_window.vala \
	gui/settings/button_settings.vala \
	gui/settings/recording_settings.vala \
	gui/settings/sound_settings.vala \
	gui/settings/tools.vala \
	audio/pulse.vala

screenrec_CPPFLAGS = $(SCREENREC_CFLAGS)
screenrec_VALAFLAGS = \
	--vapidir=../extra-vapi/ \
	--pkg gtk+-3.0 \
	--pkg json-glib-1.0 \
	--pkg gstreamer-1.0 \
	--pkg gstreamer-base-1.0 \
	--pkg gstreamer-video-1.0 \
	--pkg gstreamer-net-1.0 \
	--pkg gstreamer-rtsp-1.0 \
	--pkg gstreamer-app-1.0 \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gdk-3.0 \
	--pkg gdk-x11-3.0 \
	--pkg x11 \
	--pkg uuid \
	--pkg libpulse \
	--pkg libpulse-mainloop-glib \
	--pkg gee-0.8

screenrec_LDADD = $(SCREENREC_LIBS)

-include $(top_srcdir)/git.mk
