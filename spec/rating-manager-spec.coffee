describe "The rating Manager",->
  Rating = require "../src/rating-manager"
  manager = undefined
  CGOL_HOME = undefined
  Repository = require("../src/repository")
  repo = undefined
  Promise = require "bluebird"
  rmdir = Promise.promisify require "rimraf"
  mkdir = Promise.promisify require "mkdirp"
  pdoc=
    name:'Pattern1'
    author:'John Doe'
    mail:'john@tarent.de'
    base64String:'pattern1String'
    pin:'1234'
  pdoc2 = 
    name:'Pattern2'  
    author:'Jane Doe'
    mail:'jane@tarent.de'
    base64String:'pattern2String'
    pin:'1234'
  pdoc3 = 
    name:'Pattern3'    
    author:'Jim Doe'
    mail:'jim@tarent.de'
    base64String:'pattern3String'
    pin:'1234'
  mdoc1 =
    id:'1'
    pattern1:
      base64String:pdoc.base64String
      translation:'0/0'
      modulo:1
      score:100
    pattern2:
      base64String:pdoc2.base64String
      translation:'1/1'
      modulo:5
      score:50
  mdoc2 =
    id:'2'
    pattern1:
      base64String:pdoc.base64String
      translation:'0/0'
      modulo:1
      score:100
    pattern2:
      base64String:pdoc3.base64String
      translation:'1/1'
      modulo:5
      score:50
  mdoc3 =
    id:'3'
    pattern1:
      base64String:pdoc.base64String
      translation:'0/0'
      modulo:1
      score:100
    pattern2:
      base64String:pdoc2.base64String
      translation:'1/1'
      modulo:5
      score:50
  builder = require("../src/builder")(CGOL_HOME)
  tdoc = builder.tournament
    name:'TestTournament'
    patterns:[
      pdoc,
      pdoc2,
      pdoc3
    ]
    matches:[
      mdoc1,
      mdoc2,
      mdoc3
    ]

  beforeEach -> 
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
    .then ->
      repo = Repository CGOL_HOME
      repo.saveTournament(tdoc)
        .then -> manager = Rating(repo)

  afterEach -> 
    rmdir CGOL_HOME

  it "can update the ELO ratings of patterns, if handed a match", ->
    expect(manager.updateEloNumbers(mdoc1, 'TestTournament')).to.be.fulfilled.then ->
      expect(manager.updateEloNumbers(mdoc2, 'TestTournament')).to.be.fulfilled.then ->
        expect(manager.updateEloNumbers(mdoc3, 'TestTournament')).to.be.fulfilled.then ->
          Promise.all([
            expect(manager.eloNumbers[pdoc.base64String]).to.be.at.least 1040
            expect(manager.games[pdoc.base64String]).to.eql 3
          ])

  it "can return the scores for the tournament", ->
    expect(manager.updateEloNumbers(mdoc1, 'TestTournament')).to.be.fulfilled.then ->
      expect(manager.updateEloNumbers(mdoc2, 'TestTournament')).to.be.fulfilled.then ->
        expect(manager.updateEloNumbers(mdoc3, 'TestTournament')).to.be.fulfilled.then ->
          expect(manager.getScores('TestTournament')).to.be.fulfilled.then (scores)-> 
            expect(scores).to.be.an 'array'
            expect(scores).to.be.lengthOf 3
            res= 
              name:'Pattern1'
              author:'John Doe'
              games:3
              score:1045
              base64String:'pattern1String'
            expect(scores).to.include res 
