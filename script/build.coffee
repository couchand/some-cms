# build the site

require 'debug'
  .enable 'some-cms:*'

git = require '../src/git'
walker = require '../src/walker'

git.getMaster (err, master) ->
  if err
    throw err

  master
    .getCurrentTree()
    .then (tree) ->

      walker.walk tree
