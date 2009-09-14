AC_INIT([galactica], [0.2.0],
  [http://galactica.digitalmediaplanet.net])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([subdir-objects])
AM_MAINTAINER_MODE

VALA_REQUIRED=0.7.5
GLIB_REQUIRED=2.16.0
GEE_REQUIRED=0.3.0
GST_REQUIRED=0.10

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AM_PROG_VALAC([$VALA_REQUIRED])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

PKG_CHECK_MODULES(GALACTICA, glib-2.0 >= $GLIB_REQUIRED
                            gobject-2.0 >= $GLIB_REQUIRED
                            gee-1.0 >= $GEE_REQUIRED
                            gstreamer-0.10 >= $GST_REQUIRED
                            )
AC_SUBST(GALACTICA_CFLAGS)
AC_SUBST(GALACTICA_LIBS)

AC_CHECK_HEADERS([lua.h], HAVE_LUA_H=yes, AC_MSG_ERROR("Lua headers not found"))

if test "x$HAVE_LUA_H" = "xyes"; then
  LUA_LIBS="-llua"
  AC_SUBST(LUA_LIBS)
fi

AC_DEFINE_UNQUOTED(DATADIR, "${prefix}/share", install path of galactica.lua)

AC_CONFIG_FILES([
  Makefile
  lib/Makefile
  examples/Makefile
  data/Makefile
  tests/Makefile
  src/Makefile
])

AC_OUTPUT

echo "
$PACKAGE_NAME $PACKAGE_VERSION

    Install Prefix:               ${prefix}
"
