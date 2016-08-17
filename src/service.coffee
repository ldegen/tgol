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
  validator = require('./validator')(CGOL_HOME)
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
    debug:false
    minify:true
  service.get '/js/client.js', browserify entry, external:shared

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
    data = new Pattern req.params.base64String
      .minimize()
      .encodeSync()

    repo
      .getPatternByBase64ForTournament(data, req.params.tournament)
      .then(
        (pdoc)->
          res.statusCode = 200
          res.json pdoc
        (err)->
          if err instanceof NoSuchPatternError
            res.status(404)
            res.end()
          else throw err
      )
      .catch next


  service.post '/api/:tournament/patterns',jsonParser, (req, res, next)->
    pdoc = req.body.pdoc
    if validator.validatePattern(pdoc)
      validator.isMailAlreadyInUse(pdoc.mail, req.params.tournament)
      pattern = new Pattern(pdoc.base64String)
      pdoc.base64String = pattern.minimize().encodeSync()
      validator.isPatternAlreadyInUse(pdoc, req.params.tournament)
        .then (usage)->
          if not usage
            repo
              .savePattern(pdoc,req.params.tournament)
              .then ->
                res.statusCode = 200
                res.json pdoc
              .then null, (e)->
                res.statusCode = 901 #FIXME: what does 901 mean?
                res.sendFile path.resolve __dirname, '..', 'static', 'error.html'
              .catch next
          else
            res.status(401).sendFile path.resolve __dirname, '..', 'static', 'error.html'
        .catch (e)->
          res.status(402).sendFile path.resolve __dirname, '..', 'static', 'error.html'
    else
      res.status(403).sendFile path.resolve __dirname, '..', 'static', 'error.html'


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
      res.status(500).json msg
      console.error "unhandled error", msg
    next()

  # this is used to quickly swap out all persisted / cached state of the CGOL service
  # Useful to speed up integration tests.
  service.switchWorkspace  = (path)->
    repo = Repository path, settings

  service
