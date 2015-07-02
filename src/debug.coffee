# debug info

PREFIX = 'some-cms'
DELIMITER = ':'

debug = require 'debug'

module.exports = debug PREFIX

module.exports.logger = (name) ->
  debug PREFIX + if name then  DELIMITER + name else ''

module.exports.enable = ->
  debug.enable PREFIX + DELIMITER + '*'
  module.exports
