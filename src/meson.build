sources = files(
  'application.vala',
)

subdir('models')
subdir('pages')

executable(
  meson.project_name(),
  [resources, sources],
  dependencies: dependencies,
  c_args: [
    '-include', 'config.h'
  ],
  vala_args: [
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
  ],
  install: true,
)
