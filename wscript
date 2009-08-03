#! /usr/bin/env python

VERSION = '0.2.0'
APPNAME = 'galactica'
API_VERSION = '1.0'

srcdir = '.'
blddir = 'build'


def set_options(opt):
  opt.tool_options('compiler_cc')
  opt.tool_options('gnu_dirs')

def configure(conf):
  conf.check_tool('compiler_cc cc misc vala gnu_dirs')
  conf.check_cfg (package='gstreamer-0.10',
      uselib_store='GSTREAMER',
      mandatory=True,
      args='--cflags --libs')
  conf.check_cfg (package='gee-1.0',
      uselib_store='GEE',
      mandatory=True,
      args='--cflags --libs')
  conf.check_cfg (package='lua5.1',
      uselib_store='LUA',
      mandatory=True,
      args='--cflags --libs')

  conf.define('PACKAGE', APPNAME)
  conf.define('PACKAGE_NAME', APPNAME)
  conf.define('PACKAGE_STRING', APPNAME + '-' + VERSION)
  conf.define('PACKAGE_VERSION', APPNAME + '-' + VERSION)

  conf.define('VERSION', VERSION)
  conf.define('API_VERSION', API_VERSION)
  conf.define('PACKAGE_VERSION', VERSION)
  conf.define('PACKAGE_PREFIX', conf.env['PREFIX'])
  conf.define('PACKAGE_DATADIR', conf.env['DATADIR'])

  conf.write_config_header('config.h')

def build(bld):
  bld.add_subdirs ('share')
  bld.add_subdirs ('lib')
  bld.add_subdirs ('src')
  bld.add_subdirs ('examples')
