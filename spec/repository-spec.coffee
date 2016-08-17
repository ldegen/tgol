describe "The Repository",->
  loadYaml = require "../src/load-yaml"
  Builder = require "../src/builder"
  Repository = require "../src/repository"
  Promise = require "bluebird"
  NoSuchPatternError = require "../src/no-such-pattern-error"
  path = require "path"
  fs = require "fs"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile
  stringify = require("js-yaml").dump
  builder = undefined
  repository = undefined
  CGOL_HOME = undefined
  b=undefined
  Utils = require "../src/util"

  beforeEach ->
    b = Builder()
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
      .then ->
        repository = Repository CGOL_HOME
  afterEach ->
    rmdir CGOL_HOME

  it "can persist tournament data in a filesystem directory", ->
    tdoc = b.tournament
      name:"onkels"
      patterns: [
        "p1"
        "p2"
        "p3"
      ]
      matches: [
        "m1"
        "m2"
        "m3"
        "m4"
      ]
    expect(repository.saveTournament(tdoc)).to.be.fulfilled.then ->
      tdir = path.join CGOL_HOME,tdoc.name
      metafile = path.join tdir, 'meta.yaml'
      matchdir = path.join tdir, 'matches'
      patterndir = path.join tdir, 'patterns'
      Promise.all [
        expect(loadYaml metafile).to.eql
          name:tdoc.name
          pin:tdoc.pin

        expect(loadYaml path.join patterndir, pdoc.mail+".yaml").to.eql pdoc for pdoc in tdoc.patterns
        expect(loadYaml path.join matchdir, mdoc.id+".yaml").to.eql mdoc for mdoc in tdoc.matches
      ]
  it "can list the names of all tournaments", ->
    expect(Promise.all [
      mkdir path.join CGOL_HOME,"t1"
      mkdir path.join CGOL_HOME,"t2"
      mkdir path.join CGOL_HOME,"t3"
    ]).to.be.fulfilled.then ->
      expect(repository.allTournaments()).to.eventually.eql ['/t1','/t2','/t3']

  it "can persist a pattern on the local file system", ->
    tdoc = b.tournament()
    tournamentName = tdoc.name
    tdir = path.join CGOL_HOME, tdoc.name
    mkdir tdir
    pdir = path.join tdir, 'patterns'
    mkdir pdir
    pdoc = b.pattern
      name:"TestPattern"
      author:"Mocha"
      mail:"repo-spec@tarent.de"
      elo:1000
      base64String:"abcdefg=="
      pin:"12345"
    expect(repository.savePattern(pdoc,tdoc.name)).to.be.fulfilled.then ->
      pfile = path.join pdir, pdoc.mail+".yaml"
      expect(loadYaml pfile).to.eql pdoc


  it "can persist match data on the file system", ->
    tdoc = b.tournament()
    tdir = path.join CGOL_HOME, tdoc.name
    mkdir tdir
    mdir = path.join tdir, 'matches'
    mkdir mdir
    mdoc =
      id:'123'
      pattern1:
        base64String:'kjadfajgkja=='
        translation:'1/3'
        modulo:3
        score:123
      pattern2:
        base64String:'ahalkaiatsci='
        translation:'-6/-4'
        modulo:6
        score:456
      pin:12345
    expect(repository.saveMatch(mdoc, tdoc.name)).to.be.fulfilled.then ->
      mfile = path.join mdir, mdoc.id+'.yaml'
      expect(loadYaml mfile).to.eql mdoc


  it "can load an array of all pattern documents from the file system", ->
    tdoc = b.tournament()
    tdir = path.join CGOL_HOME, tdoc.name
    mkdir tdir
    pdir = path.join tdir, 'patterns'
    mkdir pdir
    pdoc1 = b.pattern
      name:"TestPattern1"
      author:"Mocha"
      mail:"repo-spec1@tarent.de"
      elo:1000
      base64String:"abcdefg=="
      pin:"12345"
    pdoc2 = b.pattern
      name:"TestPattern2"
      author:"Chai"
      mail:"repo-spec2@tarent.de"
      elo:1000
      base64String:"hjklmno=="
      pin:"12345"
    expect(
      repository.savePattern(pdoc1, tdoc.name)
        .then -> repository.savePattern(pdoc2, tdoc.name)
        .then -> repository.getPatternsForTournament(tdoc.name)
    ).to.be.fulfilled.then (patterns)->
      Promise.all [
         expect(patterns).to.be.an('array')
         expect(patterns).to.have.length(2)
         expect(patterns).to.include(pdoc1)
         expect(patterns).to.include(pdoc2)
      ]

  it "can load a single pattern document by its base 64 String", ->
    tdoc = b.tournament()
    tdir = path.join CGOL_HOME, tdoc.name
    mkdir tdir
    pdir = path.join tdir, 'patterns'
    mkdir pdir
    pdoc1 = b.pattern
      name:"TestPattern1"
      author:"Mocha"
      mail:"repo-spec1@tarent.de"
      elo:1000
      base64String:"abcdefg=="
      pin:"12345"
    pdoc2 = b.pattern
      name:"TestPattern2"
      author:"Chai"
      mail:"repo-spec2@tarent.de"
      elo:1000
      base64String:"hjklmno=="
      pin:"12345"
    expect(
      repository.savePattern(pdoc1, tdoc.name)
        .then -> repository.savePattern(pdoc2, tdoc.name)
    ).to.be.fulfilled.then ->
       Promise.all [
         expect(repository.getPatternByBase64ForTournament(pdoc1.base64String, tdoc.name)).to.eventually.eql pdoc1
         expect(repository.getPatternByBase64ForTournament(pdoc2.base64String, tdoc.name)).to.eventually.eql pdoc2
         expect(repository.getPatternByBase64ForTournament('abcetasd==', tdoc.name)).to.be.rejectedWith(NoSuchPatternError)
       ]


  it "can get an array of player information for the leaderboard", ->
    tdoc = b.tournament()
    tdir = path.join CGOL_HOME, tdoc.name
    mdir = path.join tdir, 'matches'
    expect(
      mkdir(mdir).then -> repository.getScores(tdoc.name)
    ).to.be.fulfilled.then (scores)->
      Promise.all [
        expect(scores).to.be.an('array')
        expect(scores[0]).to.have.a.property('score')
      ]


  it "can get a collection of patterns and matches for a tournament", ->
    tdoc = b.tournament
      name:'TestTournament'
      patterns:[
        {name:'p1', mail:'m1'}
        {name:'p2', mail:'m2'}
      ]
      matches:[
        {id:'m1'}
      ]
    expect(repository.saveTournament(tdoc)).to.be.fulfilled.then ->
      expect(repository.getPatternsAndMatchesForTournament(tdoc.name)).to.be.fulfilled.then (data)->
        Promise.all [
          expect(data).to.be.an('object')
          expect(data).to.have.a.property('patterns').which.is.an('array')
          expect(data).to.have.a.property('matches').which.is.an('array')
          expect(data.patterns).to.have.a.lengthOf 2
          expect(data.matches).to.have.a.lengthOf 1
          expect(data.patterns[0]).to.have.a.property('name').which.is.eql 'p1'
          expect(data.matches[0]).to.have.a.property('id').which.is.eql 'm1'
        ]
