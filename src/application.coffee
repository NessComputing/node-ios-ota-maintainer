logger = require './logger'
cli = require './cli'
config = require 'nconf'
Maintainer = require './maintainer'

###
The base application class.
###
class Application
  constructor: ->
    process.on 'SIGINT', () =>
        logger.info 'Got SIGINT. Exiting...'
        process.exit(0)

    @maintainer = new Maintainer()

  ###
  Aborts the application with a message.
  
  @param {String} (msg) The message to abort the application with
  ###
  abort: (msg) =>
    logger.info(''.concat('Aborting Application: ', str, '...'))
    process.exit(1)

module.exports = Application
