# static cache

{staticCacheDir} = require '../config/app'

fs.stat staticCacheDir, (err, stats) ->
  if err
    fs.mkdir staticCacheDir, (e) -> throw new Error e if e

module.exports = {staticCacheDir}
