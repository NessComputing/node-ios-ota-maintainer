config = require 'nconf'
logger = require './logger'
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
      @parallel_clean_archives
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
    async.map infolist, (info, mergeuser) =>
      async.map info.apps, (app, mergeapp) =>
        combined_info = { user: info.user, app: app }

        async.parallel
          branches: async.apply(@get_branches, combined_info)
          tags: async.apply(@get_tags, combined_info)
        , (err, pdata) =>
          branches = (user: pdata.branches.user
            , app: pdata.branches.app
            , artifact: art
            , type: pdata.branches.type \
            for art in pdata.branches.artifacts)

          tags = (user: pdata.tags.user
            , app: pdata.tags.app
            , artifact: art
            , type: pdata.tags.type \
            for art in pdata.tags.artifacts)

          mergeapp(err, branches.concat(tags))

      , (err, app_list) =>
        fn(err, [].concat.apply([], app_list))

  ###
  Parallel cleanup archives that are out of the max-archive bounds.
  @param {Array} artifactinfo_list The list of artifacts to iterate and trim
  @param {Function} fn The callback function
  ###
  parallel_clean_archives: (artifactinfo_list, fn) =>
    async.each artifactinfo_list, (artifactinfo, finished_set) =>
      @get_archives artifactinfo, (err, info) =>
        archives = (parseInt(a) for a in info.archives).sort().reverse()
        archives.splice(0, config.get('max-archives'))

        async.each archives, (archive, finished_archive) =>
          archiveinfo =
            user: info.user
            app: info.app
            type: info.type
            artifact: info.artifact
            archive: archive

          @cleanup_archive archiveinfo, (err, body) =>
            logger.info body
            finished_archive(null, null)

      , finished_set
    , fn

  ###
  Sends a request to delete a given archive.
  @param {Object} archiveinfo The information to describe a single artifact
  ###
  cleanup_archive: (archiveinfo, fn) =>
    paths = [
      archiveinfo.user,
      archiveinfo.app,
      archiveinfo.type,
      archiveinfo.artifact,
      'archives',
      archiveinfo.archive
    ]
    request url: @app_url(paths...), method: 'DELETE', json: true
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
    , artifactinfo.app, artifactinfo.type, artifactinfo.artifact, 'archives'
    , (err, body) =>
      fn err,
        user: artifactinfo.user
        app: artifactinfo.app
        type: artifactinfo.type
        artifact: artifactinfo.artifact
        archives: body["archives"]

module.exports = Maintainer
