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

copy = (tree, entry, showEntry) ->
  sourceFile = path.resolve tree.getDir(), entry.filename()
  target = tree.getPath()

  debug "copying #{sourceFile} to /#{target}#{if showEntry then "/#{entry}" else ''}"

  copyFile sourceFile, target, entry

walk = (tree, cb) ->
  clear (error) ->
    return cb error if error

    nextStep = -> doWalk tree, cb or ->
    setTimeout nextStep, 10

layout = (d) -> d

doWalk = (tree, cb) ->
  error = no

  tree.getEntries (err, entries) ->
    return error = err if err

    selectedEntry = no

    for pattern in patterns when not selectedEntry
      for entry in entries when pattern.test entry.filename()
        selectedEntry = entry
        break

    return error = 404 unless selectedEntry

    match = extension.exec selectedEntry.filename()

    return error = 500 unless match

    debug "found file to serve #{selectedEntry.filename()} in dir /#{tree.getPath()}"

    switch match[1]
      when 'txt', 'html'
        copy tree, selectedEntry

      when 'markdown', 'md'
        sourceFile = path.resolve tree.getDir(), selectedEntry.filename()
        target = tree.getPath()

#        tree.getLayout (err, layout) ->
#          if err
#            return error = err
#          else
        debug "compiling #{sourceFile} to /#{target}"
        renderFile target, selectedEntry, layout

    return if error

    for asset in assets
      for assetFile in entries when asset.test assetFile.filename()
        copy tree, assetFile, yes

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
      doWalk child, checkDone

module.exports = {walk}
