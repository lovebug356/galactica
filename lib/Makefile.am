NULL=

noinst_LTLIBRARIES=libgalactica.la

libgalactica_la_SOURCES = \
  galactica-console-key.c \
  galactica-console-width.c \
  galactica-console.vala \
  galactica-lua.vala \
  galactica-object.vala \
  galactica-output.vala \
  galactica-playlist.vala \
  galactica-playlistbuilder.vala \
  galactica-track-custompipeline.vala \
  galactica-track-playbin.vala \
  galactica-track-playbin1.vala \
  galactica-track-playbin2.vala \
  galactica-track.vala \
  $(NULL)

libgalactica_la_VALAFLAGS = \
  --library galactica \
  -H galactica.h \
  --vapidir ./ \
  --pkg gee-1.0 \
  --pkg gstreamer-0.10 \
  --pkg lua5.1 \
  --pkg config \
  $(NULL)

libgalactica_la_CFLAGS = \
  $(GALACTICA_CFLAGS) \
  $(NULL)

libgalactica_la_LIBADD = \
  $(GALACTICA_LIBS) \
  $(LUA_LIBS) \
  $(NULL)

EXTRA_DIST= galactica.h galactica.vapi
