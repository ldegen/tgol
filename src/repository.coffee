module.exports = (CGOL_HOME, settings)->
  Promise = require "bluebird"
  path = require "path"
  fs = require "fs"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  readdir = Promise.promisify require "readdirp"

  writeFile = Promise.promisify fs.writeFile
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


  replaceCachedPattern = (tournament, pattern)->
    tournament.patterns[pattern.mail]=pattern

  replaceCachedMatch = (tournament, match)->
    tournament.matches[match.id]=match

  savePattern = (pdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    pdir = path.join tdir, 'patterns'
    pfile = path.join pdir, pdoc.mail+".yaml"
    pdoc = 
      name:pdoc.name
      author:pdoc.author
      mail:pdoc.mail
      elo:pdoc.elo
      base64String:pdoc.base64String
      pin:pdoc.pin
    mkdir pdir
      .then -> writeFile pfile, dump pdoc
      .then -> cachedTournament tournamentName
      .then (tournament)->
        replaceCachedPattern tournament, pdoc


  saveMatch = (mdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    mdir = path.join tdir, 'matches'
    mfile = path.join mdir, mdoc.id+".yaml"
    mdoc =
      id: mdoc.id
      pattern1:
        base64String:mdoc.pattern1.base64String
        translation:mdoc.pattern1.translation
        modulo:mdoc.pattern1.modulo
        score:mdoc.pattern1.score
      pattern2:
        base64String:mdoc.pattern2.base64String
        translation:mdoc.pattern2.translation
        modulo:mdoc.pattern2.modulo
        score:mdoc.pattern2.score
      pin: mdoc.pin
    mkdir mdir
      .then -> writeFile mfile, dump mdoc
      .then -> cachedTournament tournamentName
      .then(
        (tournament)-> 
          replaceCachedMatch tournament, mdoc
        (err)-> console.log "error", err.stack
      ) 


  saveTournament = (tdoc)->
    tdir = path.join CGOL_HOME,tdoc.name
    metafile = path.join tdir, 'meta.yaml'
    matchdir = path.join tdir, 'matches'
    patterndir = path.join tdir, 'patterns'

    mkdir tdir
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


  getPatternByBase64ForTournament = (base64String, tournamentName)->
    getPatternsForTournament(tournamentName)
      .then (patterns)->
        return pattern for pattern in patterns when pattern.base64String == base64String
        throw new NoSuchPatternError()


  getPatternsAndMatchesForTournament = (tournamentName)->
    cachedTournament tournamentName
      .then (tournament)->
        patterns: (pattern for _,pattern of tournament.patterns)
        matches: (match for _,match of tournament.matches)

  loadTournament = (tournamentName) ->
    pdir = path.join CGOL_HOME, tournamentName, 'patterns'
    mdir = path.join CGOL_HOME, tournamentName, 'matches'
    data=
      patterns:{}
      matches:{}
    debugger
    mkdir pdir
      .then -> mkdir mdir
      .then -> readdir root:pdir, depth:0, entryType:'files'
      .then (entryStreamPatterns)->
        patterns = (entryStreamPatterns?.files ? []).map (entryPattern)-> loadYaml entryPattern.fullPath
        data.patterns[pattern.mail]=pattern for pattern in patterns
      .then -> 
        readdir root:mdir, depth:0, entryType:'files'
      .then (entryStreamMatches)->
        matches = (entryStreamMatches?.files ? []).map (entryMatch)-> loadYaml entryMatch.fullPath
        data.matches[match.id]=match for match in matches
      .then -> 
        data

  getScores = (tournamentName)->
    mdir = path.join CGOL_HOME, tournamentName, 'matches'
    readdir root:mdir, depth:0, entryType:'files'
      .then (scores)->
        data= [
          {name: 'Roman'
          games: 3
          score: 234
          mail: 'romanabendroth@t-online.de'}
          {name: 'Tester1'
          games: 4
          score: 456
          mail: 'service-spec@tarent.de'}
        ]
        data




  allTournaments: allTournaments
  saveTournament: saveTournament
  savePattern: savePattern
  saveMatch:saveMatch
  getPatternsForTournament:getPatternsForTournament
  getPatternByBase64ForTournament:getPatternByBase64ForTournament
  getPatternsAndMatchesForTournament:getPatternsAndMatchesForTournament
  getScores:getScores
