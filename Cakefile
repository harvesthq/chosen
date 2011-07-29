fs               = require 'fs'
path             = require 'path'
{spawn, exec}    = require 'child_process'

javascripts = [
  'chosen/chosen.jquery.js', 'chosen/chosen.proto.js'
]

# Run a command
#
run = (cmd, args, cb) ->
  proc =         spawn cmd, args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

coffescript_files = ->
  'coffee/' + file for file in (fs.readdirSync 'coffee') when file.match(/\.coffee$/)

# Build Chosen. Requires `coffee` and `uglifyjs`.
#
task 'build', 'build Chosen from source', build = (cb) ->
  run 'coffee', ['-c', '-o', 'chosen'].concat(coffescript_files()), ->
    cb() if typeof cb is 'function'
    unless process.env.MINIFY is 'false'
      for javascript in javascripts
        uglified = javascript.replace /\.js$/, '.min.js'
        run 'uglifyjs', ['-o', uglified, javascript], cb
 
task 'watch', 'watch coffee/ for changes and build Chosen', ->
  console.log "Watching for changes in coffee/"
  for file in coffescript_files()
    fs.watchFile file, (curr, prev) ->
      if +curr.mtime isnt +prev.mtime
        console.log "Saw change in #{file}"
        invoke 'build'

