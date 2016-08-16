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
  validator = require("./validator")()

  savePattern = (pdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    pdir = path.join tdir, 'patterns'
    pfile = path.join pdir, pdoc.mail+".yaml"
    writeFile pfile, dump 
      name:pdoc.name
      author:pdoc.author
      mail:pdoc.mail
      elo:pdoc.elo
      base64String:pdoc.base64String
      pin:pdoc.pin

    
  saveMatch = (mdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    mdir = path.join tdir, 'matches'
    mfile = path.join mdir, mdoc.id+".yaml"
    mkdir mdir
      .then ->
        writeFile mfile, dump 
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
       

  saveTournament = (tdoc)->
    tdir = path.join CGOL_HOME,tdoc.name
    metafile = path.join tdir, 'meta.yaml'
    matchdir = path.join tdir, 'matches'
    patterndir = path.join tdir, 'patterns'

    mkdir tdir
      .then -> writeFile metafile, dump
        name:tdoc.name
        pin: tdoc.pin
      .then ->
        Promise.all (savePattern pattern,tdoc.name for pattern in tdoc.patterns)
      .then ->
        Promise.all (saveMatch match,tdoc.name for match in tdoc.matches)


  allTournaments = ->
    readdir root: CGOL_HOME, depth: 0,entryType: 'directories'
      .then (entries)->
        entries.directories
          .map (entry)->"/"+entry.name
          .sort()
  
  
  getPatternsForTournament = (tournamentName)->
    pdir = path.join CGOL_HOME, tournamentName, 'patterns'
    readdir root:pdir, depth:0, entryType:'files'
      .then (entryStream)->
        entryStream.files
          .map (file)->
            loadYaml file.fullPath


  getPatternByBase64ForTournament = (base64String, tournamentName)->
    pdir = path.join CGOL_HOME, tournamentName, 'patterns'
    file = path.join pdir, base64String + ".yaml"
    stat file
      .then (stat)->
        throw new Error "pattern does not exist" if not stat.isFile()
        loadYaml file


  getPatternsAndMatchesForTournament = (tournamentName)->
    pdir = path.join CGOL_HOME, tournamentName, 'patterns'
    mdir = path.join CGOL_HOME, tournamentName, 'matches'
    data=
      patterns:[]
      matches:[]
    Promise.all([
      readdir root:pdir, depth:0, entryType:'files'
      .then (entryStreamPatterns)->
        data.patterns = entryStreamPatterns.files
          .map (entryPattern)->
            loadYaml entryPattern.fullPath
      readdir root:mdir, depth:0, entryType:'files'
        .then (entryStreamMatches)->
          data.matches = entryStreamMatches.files
            .map (entryMatch)->
              loadYaml entryMatch.fullPath
    ]).then ->
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


  checkPatternIsUnique = (baseString,tournamentName)->
    file = path.join CGOL_HOME, tournamentName, "patterns", baseString+'.yaml'
    stat file
      .then ((stats)-> throw new Error("Pattern already in use!") if stats.isFile()), (e)-> true


  allTournaments: allTournaments
  saveTournament: saveTournament
  savePattern: savePattern
  saveMatch:saveMatch
  getPatternsForTournament:getPatternsForTournament
  getPatternByBase64ForTournament:getPatternByBase64ForTournament
  getPatternsAndMatchesForTournament:getPatternsAndMatchesForTournament
  getScores:getScores
