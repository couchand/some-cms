# github webhook middleware

crypto = require 'crypto'

debug = require './debug'
  .logger 'github'

onPush = (repo, secret, cb) ->

  debug "Initializing webhook middleware"

  unless cb?
    cb = secret
    secret = no

  (req, res, next) ->

    debug "Webhook middleware hit"

    throwError = (err) ->
      debug "Error:", err
      return next err

    event = req.headers["x-github-event"]

    return throwError "GitHub hook missing X-GitHub-Event header!" unless event
    if event is "ping"
      debug "reponding to ping"
      return res.sendStatus 200

    unless event is "push"
      debug "#{event} is not a push event"
      return next()

    body = req.body.toString()

    return throwError "Body not parsed!" unless body

    if secret
      signature = req.headers["x-hub-signature"]

      hash = crypto.createHmac 'sha1', secret
        .update body
        .digest 'hex'

      if "sha1=#{hash}" isnt signature
        debug "Signature mismatch!"
        return next()

    payload = JSON.parse body
    repository = payload.repository

    return throwError "PushEvent missing repository!" unless repository
    unless repository.full_name is repo
      debug "Push is for a different repository: #{repository.full_name} not #{repo}"
      return next()

    debug "Push event received"

    cb req, res, next

module.exports = {onPush}
