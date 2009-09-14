NULL=

AM_VALAFLAGS = \
  --pkg galactica --vapidir $(top_builddir)/lib \
  --pkg gee-1.0 \
  --pkg gstreamer-0.10 \
  --pkg config \
  $(NULL)

AM_CFLAGS = \
  $(GALACTICA_CFLAGS) \
  -I$(top_srcdir)/lib/ \
  $(NULL)

AM_LDFLAGS = \
  $(GALACTICA_LIBS) \
  $(top_builddir)/lib/libgalactica.la \
  $(LUA_LIBS) \
  $(NULL)

bin_PROGRAMS=galactica
galactica_SOURCES = galactica.vala
