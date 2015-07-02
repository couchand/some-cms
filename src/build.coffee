# build the site

{branch} = require '../config/git'
branch ?= "master"

debug = require './debug'
  .logger 'build'

git = require './git'
walker = require './walker'

build = ->

  debug "Loading #{branch}"
  git.getCurrent (err, current) ->
    if err
      throw err

    debug "Getting tree root"
    current
      .getCurrentTree()
      .then (tree) ->

        debug "Walking tree"
        walker.walk tree, (err) ->
          console.error err if err

module.exports = {build}
