describe "The rating Manager",->
  Rating = require "../src/rating-manager"
  manager = undefined
  CGOL_HOME = tmpFileName @test
  repo = require("../src/repository")(CGOL_HOME)
  pdoc=
    name:'John Doe'
    mail:'john@tarent.de'
    base64String:'kajfmckuwmzrxkaj'
    pin:'1234'
  pdoc2 = 
    name:'Jane Doe'
    mail:'jane@tarent.de'
    base64String:'kajfmckuwadadfamzrxkaj'
    pin:'1234'
  pdoc3 = 
    name:'Jim Doe'
    mail:'jim@tarent.de'
    base64String:'kasadfsdjfmckuwmzrxkaj'
    pin:'1234'
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
        score:50}
      {id:'3'
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
    ]

  beforeEach -> 
    repo.saveTournament(tdoc)
    manager = Rating(repo)

  it "can calculate the rating for a pattern based on its history", ->
    elo1 = manager.calculateEloForPattern(pdoc)
    expect(elo1).to.be.at.least 103

  
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