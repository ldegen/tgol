describe "The Repository",->
  loadYaml = require "../src/load-yaml"
  Builder = require "../src/builder"
  Repository = require "../src/repository"
  Promise = require "bluebird"
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
      expect(loadYaml metafile).to.eql
        name:tdoc.name
        pin:tdoc.pin

      expect(loadYaml path.join patterndir, pdoc.mail+".yaml").to.eql pdoc for pdoc in tdoc.patterns
      expect(loadYaml path.join matchdir, mdoc.name+".yaml").to.eql mdoc for mdoc in tdoc.matches

  it "can list the names of all tournaments", ->
    expect(Promise.all [
      mkdir path.join CGOL_HOME,"t1"
      mkdir path.join CGOL_HOME,"t2"
      mkdir path.join CGOL_HOME,"t3"
    ]).to.be.fulfilled.then ->
      expect(repository.allTournaments()).to.eventually.eql ['/t1','/t2','/t3']

  it "can persist a pattern on the local file system", ->
    tdoc = b.tournament
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
    
  it "wont persist two patterns with the same mail addres", ->
    tdoc = b.tournament
    tdir = path.join CGOL_HOME, tdoc.name
    mkdir tdir
    pdir = path.join tdir, 'patterns'
    mkdir pdir
    pdoc1 = b.pattern
      name:"TestPattern1"
      author:"Mocha"
      mail:"repo-spec@tarent.de"
      elo:1000
      base64String:"abcdefg=="
      pin:"12345"
    pdoc2 = b.pattern
      name:"TestPattern2"
      author:"Chai"
      mail:"repo-spec@tarent.de"
      elo:1000
      base64String:"hjklmno=="
      pin:"12345"
    expect(repository.savePattern(pdoc1, tdoc.name)).to.be.fulfilled.then ->
      expect(repository.savePattern(pdoc2, tdoc.name)).to.be.rejected
      expect(repository.savePattern(pdoc2,tdoc.name)).to.be.rejectedWith("Mail already in use!")

  it "can load an array of pattern documents from the file system", ->
    tdoc = b.tournament
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
    expect(repository.savePattern(pdoc1, tdoc.name)).to.be.fulfilled.then ->
     expect(repository.savePattern(pdoc2, tdoc.name)).to.be.fulfilled.then ->
       expect(repository.getPatternsForTournament(tdoc.name)).to.be.fulfilled.then (patterns)->
         expect(patterns).to.be.an('array')
         expect(patterns).to.have.length(2)
         expect(patterns).to.include(pdoc1)
         expect(patterns).to.include(pdoc2)

  it "can load a single pattern document by its base 64 String", ->
    tdoc = b.tournament
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
    expect(repository.savePattern(pdoc1, tdoc.name)).to.be.fulfilled.then ->
     expect(repository.savePattern(pdoc2, tdoc.name)).to.be.fulfilled.then ->
       expect(repository.getPattern(pdoc1.base64String, tdoc.name)).to.be.fulfilled.then (pattern)->
         expect(pattern).to.not.be.undefinded
         expect(pattern).to.not.be.an('array')
         expect(pattern).to.be.eql(pdoc1)
       expect(repository.getPattern(pdoc2.base64String, tdoc.name)).to.be.fulfilled.then (pattern2)->
         expect(pattern2).to.not.be.undefinded
         expect(pattern2).to.not.be.an('array')
         expect(pattern2).to.be.eql(pdoc2)
