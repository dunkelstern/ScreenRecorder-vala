bin_PROGRAMS = screenrec

screenrec_SOURCES = \
	main.vala \
	config/configfile.vala \
	config/config.vala \
	config/config_audio.vala \
	config/config_recording.vala \
	config/config_streaming.vala \
	config/config_buttons.vala \
	gst_bins/audio_encoder_bin.vala \
	gst_bins/video_encoder_bin.vala \
	gst_bins/playback_bin.vala \
	gui/main_window.vala \
	gui/playback_window.vala \
	gui/v4l2_window.vala \
	gui/rtmp_window.vala \
	gui/mjpeg_pipe_window.vala \
	gui/player_window.vala \
	gui/settings_window.vala

screenrec_CPPFLAGS = $(SCREENREC_CFLAGS)
screenrec_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg json-glib-1.0 \
	--pkg gstreamer-1.0 \
	--pkg gstreamer-net-1.0 \
	--pkg gstreamer-rtsp-1.0 \
	--pkg gio-2.0 \
	--pkg gdk-3.0

screenrec_LDADD = $(SCREENREC_LIBS)

-include $(top_srcdir)/git.mk
