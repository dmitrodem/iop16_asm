project('iop16_asm', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])

flex  = find_program('flex',  required: true)
bison = find_program('bison', required: true)

lexgen = generator(
  flex,
  output: '@PLAINNAME@.yy.c',
  arguments: ['-o', '@OUTPUT@', '@INPUT@'])
parsergen = generator(
  bison,
  output: ['@BASENAME@.tab.c', '@BASENAME@.tab.h'],
  arguments : [
    '@INPUT@',
    '--defines=@OUTPUT1@',
    '--output=@OUTPUT0@',
    '--debug'
  ])

subdir('src')

exe = executable(
  'iop16_asm',
  sources,
  lexfiles,
  parserfiles,
  include_directories: 'src',
  install : true,
  c_args: ['-UTEST_LEXER', '-UTEST_PARSER'])

test_exe = executable(
  'iop16_test',
  test_srcs,
  include_directories: 'src')

test('Simple test',
     exe,
     args: [meson.source_root() + '/tests/test.asm']
    )
