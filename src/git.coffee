# git setup

fs = require 'fs'
path = require 'path'

coffee = require 'coffee-script'

debug = require './debug'
  .logger 'git'

Git = require 'nodegit'

gitconfig = require '../config/git'

gitdir = path.resolve gitconfig.dir

{openLayoutCache, clear} = require './layout-cache'

layoutCacheDir = null
# clear once on application start
clear ->
  openLayoutCache (err, cacheDir) ->
    throw err if err

    layoutCacheDir = cacheDir

openOrClone = (cb) ->
  unless gitconfig.dir and gitconfig.repo
    msg = "Git config expects a directory and repository."
    debug msg
    cb new Error msg

  branch = gitconfig.branch or "master"

  callbacks = credentials: (url, userName) ->
      Git.Cred.sshKeyFromAgent userName
  options =
    remoteCallbacks: callbacks
    checkoutBranch: branch
    # TODO: restore when bare actually works
    #bare: 1 # c true

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
              branch = gitconfig.branch or "master"
              repository.mergeBranches branch, "origin/#{branch}"
            .then ->
              cb null, repository
        .catch (err) ->
          debug "open error: #{err}"
          cb err

# git branch is our draft
class Draft
  constructor: (@repo, @name) ->

  getCurrentVersion: ->
    @repo.getBranchCommit @name

  getCurrentTree: ->
    repo = @repo
    @getCurrentVersion()
      .then (commit) ->
        repo.getTree commit.treeId()
      .then (tree) ->
        new Tree tree

# git tree is our tree
class Tree
  constructor: (@tree, @parent) ->

  getDir: ->
    path.resolve gitdir, @getPath()

  getPath: ->
    @tree.path()

  getChild: (child, cb) ->
    entry = @tree.entryByName child
    @getChildByEntry entry
      .then (child) -> cb null, child
      .catch cb

  getChildByEntry: (entry) ->
    unless entry.isTree()
      throw new Error "not a tree!"

    me = @

    entry
      .getTree()
      .then (tree) ->
        new Tree tree, me

  getLayout: (cb) ->
    unless @getPath
      console.log @toString()
      return

    debug "getting layout for /#{@getPath()}"

    me = @
    base = @parent

    finish = (entry) ->
      debug "entry found at path /#{me.getPath()}/#{entry.filename()}"

      entry.getBlob().then (blob) ->
        debug "layout loaded, #{blob.rawsize()} bytes"

        cachedLayout = path.resolve layoutCacheDir, me.getPath(), '_layout.js'

        fs.stat cachedLayout, (err, stats) ->
          if err
            fs.writeFileSync cachedLayout, coffee.compile blob.content().toString()

          layout = require cachedLayout
          cb null, layout

    @getEntries (err, entries) ->
      debug "inspecting #{entries.length} entries"

      for entry in entries when '_layout.coffee' is entry.filename()
        return finish entry

      debug "entry not found at path /#{me.getPath()}"

      if base
        base.getLayout cb
      else
        cb null, String

  getEntries: (cb) ->
    @walk()
    cb null, @entries

  getChildren: (cb) ->
    @walk()
    left = @fetchChildren.length
    errors = []
    children = []

    me = @
    addTo = (list) -> (el) ->
      list.push el
    checkDone = ->
      left -= 1
      if left is 0
        if errors.length
          cb errors
        else
          me.children = children
          cb null, children

    for getChild in @fetchChildren
      getChild
        .then addTo children
        .catch addTo errors
        .done checkDone

  walk: ->
    dirs = []
    plain = []

    for entry in @tree.entries()
      if entry.isDirectory()
        dirs.push entry
      else if entry.isFile()
        plain.push entry

    @fetchChildren = (@getChildByEntry dir for dir in dirs)
    @entries = plain

MASTER = 'refs/heads/master'

module.exports =
  getCurrent: (cb) ->
    openOrClone (err, repo) ->
      return cb err if err

      repo
        .getCurrentBranch()
        .then (branch) ->
          cb null, new Draft repo, branch.name()
        .catch cb
###
  getMaster: (cb) ->
    openOrClone (err, repo) ->
      return cb err if err

      repo
        .getReferences()
        .then (refs) ->
          for ref in refs when ref.isBranch() and ref.name() is MASTER
            new Draft repo, ref.name()
        .then (drafts) ->
          if drafts.length isnt 1
            cb new Error "Master branch not found!"
          else
            cb null, drafts[0]

        .catch cb

  getDrafts: (cb) ->
    openOrClone (err, repo) ->
      return cb err if err

      repo
        .getReferences()
        .then (refs) ->
          for ref in refs when ref.isBranch() and ref.name() isnt MASTER
            new Draft repo, ref.name()
        .then (drafts) ->
          cb null, drafts

        .catch cb
###
