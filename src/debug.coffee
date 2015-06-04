# debug info

debug = require 'debug'

module.exports = debug 'some-cms'

module.exports.logger = (name) ->
  debug "some-cms#{if name then ":#{name}" else ''}"
