# git setup

fs = require 'fs'
path = require 'path'

Git = require 'nodegit'

gitconfig = require '../config/git'

openOrClone = (cb) ->
  console.log 'hey'
  unless gitconfig.dir and gitconfig.repo
    cb new Error "Git config expects a directory and repository."

  gitdir = path.resolve gitconfig.dir

  fs.stat gitdir, (err, stats) ->
    if err
      console.log 'cloning'

      options =
        remoteCallbacks: credentials: (url, userName) ->
          Git.Cred.sshKeyFromAgent userName

      Git.Clone gitconfig.repo, gitdir, options
        .then (repository) ->
          console.log repository
          cb null, repository
        .catch (err) ->
          console.error err
          cb err
    else
      console.log 'opening'
      Git.Repository.open gitdir
        .then (repository) ->
          console.log repository
          cb null, repository
        .catch (err) ->
          console.error err
          cb err

REPO = no

openOrClone (err, repo) ->
  throw err if err

  REPO = repo

class Folder
  constructor: (@parent, @name, @dir) ->

  getPath: ->
    return '' unless @parent

    dir = @parent.getPath()
    return @name unless dir

    [dir, @name].join '/'

  getChild: (child) ->
    new Folder @, child, path.resolve @dir, child

  getLayout: (cb) ->
    layout = path.resolve @dir, '_layout.coffee'
    fs.stat layout, (err, stats) ->
      if err
        unless @parent
          cb null, (d) -> d
          return

        @parent.getLayout cb

      else
        cb null, require layout

  getChildren: (cb) ->
    me = @
    @walk (err) ->
      return cb err if err

      cb null, me.children

  getEntries: (cb) ->
    me = @
    @walk (err) ->
      return cb err if err

      cb null, me.entries

  walk: (cb) ->
    me = @

    fs.readdir @dir, (err, files) ->
      dirs = []
      plain = []
      left = files.length
      errors = []

      checkDone = ->
        left -= 1
        if left is 0
          if errors.length
            cb errors
          else
            me.children = (me.getChild d for d in dirs)
            me.entries = plain
            cb null

      files.forEach (file) ->
        absolute = path.resolve me.dir, file
        fs.stat absolute, (err, stats) ->
          if err
            error.push err

          else
            if stats.isDirectory()
              dirs.push file unless file[0] is '.'
            else if stats.isFile()
              plain.push file

          checkDone()


module.exports =
  getRoot: ->
    return unless REPO

    gitpath = REPO.path()
    root = path.resolve gitpath, '..'

    new Folder null, '', root
