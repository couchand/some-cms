# markdown compiler

fs = require 'fs'
path = require 'path'

debug = require './debug'
  .logger 'markdown'

mdit = require 'markdown-it'
mditContainer = require 'markdown-it-container'

{openStaticCache} = require './static-cache'

md = mdit typographer: yes
  .use mditContainer, 'frame'

module.exports =
  render: render = (source) ->
    md.render source

  renderFile: (dir, file, layout, cb) ->
    throwError = (err) ->
      debug err
      return cb err if cb
      throw err

    targetDir = ''

    openStaticCache (err, staticCacheDir) ->
      return throwError new Error err if err

      targetDir = path.resolve staticCacheDir, dir

      fs.stat targetDir, (err, stats) ->
        if err
          fs.mkdir targetDir, goAhead

        else unless stats.isDirectory()
          return throwError new Error "target directory is a regular file!!!"

        goAhead()

    goAhead = (err) ->
      targetFile = path.resolve targetDir, 'index.html'

      debug "getting blob for #{file.filename()}"

      file.getBlob().then (blob) ->
        debug "got blob #{file.filename()}"

        debug "rendering #{targetFile} from #{file.filename()}"

        data = blob.content()
        content = render data.toString()
        rendered = layout content, dir

        debug "writing file #{targetFile}"

        fs.writeFile targetFile, rendered, (err) ->
          return throwError new Error err if err

          cb? null
