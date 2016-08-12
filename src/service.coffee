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

  packageJson = require "../package.json"
  service = Express()

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
  service.get '/api', (req,res)->
    repo.allTournaments()
      .then (tnames)->
        res.json
          version: require("../package.json").version
          tournaments: tnames


  service.get '/api/:tournamentName/leaderboard', (req, res)->
    repo.getScores(req.params.tournamentName)
      .then (scores)->
        res.status(200).json(scores)
                

  service.get '/api/:tournament/patterns/:base64String', (req, res)->
    repo.getPatternByBase64ForTournament(req.params.base64String, req.params.tournament)
      .then (pdoc)->
        if pdoc != undefined
          res.statusCode = 200
          res.json pdoc
        else
          pattern=
            name:''
            author:''
            mail:''
            elo:0
            pin:0
          res.status(404).json pattern
               

  service.post '/api/:tournament/patterns',jsonParser, (req, res)->
    pdoc = req.body.pdoc
    try
      repo.savePattern(pdoc,req.params.tournament).then ->
        res.statusCode = 200
        res.sendFile path.resolve __dirname, '..', 'static', 'index.html'
    catch e
      res.statusCode = 901
      res.sendFile path.resolve __dirname, '..', 'static', 'error.html'


  service.post '/api/:tournamentName/matches', jsonParser, (req, res)->
    mdoc = req.body.mdoc
    repo.saveMatch(mdoc, req.params.tournamentName)
      .then ->
        res.status(200).sendFile path.resolve __dirname, '..', 'static', 'index.html'


  service.get '/api/:tournamentName/matchmaker', (req, res)->
    repo.getPatternsForTournament(req.params.tournamentName).then (patterns)->
      pair = matchmaker.matchForElo(patterns)
      res.status(200).json pair


  service.get '/api/:tournamentName', (req, res)->
    repo.getPatternsAndMatchesForTournament(req.params.tournamentName).then (data)->
      res.status(200).json data

      
  service.get '/kiosk/leaderboard', (req, res) ->
    res.sendFile path.resolve __dirname, '..', 'static', 'leaderboard.html'


  service.get '/editor', (req, res)->
    res.sendFile path.resolve __dirname, '..', 'static', 'index.html'

  # for everything else, just return landingpage.html
  # so client-side routing works smoothly
  service.get '*',  (request, response)->
    response.sendFile path.resolve __dirname, '..', 'static', 'landingpage.html'

  service