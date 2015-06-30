# layout cache

fs = require 'fs'
rimraf = require 'rimraf'

debug = require './debug'
  .logger 'layout-cache'

{layoutCacheDir} = require '../config/app'

makeCache = (cb) ->
  fs.mkdir layoutCacheDir, (e) ->
    if e then throw new Error e else cb?()

fs.stat layoutCacheDir, (err, stats) ->
  makeCache() if err

clear = (cb) ->
  debug "clearing cache"

  rimraf layoutCacheDir, (err) ->
    throw new Error err if err

    debug "cache clear"

    cb?()

openLayoutCache = (cb) ->
  debug "opening cache"

  fs.stat layoutCacheDir, (err, stats) ->
    if err
      debug "making cache dir"
      return fs.mkdir layoutCacheDir, -> cb null, layoutCacheDir

    else unless stats.isDirectory()
      return cb new Error "layout cache is a regular file!!!"

    debug "cache ready"

    cb null, layoutCacheDir

module.exports = {openLayoutCache, clear}
