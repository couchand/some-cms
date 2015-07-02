# app server

GITHUB_REPO_RE = /^git@github.com:([^\/]+\/[^\/]+).git$/

bodyParser = require 'body-parser'

{serverPort} = require '../config/app'
{repo, webhookSecret} = require '../config/git'

debug = require './debug'
  .enable()
  .logger 'server'

express = require 'express'

github = require './github'
{build} = require './build'

debug "Creating server"
app = express()

if GITHUB_REPO_RE.test repo
  match = GITHUB_REPO_RE.exec repo
  repoName = match[1]

  parser = bodyParser.text type: '*/json'

  debug "Adding GitHub webhook middleware for repo #{repoName}"
  app.use '/github/hook', parser, github.onPush repoName, webhookSecret, (req, res) ->
    debug "Got push to repository"

    res.sendStatus 200

    build()

debug "Listening on localhost:#{serverPort}"
app.listen serverPort

debug "Server up."
