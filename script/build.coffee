# build the site

require 'debug'
  .enable 'some-cms:*'

git = require '../src/git'
walker = require '../src/walker'

git.getRoot (err, root) ->
  if err
    throw err

  walker.walk root
