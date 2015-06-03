# static cache

fs = require 'fs'
rimraf = require 'rimraf'

{staticCacheDir} = require '../config/app'

makeCache = (cb) ->
  fs.mkdir staticCacheDir, (e) ->
    if e then throw new Error e else cb?()

fs.stat staticCacheDir, (err, stats) ->
  makeCache() if err

clear = (cb) ->
  rimraf staticCacheDir, (err) ->
    throw new Error err if err

    cb?()

module.exports = {staticCacheDir, clear}
