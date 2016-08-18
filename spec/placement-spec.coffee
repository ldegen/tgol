describe "The Placement strategy", ->
  Pattern = require "../src/pattern"
  Board = require "../src/board"
  Placement = require "../src/placement"
  notSoRandom = ( ()->
    i=0
    -> i++/8
  )()
  p1 = undefined
  p2 = undefined
  placement = Placement
    distance:2
    random: notSoRandom
  beforeEach ->

    p1 = new Pattern """
      _|*|*|_|
      *|_|_|*|
      """
    p2 = new Pattern """
      *|_|
      *|_|
      *|*|
      """

  it """
     calculates the number of possible offset pairs for two patterns
     """, ->
    expect(placement.possibleOffsetPairs(p1,p2)).to.eql 38

  it "can calculate the i-th of the possible offset pairs", ->
    expect(placement.offsetPair(p1,p2,3)).to.eql [[4,5],[3,0]]
    expect(placement.offsetPair(p1,p2,14)).to.eql [[4,5],[10,4]]
    expect(placement.offsetPair(p1,p2,25)).to.eql [[4,5],[4,9]]
    expect(placement.offsetPair(p1,p2,36)).to.eql [[4,5],[0,2]]

  it "takes two patterns creates a randomized match template", ->
    expect(placement.matchTemplate(p1,p2)).to.eql
      id: null
      pattern1:
        base64String: p1.minimize().encodeSync()
        translation: [4,5]
        variant: 0
        score: null
      pattern2:
        base64String: p2.minimize().encodeSync()
        translation: [9,0]
        variant: 1
        score: null


