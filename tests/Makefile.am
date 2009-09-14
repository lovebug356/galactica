NULL=

AM_VALAFLAGS = \
  --pkg galactica --vapidir $(top_builddir)/lib \
  --pkg gee-1.0 \
  --pkg gstreamer-0.10 \
  $(NULL)

AM_CFLAGS = \
  $(GALACTICA_CFLAGS) \
  -I$(top_builddir)/lib \
  $(NULL)

AM_LDFLAGS = \
  $(GALACTICA_LIBS) \
  $(top_builddir)/lib/libgalactica.la \
  $(NULL)

noinst_PROGRAMS= \
  test-galactica-playlist \
  test-galactica-playbin \
  test-galactica-custom \
  $(NULL)
TESTS=$(build_PROGRAMS)

test_galactica_playlist_SOURCES = test-galactica-playlist.vala
test_galactica_playbin_SOURCES = test-galactica-playbin.vala
test_galactica_custom_SOURCES = test-galactica-custom.vala
