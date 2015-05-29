# copy util

path = require 'path'

{staticCacheDir} = require './static-cache'

module.exports =
  copyFile: (from, to, file, cb) ->
    targetDir = path.resolve staticCacheDir, to

    fs.stat targetDir, (err, stats) ->
      if err
        fs.mkdir targetDir, goAhead

      else unless stats.isDirectory()
        return throwError new Error "target directory is a regular file!!!"

      goAhead()

    goAhead = (err) ->
      targetFile = path.resolve targetDir, file

      console.log "copying #{targetFile} from #{from}"

      source = fs.createReadStream from
      target = fs.createWriteStream targetFile

      source.on 'end', ->
        cb? null

      source.on 'error', (err) ->
        return cb err if cb
        throw new Error err

      source.pipe target
