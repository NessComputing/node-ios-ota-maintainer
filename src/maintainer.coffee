config = require 'nconf'
request = require 'request'
path = require 'path'
url = require 'url'
async = require 'async'

###
The ios-ota maintenance class.
###
class Maintainer
  constructor: () ->
    if config.get('loop').toString() is "true"
      setInterval () =>
        @cleanup()
      , parseInt(config.get('interval'))
    else
      @cleanup()

  ###
  Runs the cleanup job.
  @param {Function} fn The callback function
  ###
  cleanup: () =>
    async.waterfall([
      @get_users,
      @user_application_mapping,
      @parallel_branch_and_tags,
      @cleanup_leafs
    ])

  ###
  Usermapping
  ###
  user_application_mapping: (users, fn) =>
    async.map users, @get_applications
    , (err, usermapping) =>
      console.log usermapping
      fn(err, usermapping)

  ###
  ###
  parallel_branch_and_tags: (info, fn) =>
    fn(null, "awesome")

  ###
  Cleanup leafs for archives and branches
  ###
  cleanup_leafs: (info, fn) =>
    fn(null, "cool")

  ###
  Helper function for the base app url.
  @param {String} paths The argument list of paths to append
  @return {String} The generated url string
  ###
  app_url: (paths...) =>
    base = "http://#{config.get('host')}:#{config.get('port')}/"
    newpaths = (p.toString() for p in paths)
    joined = path.join(newpaths...)
    url.resolve(base, joined)

  ###
  Request helper for general ios-ota requests
  @param {String} paths The argument list of paths to append
  @param {Function} fn The callback function
  ###
  app_request: (paths..., fn) =>
    request url: @app_url(paths...), json: true
    , (err, resp, body) => fn(err, body)

  ###
  Gets the list of users.
  @param {Function} fn The callback function
  ###
  get_users: (fn) =>
    @app_request 'users', (err, body) =>
      fn(err, body["users"])

  ###
  Gets the list of applications for a given user.
  @param {String} user The user to request applications for
  @param {Function} fn The callback function
  ###
  get_applications: (user, fn) =>
    @app_request user, (err, body) =>
      fn err,
        user: user,
        apps: body["applications"]

  ###
  Gets all of the branches for a given application.
  @param {Object} userapp The user and application combined object
  @param {Function} fn The callback function
  ###
  get_branches: (userapp, fn) =>
    @app_request userapp.user, userapp.app
    , (err, body) =>
      fn err,
        user: userapp.user
        app: userapp.app
        type: 'branches'
        artifacts: body["branches"]

  ###
  Gets all of the tags for a given application.
  @param {Object} userapp The user and application combined object
  @param {Function} fn The callback function
  ###
  get_tags: (userapp, fn) =>
    @app_request userapp.user, userapp.app
    , (err, body) =>
      fn err, 
        user: userapp.user
        app: userapp.app
        type: 'tags'
        artifacts: body["tags"]

  ###
  Gets all of the archives for a given branch/tag.
  @param {Object} artifactinfo The user, app, type, and artifacts
  @param {Function} fn The callback function
  ###
  get_archives: (artifactinfo fn) =>
    @app_request artifactinfo.user
    , artifactinfo.app, artifactinfo.type, 'archives'
    , (err, body) =>
      fn err,
        user: artifactinfo.user
        app: artifactinfo.app
        type: artifactinfo.type
        archives: body["archives"]

module.exports = Maintainer
