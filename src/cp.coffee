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

      targetFile = path.resolve targetDir, file.filename()

      debug "copying #{targetFile} from #{from}"

      debug "getting blob"
      file.getBlob().then (blob) ->
        mode = blob.filemode()

        debug "opening #{targetFile} for writing with mode #{mode}"
        target = fs.open targetFile, 'w', mode, (err, fd) ->
          return throwError err if err

          debug "opened fd #{fd}"

          size = blob.rawsize()
          content = blob.content()
          debug "writing blob content, #{size} bytes"
          fs.write fd, content, 0, size, 0, (err, written) ->
            return throwError err if err

            debug "blob written, #{written} bytes"
            cb? null
