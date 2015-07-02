# build the site

debug = require '../src/debug'
  .enable()

git = require '../src/git'
walker = require '../src/walker'

build = ->

  debug "Loading master"
  git.getMaster (err, master) ->
    if err
      throw err

    debug "Getting tree root"
    master
      .getCurrentTree()
      .then (tree) ->

        debug "Walking tree"
        walker.walk tree, (err) ->
          console.error err if err

module.exports = {build}
