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
    name:'John Doe'
    mail:'john@tarent.de'
    base64String:'pattern1String'
    pin:'1234'
  pdoc2 = 
    name:'Jane Doe'
    mail:'jane@tarent.de'
    base64String:'pattern2String'
    pin:'1234'
  pdoc3 = 
    name:'Jim Doe'
    mail:'jim@tarent.de'
    base64String:'pattern3String'
    pin:'1234'
  mdoc =
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
      {id:'1'
      pattern1:
        base64String:pdoc.base64String
        translation:'0/0'
        modulo:1
        score:100
      pattern2:
        base64String:pdoc2.base64String
        translation:'1/1'
        modulo:5
        score:50}
      {id:'2'
      pattern1:
        base64String:pdoc.base64String
        translation:'0/0'
        modulo:1
        score:100
      pattern2:
        base64String:pdoc3.base64String
        translation:'1/1'
        modulo:5
        score:50},
      mdoc
    ]

  beforeEach -> 
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
    .then ->
      repo = Repository CGOL_HOME
      repo.saveTournament(tdoc)
        .then -> manager = Rating(repo, 'TestTournament')

  afterEach -> 
    rmdir CGOL_HOME

  it "can update the ELO ratings of patterns, if handed a match", ->
    expect(manager.updateEloNumbers(mdoc)).to.be.fulfilled.then ->
      console.log 'AFTER THE FUNCTION'
      console.log manager
      expect(manager.eloNumbers[pdoc.base64String]).to.be.at.least 1003

  it "can return the current score for a pattern", ->
    expect(manager.getScore(pdoc)).to.be.fulfilled.then (score)->
      expect(score).to.eql 300
  # it "can update the ELO rating for a player, if given the opponent and the result of the match", ->
  #   ratingA = 1000
  #   ratingB = 1000
  #   ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 1)
  #   ratingB = manager.updateELOForPlayerA(ratingB, ratingA, 0)
  #   expect(ratingA).to.be.above(1000)
  #   expect(ratingB).to.be.below(1000)

  # it "also can handle if a player has no ELO to begin with", ->
  #   ratingA = 0
  #   ratingB = 0
  #   ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 1)
  #   expect(ratingA).to.be.above(0)

  # it "never demotes anyone to an ELO less than 0", ->
  #   ratingA = 0
  #   ratingB = 0
  #   ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 0)
  #   expect(ratingA).to.equal(0)