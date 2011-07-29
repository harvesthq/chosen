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

# Build Chosen. Requires `coffee` and `uglifyjs`.
#
task 'build', 'build Chosen from source', build = (cb) ->
  files = fs.readdirSync 'coffee'
  files = ('coffee/' + file for file in files when file.match(/\.coffee$/))
  run 'coffee', ['-c', '-o', 'chosen'].concat(files), ->
    cb() if typeof cb is 'function'
    unless process.env.MINIFY is 'false'
      for javascript in javascripts
        uglified = javascript.replace /\.js$/, '.min.js'
        run 'uglifyjs', ['-o', uglified, javascript], cb
 
