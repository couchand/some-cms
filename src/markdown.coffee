# markdown compiler

fs = require 'fs'
path = require 'path'

mdit = require 'markdown-it'

{staticCacheDir} = require './static-cache'

md = mdit
  typographer: yes

module.exports =
  render: render = (source) ->
    md.render source

  renderFile: (dir, file, cb) ->
    throwError = (err) ->
      return cb err if cb
      throw err

    targetDir = path.resolve staticCacheDir, dir

    fs.stat targetDir, (err, stats) ->
      if err
        fs.mkdir targetDir, goAhead

      else unless stats.isDirectory()
        return throwError new Error "target directory is a regular file!!!"

      goAhead()

    goAhead = (err) ->
      return throwError new Error err if err

      targetFile = path.resolve targetDir, 'index.html'

      console.log "rendering #{targetFile} from #{file}"

      fs.readFile file, (err, data) ->
        return throwError new Error err if err

        rendered = render data.toString()

        fs.writeFile targetFile, rendered, (err) ->
          return throwError new Error err if err

          cb? null
