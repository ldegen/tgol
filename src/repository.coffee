module.exports = (CGOL_HOME, settings)->
  Promise = require "bluebird"
  path = require "path"
  fs = require "fs"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  readdir = Promise.promisify require "readdirp"
  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile
  dump = require("js-yaml").dump
  loadYaml = require("./load-yaml")


  savePattern = (pdoc, tournamentName)->
    tdir = path.join CGOL_HOME, tournamentName
    pdir = path.join tdir, 'patterns'
    pfile = path.join pdir, pdoc.author+".yaml"
    isAuthorNameAlreadyInUse(pdoc.author).then (val)->
      if val
        throw new Error('Nickname already in use!')
      else
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
      .then -> mkdir matchdir
      .then -> mkdir patterndir
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
    readdir root:pdir, depth:0, entryType:'files'
      .then (entryStream)->
        files = entryStream.files
          .map (entry)->
            loadYaml entry.fullPath
        for file in files
          if file.base64String == base64String
            return file
        return undefined


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
        

  isAuthorNameAlreadyInUse = (author)->
    readdir root:CGOL_HOME, entryType: 'files'
    .then (entryStream)->
      files = entryStream.files
        .map (entry)->entry.name
      author+'.yaml' in files


  allTournaments: allTournaments
  saveTournament: saveTournament
  savePattern: savePattern
  saveMatch:saveMatch
  getPatternsForTournament:getPatternsForTournament
  getPatternByBase64ForTournament:getPatternByBase64ForTournament
  getPatternsAndMatchesForTournament:getPatternsAndMatchesForTournament
  getScores:getScores