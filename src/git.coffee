# git setup

fs = require 'fs'
path = require 'path'

debug = require './debug'
  .logger 'git'

Git = require 'nodegit'

gitconfig = require '../config/git'

openOrClone = (cb) ->
  unless gitconfig.dir and gitconfig.repo
    msg = "Git config expects a directory and repository."
    debug msg
    cb new Error msg

  gitdir = path.resolve gitconfig.dir

  callbacks = credentials: (url, userName) ->
      Git.Cred.sshKeyFromAgent userName
  options =
    remoteCallbacks: callbacks

  fs.stat gitdir, (err, stats) ->
    if err
      debug "cloning into #{gitdir}"

      Git.Clone gitconfig.repo, gitdir, options
        .then (repository) ->
          cb null, repository
        .catch (err) ->
          debug "clone error: #{err}"
          cb err
    else
      debug "opening repository #{gitdir}"

      Git.Repository.open gitdir
        .then (repository) ->
          repository.fetchAll callbacks
            .then ->
              repository.mergeBranches "master", "origin/master"
            .then ->
              cb null, repository
        .catch (err) ->
          debug "open error: #{err}"
          cb err

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
  getRoot: (cb) ->
    openOrClone (err, repo) ->
      return cb err if err

      gitpath = repo.path()
      root = path.resolve gitpath, '..'

      cb null, new Folder null, '', root
