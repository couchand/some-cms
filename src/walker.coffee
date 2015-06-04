# walker, texas ranger

# walks the tree and ensures everything is up-to-date

# tree should have a name and three methods:
# * tree.getEntries(cb)
#   get entries at this level
# * tree.getChildren(cb)
#   get child trees at next level
# * tree.getPath()
#   gets the path to the current tree from the root

path = require 'path'

debug = require './debug'
  .logger 'walker'

{extension, patterns, assets} = require './search'
{renderFile} = require './markdown'
{copyFile} = require './cp'
{clear} = require './static-cache'

walk = (tree, cb) ->
  clear (error) ->
    return cb error if error

    doWalk tree, cb or ->

doWalk = (tree, cb) ->
  error = no

  tree.getEntries (err, entries) ->
    return error = err if err

    selectedEntry = no

    for pattern in patterns when not selectedEntry
      for entry in entries when pattern.test entry
        selectedEntry = entry
        break

    return error = 404 unless selectedEntry

    match = extension.exec selectedEntry

    return error = 500 unless match

    debug "found file to serve #{match[0]} in dir #{tree.getPath()}"

    switch match[1]
      when 'txt', 'html'
        sourceFile = path.resolve tree.dir, selectedEntry
        target = tree.getPath()

        debug "copying #{sourceFile} to /#{target}"

        copyFile sourceFile, target, selectedEntry

      when 'markdown', 'md'
        sourceFile = path.resolve tree.dir, selectedEntry
        target = tree.getPath()

        debug "compiling #{sourceFile} to /#{target}"

        tree.getLayout (err, layout) ->
          if err
            return error = err
          else
            renderFile target, sourceFile, layout

    return if error

    for asset in assets
      for entry in entries when asset.test entry
        sourceFile = path.resolve tree.dir, entry
        target = tree.getPath()

        debug "copying asset #{sourceFile} to #{target}/#{entry}"

        copyFile sourceFile, target, entry

  return cb error if error

  tree.getChildren (err, children) ->
    return cb err if err

    left = children.length
    checkDone = (err) ->
      if err
        error = [] unless error
        error.push err

      if left -= 1 is 0
        if error then cb error else cb null

    for child in children
      walk child, checkDone

module.exports = {walk}
