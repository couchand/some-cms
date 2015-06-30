# static cache

fs = require 'fs'
rimraf = require 'rimraf'

debug = require './debug'
  .logger 'static-cache'

{staticCacheDir} = require '../config/app'

makeCache = (cb) ->
  fs.mkdir staticCacheDir, (e) ->
    if e then throw new Error e else cb?()

fs.stat staticCacheDir, (err, stats) ->
  makeCache() if err

clear = (cb) ->
  debug "clearing cache"

  rimraf staticCacheDir, (err) ->
    throw new Error err if err

    debug "cache clear"

    cb?()

openStaticCache = (cb) ->
  debug "opening cache"

  fs.stat staticCacheDir, (err, stats) ->
    if err
      debug "making cache dir"
      return fs.mkdir staticCacheDir, -> cb null, staticCacheDir

    else unless stats.isDirectory()
      return cb new Error "static cache is a regular file!!!"

    debug "cache ready"

    cb null, staticCacheDir

module.exports = {openStaticCache, clear}
