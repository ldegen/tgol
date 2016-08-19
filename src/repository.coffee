module.exports = (CGOL_HOME, settings)->
  Promise = require "bluebird"
  path = require "path"
  fs = require "fs"
  split = require "split"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  readdir = Promise.promisify require "readdirp"
  merge = require "deepmerge"
  writeFile = Promise.promisify fs.writeFile
  appendFile = Promise.promisify fs.appendFile
  readFile = Promise.promisify fs.readFile
  stat = Promise.promisify fs.stat
  dump = require("js-yaml").dump
  loadYaml = require("./load-yaml")
  NoSuchPatternError = require "./no-such-pattern-error"
  cache = {}
  cachedTournament = (tournamentName)->
    if cache[tournamentName]?
      Promise.resolve cache[tournamentName]
    else
      loadTournament tournamentName
        .then (tournament)-> 
          cache[tournamentName]=tournament

  readJsonLines = (file)->
    stat file
      .catch (e)->
        null
      .then (s)->
        if not s?.isFile()
          []
        else
          new Promise (resolve, reject)->
            jsonLines=[]
            fs.createReadStream(file)
              .pipe(split(JSON.parse, null, trailing:false))
              .on 'data', (obj) -> jsonLines.push obj
              .on 'error', (err) -> reject err
              .on 'end' , -> resolve jsonLines

  replaceCachedPattern = (tournament, pattern)->
    tournament.patterns[pattern.mail]=pattern

  addCachedMatch = (tournament, match)->
    tournament.matches.push match

  savePattern = (pdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    pdir = path.join tdir, 'patterns'
    pfile = path.join pdir, pdoc.mail+".yaml"
    pdoc = merge pdoc, {}
    mkdir pdir
      .then -> writeFile pfile, dump pdoc
      .then -> cachedTournament tournamentName
      .then (tournament)->
        replaceCachedPattern tournament, pdoc


  saveMatch = (mdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    mfile = path.join tdir, 'matches.log'
    appendFile mfile, (JSON.stringify mdoc)+"\n"
      .then -> cachedTournament tournamentName
      .then(
        (tournament)-> 
          addCachedMatch tournament, mdoc
        (err)-> 
          console.log "error", err.stack
          throw err
      ) 


  saveTournament = (tdoc)->
    tdir = path.join CGOL_HOME,tdoc.name
    metafile = path.join tdir, 'meta.yaml'
    matchdir = path.join tdir, 'matches'
    patterndir = path.join tdir, 'patterns'
    cachedTournament tdoc.name # make sure cache is initialized to avoid adding the match twice
      .then -> mkdir tdir
      .then -> mkdir matchdir
      .then -> mkdir patterndir
      .then -> 
        writeFile metafile, dump
          name:tdoc.name
          pin: tdoc.pin
      .then -> Promise.each tdoc.patterns, (pattern)-> savePattern pattern,tdoc.name
      .then -> Promise.each tdoc.matches, (match)-> saveMatch match,tdoc.name

  allTournaments = ->
    readdir root: CGOL_HOME, depth: 0,entryType: 'directories'
      .then (entries)->
        entries.directories
          .map (entry)->"/"+entry.name
          .sort()


  getPatternsForTournament = (tournamentName)->
    cachedTournament(tournamentName)
      .then (tournament)->
        pattern for _,pattern of tournament.patterns


  getPatternByEmailForTournament = (email, tournamentName)->
    cachedTournament(tournamentName)
      .then (tournament)->
        pattern = tournament.patterns[email]
        throw new NoSuchPatternError if not pattern?
        pattern

  getPatternByBase64ForTournament = (base64String, tournamentName)->
    getPatternsForTournament(tournamentName)
      .then (patterns)->
        return pattern for pattern in patterns when pattern.base64String == base64String
        throw new NoSuchPatternError()


  getPatternsAndMatchesForTournament = (tournamentName)->
    cachedTournament tournamentName
      .then (tournament)->
        patterns: (pattern for _,pattern of tournament.patterns)
        matches:  tournament.matches


  getMatchesForTournament = (tournamentName)->
    cachedTournament tournamentName
      .then (tournament)-> tournament.matches

  loadTournament = (tournamentName) ->
    pdir = path.join CGOL_HOME, tournamentName, 'patterns'
    mfile = path.join CGOL_HOME, tournamentName, 'matches.log'
    data=
      patterns:{}
      matches:[]
    mkdir pdir
      .then -> readdir root:pdir, depth:0, entryType:'files'
      .then (entryStreamPatterns)->
        patterns = (entryStreamPatterns?.files ? []).map (entryPattern)-> loadYaml entryPattern.fullPath
        data.patterns[pattern.mail]=pattern for pattern in patterns
      .then -> 
        readJsonLines mfile
      .then (matches)->
        data.matches = matches
      .then -> 
        data


  getScores = (tournamentName)->
    Promise.resolve [
      name: 'Roman'
      games: 3
      score: 234
      mail: 'romanabendroth@t-online.de'
    ,
      name: 'Tester1'
      games: 4
      score: 456
      mail: 'service-spec@tarent.de'
    ]
        


  allTournaments: allTournaments
  saveTournament: saveTournament
  savePattern: savePattern
  saveMatch:saveMatch
  getPatternsForTournament:getPatternsForTournament
  getPatternByBase64ForTournament:getPatternByBase64ForTournament
  getPatternByEmailForTournament:getPatternByEmailForTournament
  getPatternsAndMatchesForTournament:getPatternsAndMatchesForTournament
  getMatchesForTournament:getMatchesForTournament
  getScores:getScores
