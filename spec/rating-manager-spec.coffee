describe "The rating Manager",->
  Rating = require "../src/rating-manager"
  manager = undefined

  beforeEach -> 
    manager = Rating()

  it "can update the ELO rating for a player, if given the opponent and the result of the match", ->
    ratingA = 1000
    ratingB = 1000
    ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 1)
    ratingB = manager.updateELOForPlayerA(ratingB, ratingA, 0)
    expect(ratingA).to.be.above(1000)
    expect(ratingB).to.be.below(1000)

  it "also can handle if a player has no ELO to begin with", ->
    ratingA = 0
    ratingB = 0
    ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 1)
    expect(ratingA).to.be.above(0)

  it "never demotes anyone to an ELO less than 0", ->
    ratingA = 0
    ratingB = 0
    ratingA = manager.updateELOForPlayerA(ratingA, ratingB, 0)
    expect(ratingA).to.equal(0)