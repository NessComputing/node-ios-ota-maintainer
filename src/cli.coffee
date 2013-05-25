optimist = require 'optimist'
logger = require './logger'
config = require 'nconf'
require('pkginfo')(module, 'name')

###
The command line interface class.
###
class CLI
  constructor: () ->
    @argv = optimist
      .usage("Usage: " + exports.name)

      # configuration
      .alias('c', 'config')
      .describe('c', 'The configuration file to use')
      .default('c', "/etc/ios-ota-maintainer.json")

      # host
      .alias('H', 'host')
      .describe('H', 'The host to connect to')
      .default('H', '127.0.0.1')

      # port
      .alias('P', 'port')
      .describe('P', 'The port co connect to')
      .default('P', '3000')

      # logging
      .alias('l', 'loglevel')
      .describe('l', 'Set the log level (debug, info, warn, error, fatal)')
      .default('l', 'warn')

      # clean interval
      .alias('i', 'interval')
      .describe('i', 'Clean interval (in seconds)')
      .default('i', 43200)

      # max archives
      .alias('m', 'max-archives')
      .describe('m', 'Maximum number of archives for all branches/tags')
      .default('m', 10)

      # Run as a loop
      .alias('L', 'loop')
      .describe('L', 'Runs the application in an event loop')
      .default('L', false)

      # help
      .alias('h', 'help')
      .describe('h', 'Shows this message')
      .default('h', false)

      # append the argv from the cli
      .argv

    @configure()

    if config.get('help').toString() is "true"
      optimist.showHelp()
      process.exit(0)

  # Configures the nconf mapping where the priority matches the order
  configure: () =>
    @set_overrides()
    @set_argv()
    @set_env()
    @set_file()
    @set_defaults()

  # Sets up forceful override values
  set_overrides: () =>
    config.overrides({
      })

  # Sets up the configuration for cli arguments
  set_argv: () =>
    config.add('optimist_args', {type: 'literal', store: @argv})

  # Sets up the environment configuration
  set_env: () =>
    config.env({
      whitelist: []
      })

  # Sets up the file configuration
  set_file: () =>
    config.file({ file: config.get('c') })

  # Sets up the default configuration
  set_defaults: () =>
    config.defaults({
      })

module.exports = new CLI()
