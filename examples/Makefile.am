NULL=

AM_VALAFLAGS = \
  --pkg galactica --vapidir $(top_builddir)/lib \
  --pkg gee-1.0 \
  --pkg gstreamer-0.10 \
  $(NULL)

AM_CFLAGS = \
  $(GALACTICA_CFLAGS) \
  -I$(top_srcdir)/lib \
  $(NULL)

AM_LDFLAGS = \
  $(GALACTICA_LIBS) \
  $(top_builddir)/lib/libgalactica.la \
  $(NULL)

noinst_PROGRAMS=galactica-file galactica-audiotestsrc

galactica_file_SOURCES = simple_file_player.vala
galactica_audiotestsrc_SOURCES = simple_audiotestsrc_player.vala
