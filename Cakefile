# Building Chosen requires coffee-script and uglify-js. For
# help installing, try:
#
# `npm -g install coffee-script uglify-js`
#
fs               = require 'fs'
path             = require 'path'
{spawn, exec}    = require 'child_process'
CoffeeScript     = require 'coffee-script'
{parser, uglify} = require 'uglify-js'

javascripts = {
  'chosen/chosen.jquery.js': [
    'coffee/chosen/select-parser.coffee'
    'coffee/chosen.jquery.coffee'
  ]
  'chosen/chosen.proto.js': [
    'coffee/chosen/select-parser.coffee'
    'coffee/chosen.proto.coffee'
  ]
}

Array::unique = ->
  output = {}
  output[@[key]] = @[key] for key in [0...@length]
  value for key, value of output

# Gather a list of unique source files.
#
source_files = ->
  all_sources = []
  for javascript, sources of javascripts
    for source in sources
      all_sources.push source
  all_sources.unique()

# Build Chosen.
#
task 'build', 'build Chosen from source', build = (cb) ->
  for javascript, sources of javascripts
    code = ''
    for source in sources
      code += CoffeeScript.compile "\n#{fs.readFileSync source}"
    fs.writeFileSync javascript, code
    unless process.env.MINIFY is 'false'
      fs.writeFileSync javascript.replace(/\.js$/,'.min.js'), (
        uglify.gen_code uglify.ast_squeeze uglify.ast_mangle parser.parse code
      )
    cb() if typeof cb is 'function'
 
task 'watch', 'watch coffee/ for changes and build Chosen', ->
  console.log "Watching for changes in coffee/"
  for file in source_files()
    # Coffeescript wasn't scoping file correctly-
    # without this closure the file name displayed
    # is incorrect.
    ((file) ->
      fs.watchFile file, (curr, prev) ->
        if +curr.mtime isnt +prev.mtime
          console.log "Saw change in #{file}"
          invoke 'build'
    )(file)
