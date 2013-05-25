config = require 'nconf'
request = require 'request'
path = require 'path'
url = require 'url'

###
The ios-ota maintenance class.
###
class Maintainer
  constructor: () ->
    if config.get('loop').toString() is "true"
      setInterval () =>
        @cleanup
      , parseInt(config.get('interval'))
    else
      @cleanup()

  ###
  Runs the cleanup job.
  ###
  cleanup: () =>
    console.log @app_url('users', 'lol')

  ###
  Helper function for the base app url.
  ###
  app_url: (paths...) =>
    base = "http://#{config.get('host')}:#{config.get('port')}/"
    newpaths = (p.toString() for p in paths)
    joined = path.join(newpaths...)
    url.resolve(base, joined)

  ###
  Gets the list of users.
  ###
  get_users: () =>
    request(@app_url('users'))

  ###
  Gets the list of applications for a given user.
  @param {String} user The user to request applications for
  ###
  get_applications: (user) =>
    @app_url(user, user)

  ###
  Gets all of the branches for a given application.
  @param {String} user The user to query against
  @param {String} application The application to request branches for
  ###
  get_branches: (user, application) =>

  ###
  Gets all of the tags for a given application.
  @param {String} user The user to query against
  @param {String} application The application to request branches for
  ###
  get_tags: (user, application) =>

  ###
  Gets all of the archives for a given branch/tag.
  @param {String} user The user to query against
  @param {String} application The application to query against
  @param {String} type Whether you want branch or tag archives
  ###
  get_archives: (user, application, type) =>

module.exports = Maintainer
