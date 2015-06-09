# copy util

fs = require 'fs'
path = require 'path'

debug = require './debug'
  .logger 'cp'

{openStaticCache} = require './static-cache'

module.exports =
  copyFile: (from, to, file, cb) ->
    throwError = (err) ->
      debug err
      return cb err if cb
      throw err

    targetDir = ''

    openStaticCache (err, staticCacheDir) ->
      return throwError new Error err if err

      targetDir = path.resolve staticCacheDir, to

      fs.stat targetDir, (err, stats) ->
        if err
          return fs.mkdir targetDir, goAhead

        else unless stats.isDirectory()
          return throwError new Error "target directory is a regular file!!!"

        goAhead()

    goAhead = (err) ->
      return throwError new Error err if err

      targetFile = path.resolve targetDir, file

      debug "copying #{targetFile} from #{from}"

      source = fs.createReadStream from
      target = fs.createWriteStream targetFile

      source.on 'end', -> cb? null
      source.on 'error', throwError

      source.pipe target
