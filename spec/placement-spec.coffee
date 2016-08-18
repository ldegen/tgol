describe "The Placement strategy", ->
  Pattern = require "../src/pattern"
  Board = require "../src/board"
  Placement = require "../src/placement"
  notSoRandom = ( ()->
    i=0
    -> i++/8
  )()
  it """
     takes two (normalized) patterns and returns eight possible translations for placing both patterns
     'next' to each other
     """, ->
    p1 = new Pattern """
      _|*|*|_|
      *|_|_|*|
      """
    p2 = new Pattern """
      *|_|
      *|_|
      *|*|
      """
    expect(Placement(distance:5).possibleOffsets(p1,p2)).to.eql [
      [-9,-8]
      [0,-8]
      [9,-8]
      [9,0]
      [9,8]
      [0,8]
      [-9,8]
      [-9,0]
    ]

  it "takes two patterns creates a randomized match template", ->
    p1 = new Pattern """
      _|*|*|_|
      *|_|_|*|
      """
    p2 = new Pattern """
      *|_|
      *|_|
      *|*|
      """
    expect(Placement(distance:5, random:notSoRandom).matchTemplate(p1,p2)).to.eql
      id: null
      pattern1:
        base64String: p1.minimize().encodeSync()
        translation: [0,0]
        variant: 0
        score: null
      pattern2:
        base64String: p2.minimize().encodeSync()
        translation: [9,-8]
        variant: 1
        score: null


