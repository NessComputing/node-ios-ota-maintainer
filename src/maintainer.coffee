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
      @parallel_get_artifacts
      # @cleanup_leafs
    ])

  ###
  Parallel get_applications mapping.
  @param {Array} users The list of users to map applications to
  @param {Function} fn The callback function
  ###
  user_application_mapping: (users, fn) =>
    async.map users, @get_applications, fn

  ###
  Parallel get_branch and get_tags mapping.
  @param {Array} infolist The list of user/apps objects
  @param {Function} fn The callback function
  ###
  parallel_branch_and_tags: (infolist, fn) =>
    async.map infolist, (info, cb) =>
      async.map info.apps, (app, cb2) =>
        combined_info = { user: info.user, app: app }

        async.parallel
          branches: async.apply(@get_branches, combined_info)
          tags: async.apply(@get_tags, combined_info)
        , fn

  ###
  ###
  parallel_get_artifacts: (artifactinfo_list, fn) =>
    console.log artifactinfo_list

    async.parallel
      branches: async.map

  ###
  Cleanup leafs for archives and branches
  ###
  cleanup_leafs: (leafinfo, fn) =>
    console.log leafinfo
    fn(null, "cool")

  ###
  Sends a request to delete a given artifact.
  @param {Object} artifactinfo The information to describe a single artifact
  ###
  cleanup_artifact: (artifactinfo, fn) =>
    paths = [
      artifactinfo.user,
      artifactinfo.app,
      artifactinfo.type,
      artifactinfo.artifact
    ]
    request url: @app_url(paths), method: 'DELETE', json: true
    , (err, resp, body) => fn(err, body)

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
  get_archives: (artifactinfo, fn) =>
    @app_request artifactinfo.user
    , artifactinfo.app, artifactinfo.type, 'archives'
    , (err, body) =>
      fn err,
        user: artifactinfo.user
        app: artifactinfo.app
        type: artifactinfo.type
        archives: body["archives"]

module.exports = Maintainer
