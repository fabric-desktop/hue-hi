project(
  'hue-hi',
  'vala', 'c',
  version: '2023-10-24'
)

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
  meson.get_compiler('vala').find_library('linux'),
  dependency('glib-2.0'),
  dependency('json-glib-1.0'),
  dependency('gtk4'),
  dependency('gee-0.8', version: '>=0.18'),
  dependency('fabric-ui', fallback:['fabric-ui', 'fabric_ui_dep']),
]

# Add data for use at runtime
conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set('bindir', join_paths(get_option('prefix'), 'bin'))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

configure_file(
  input: 'hue-hi.desktop.in',
  output: 'hue-hi.desktop',
  configuration: conf,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Call subdirs
subdir('resources')
subdir('src')
