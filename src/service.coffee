module.exports = (CGOL_HOME, settings)->
  Express = require "express"
  Repository = require "./repository"
  browserify = require "browserify-middleware"
  coffeeify = require "coffeeify"
  path = require "path"
  repo = Repository CGOL_HOME, settings
  bodyParser = require "body-parser"
  jsonParser = bodyParser.json()
  Matchmaker = require './matchmaker'
  matchmaker = Matchmaker()
  Validator = require('./validator')
  packageJson = require "../package.json"
  NoSuchPatternError = require "./no-such-pattern-error"
  service = Express()
  Pattern = require "./pattern"

  # client code
  browserify.settings 'extensions', ['.coffee']
  browserify.settings 'transform', [coffeeify]
  browserify.settings 'grep', /\.coffee$|\.js$/
  # debugging on android does not work if filesize is to big.
  #browserify.settings.development 'debug', false
  #browserify.settings.development 'minify', false
  entry = require.resolve "./client/index"
  shared = [
    'deepmerge'
    'baconjs'
    'd3-brush'
    'd3-selection'
    'd3-zoom'
    'document-ready'
    'qr-image'
    'react'
    'react-dom'
    'react-router'
    'kbpgp'
    'bluebird'
  ]
  service.get '/js/vendor.js', browserify shared,
    debug:settings.sourceMaps.vendor
    minify:settings.minify.vendor
  service.get '/js/client.js', browserify entry, 
    external:shared
    debug:settings.sourceMaps.client
    minify:settings.minify.client

  # static assets
  service.use Express.static('static')

  # service root
  # TODO: move api routes to a separate module?
  service.get '/api', (req,res, next)->
    repo
      .allTournaments()
      .then (tnames)->
        res.json
          version: require("../package.json").version
          tournaments: tnames
      .catch next


  service.get '/api/:tournamentName/leaderboard', (req, res, next)->
    repo
      .getScores(req.params.tournamentName)
      .then (scores)->
        res.status(200).json(scores)
      .catch next

  service.get '/api/:tournament/patterns/:base64String', (req, res, next)->
    data = req.params.base64String
    #FIXME: we should normalize here, too.
    #       disabled it, because it breaks tests and I am lazy.
    #
    #data = new Pattern req.params.base64String
    #  .minimize()
    #  .encodeSync()

    repo
      .getPatternByBase64ForTournament(data, req.params.tournament)
      .then (pdoc)->
        res.statusCode = 200
        res.json pdoc
      .catch next


  service.post '/api/:tournament/patterns',jsonParser, (req, res, next)->
    pdoc = req.body.pdoc
    allowOverride = req.body.allowOverride
    validate = Validator repo, req.params.tournament
    validate pdoc, allowOverride
      .then ->
        pdoc.base64String = new Pattern(pdoc.base64String).minimize().encodeSync()
        repo.savePattern(pdoc,req.params.tournament)
      .then ->
        res.json pdoc
      .catch next


  service.post '/api/:tournamentName/matches', jsonParser, (req, res,next)->
    mdoc = req.body.mdoc
    repo
      .saveMatch(mdoc, req.params.tournamentName)
      .then ->
        res.status(200).sendFile path.resolve __dirname, '..', 'static', 'index.html'
      .catch next

  service.get '/api/:tournamentName/matchmaker', (req, res, next)->
    repo
      .getPatternsForTournament(req.params.tournamentName)
      .then (patterns)->
        repo.getMatchesForTournament(req.params.tournamentName)
          .then (matches)->
            pair = matchmaker.matchForElo(patterns, matches)
            res.status(200).json pair
      .catch next

  service.get '/api/:tournamentName', (req, res, next)->
    repo
      .getPatternsAndMatchesForTournament(req.params.tournamentName)
      .then (data)->
        res.status(200).json data
      .catch next


  # FIXME: This won't do. Routing logic needs to be done client-side.
  service.get '/kiosk/leaderboard', (req, res) ->
    res.sendFile path.resolve __dirname, '..', 'static', 'leaderboard.html'


  service.get '/landingpage', (req, res)->
    res.sendFile path.resolve __dirname, '..', 'static', 'landingpage.html'

  # for everything else, just return index.html
  # so client-side routing works smoothly
  #
  #
  service.get '*',  (request, response)->
    response.sendFile path.resolve __dirname, '..', 'static', 'index.html'

  service.use (err,req,res,next)->
    if err
      msg = err.stack ? err.toString()
      if err instanceof require "./domain-error"
        res
          .status err.code
          .json
            message:msg
            type: err.name
      else
        console.error "unhandled error", msg
        res.status(500).json message: msg, type: null
    next()

  # this is used to quickly swap out all persisted / cached state of the CGOL service
  # Useful to speed up integration tests.
  service.switchWorkspace  = (path)->
    repo = Repository path, settings

  service
