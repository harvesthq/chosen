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
    'coffee/lib/select-parser.coffee'
    'coffee/lib/abstract-chosen.coffee'
    'coffee/chosen.jquery.coffee'
  ]
  'chosen/chosen.proto.js': [
    'coffee/lib/select-parser.coffee'
    'coffee/lib/abstract-chosen.coffee'
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

# Get the version number
#
version = ->
  "#{fs.readFileSync('VERSION')}".replace /[^0-9a-zA-Z.]*/gm, ''

version_tag = ->
  "v#{version()}"

# Write chosen files with a header
#
write_chosen_javascript = (filename, body, trailing='') ->
  fs.writeFileSync filename, """
// Chosen, a Select Box Enhancer for jQuery and Protoype
// by Patrick Filler for Harvest, http://getharvest.com
//
// Version #{version()}
// Full source at https://github.com/harvesthq/chosen
// Copyright (c) 2011 Harvest http://getharvest.com
//
// Changelog:
// [2012-08-02] - Add option to specify a custom value on the fly [Anderson Grüdtner Martins]

// MIT License, https://github.com/harvesthq/chosen/blob/master/LICENSE.md
// This file is generated by `cake build`, do not edit it by hand.
#{body}#{trailing}
"""
  console.log "Wrote #{filename}"

# Build Chosen.
#
task 'build', 'build Chosen from source', build = (cb) ->
  file_name = null; file_contents = null
  try
    for javascript, sources of javascripts
      code = ''
      for source in sources
        file_name = source
        file_contents = "#{fs.readFileSync source}"
        code += CoffeeScript.compile file_contents
      write_chosen_javascript javascript, code
      unless process.env.MINIFY is 'false'
        write_chosen_javascript javascript.replace(/\.js$/,'.min.js'), (
          uglify.gen_code uglify.ast_squeeze uglify.ast_mangle parser.parse code
        ), ';'
    package_npm () ->
      package_jquery () ->
        cb() if typeof cb is 'function'
  catch e
    print_error e, file_name, file_contents

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

task 'package_npm', 'generate the package.json file for npm', package_npm = (cb) ->
  try
    package_file = 'package.json'
    package_obj = JSON.parse("#{fs.readFileSync package_file}")
    package_obj['version'] = version()
    fs.writeFileSync package_file, JSON.stringify(package_obj, null, 2)
    console.log "Wrote #{package_file}"
    cb() if typeof cb is 'function'
  catch e
    print_error e, package_file

task 'package_jquery', 'generate the chosen.jquery.json file for the jQuery plugin website', package_jquery = (cb) ->
  try
    package_file = 'chosen.jquery.json'
    package_obj = JSON.parse("#{fs.readFileSync package_file}")
    package_obj['version'] = version()
    fs.writeFileSync package_file, JSON.stringify(package_obj, null, 2)
    console.log "Wrote #{package_file}"
    cb() if typeof cb is 'function'
  catch e
    print_error e, package_file

run = (cmd, args, cb, err_cb) ->
  exec "#{cmd} #{args.join(' ')}", (err, stdout, stderr) ->
    if err isnt null
      console.error stderr
      if typeof err_cb is 'function'
        err_cb()
      else
        throw "Failed command execution (#{err})."
    else
      cb(stdout) if typeof cb is 'function'

with_clean_repo = (cb) ->
  run 'git', ['diff', '--exit-code'], cb, ->
    throw 'There are files that need to be committed first.'

without_existing_tag = (cb) ->
  run 'git', ['tag'], (stdout) ->
    if stdout.split("\n").indexOf( version_tag() ) >= 0
      throw 'This tag has already been committed to the repo.'
    else
      cb()

tag_release = (cb, cb_err) ->
  run 'git', ['tag', '-a', '-m', "\"Version #{version()}\"", version_tag()], cb, cb_err

untag_release = (e) ->
  console.log "Failure to tag caught: #{e}"
  console.log "Removing tag #{version_tag()}"
  run 'git', ['tag', '-d', version_tag()]

push_repo = (args=[], cb, cb_err) ->
  run 'git', ['push'].concat(args), cb, cb_err

print_error = (error, file_name, file_contents) ->
  line = error.message.match /line ([0-9]+):/
  if line && line[1] && line = parseInt(line[1])
    contents_lines = file_contents.split "\n"
    first = if line-4 < 0 then 0 else line-4
    last  = if line+3 > contents_lines.size then contents_lines.size else line+3
    console.log "Error compiling #{file_name}. \"#{error.message}\"\n"
    index = 0
    for line in contents_lines[first...last]
      index++
      line_number = first + 1 + index
      console.log "#{(' ' for [0..(3-(line_number.toString().length))]).join('')} #{line}"
  else
    console.log """
Error compiling #{file_name}:

  #{error.message}

"""



task 'release', 'build, tag the current release, and push', ->
  console.log "Trying to tag #{version_tag()}..."
  with_clean_repo ->
    without_existing_tag ->
      build ->
        tag_release ->
          push_repo [], ->
            push_repo ['--tags'], ->
              console.log "Successfully tagged #{version_tag()}: https://github.com/harvesthq/chosen/tree/#{version_tag()}"

            , untag_release ('push repo with tags')
          , untag_release ('push repo')
        , untag_release ('tag release')
