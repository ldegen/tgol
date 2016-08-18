describe "The Board", ->
  Board = require "../src/board"
  BBox = require("../src/bbox")
  Pattern = require "../src/pattern"
  cell = (x,y,z=0)->[x,y,z]

  it "has a list of living cells and a bounding box", ->
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    expect(board.livingCells()).to.eql [
      cell 2,1
      cell 3,2
      cell 1,3
      cell 2,3
      cell 3,3
    ]
    expect(board.bbox()).to.eql
      left:1
      top:1
      right:4
      bottom:4

  it "can check the state of any given cell", ->
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    expect(board.alive 2,1 ).to.be.true
    expect(board.alive 3,2 ).to.be.true
    expect(board.alive 4,3 ).to.be.false

  it "can toggle the state of a cell and update its bounding box", ->
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    expect(board.bbox()).to.eql
      left:1
      top:1
      right:4
      bottom:4
    board.toggle 2,3
    board.toggle 3,2
    board.toggle 2,2
    expect(board.alive 2,3 ).to.be.false
    expect(board.alive 3,2 ).to.be.false
    expect(board.alive 2,2 ).to.be.true
    expect(board.bbox()).to.eql
      left:1
      top:1
      right:4
      bottom:4
    board.toggle 0,0
    expect(board.alive 0,0).to.be.true
    expect(board.bbox()).to.eql
      left:0
      top:0
      right:4
      bottom:4

    board.toggle 3,3
    expect(board.alive 3,3).to.be.false
    expect(board.bbox()).to.eql
      left:0
      top:0
      right:3
      bottom:4

  it "can represent its state using ascii art",->
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    expect( board.asciiArt
      top:0
      left:0
    ).to.eql """
     _|_|_|_|
     _|_|*|_|
     _|_|_|*|
     _|*|*|*|
    """
    expect( board.asciiArt
      right:5
      bottom:5
    ).to.eql """
    _|*|_|_|
    _|_|*|_|
    *|*|*|_|
    _|_|_|_|
    """

  it "allows living cells with two different colors", ->
     
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|o|_|
     _|*|*|o|_|
     _|_|_|_|_|
    """
    expect(board.livingCells()).to.eql [
      cell 2,1,0
      cell 3,2,1
      cell 1,3,0
      cell 2,3,0
      cell 3,3,1
    ]

  it "can calculate the next generation of cells", ->
    board = Board """ 
     _|_|_|_|
     _|_|*|_|
     _|_|_|*|
     _|*|*|*|
    """
    expect(board.next().asciiArt left:0,top:0).to.eql """
     _|_|_|_|
     _|_|_|_|
     _|*|_|*|
     _|_|*|*|
     _|_|*|_|
    """


  it "adheres to the 'Immigration' (a.k.a. 'Black and White') rules", ->
    board = Board """ 
     _|_|_|
     _|*|_|
     _|*|_|
     _|o|_|
     _|o|_|
     _|_|_|
    """
    expect(board.next().asciiArt left:0,top:0,bottom:6).to.eql """
     _|_|_|
     _|_|_|
     *|*|*|
     o|o|o|
     _|_|_|
     _|_|_|
    """

  it "can paste a pattern in a given color", ->
    board = Board """ 
     _|_|_|_|_|
     _|_|*|_|_|
     _|_|_|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """

    pattern = new Pattern """
    _|*|_|
    _|_|*|
    *|*|*|
    """

    board.paste pattern, 1

    expect(board.asciiArt left:0,top:0,bottom:5,right:5).to.eql """ 
     _|o|_|_|_|
     _|_|o|_|_|
     o|o|o|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """

  it "can create a (single-color) pattern from a rectangular area of the board", ->
    board = Board """
     _|o|_|_|_|
     _|_|o|_|_|
     o|o|o|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    pattern = board.copy left:1, top:2, right:4, bottom:4
    expect(pattern.asciiArt left:0,top:0, bottom:5, right:5).to.eql """
     _|_|_|_|_|
     _|_|_|_|_|
     _|*|*|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """

  it "can erase a rectangular area of the board", ->
    board = Board """
     _|o|_|_|_|
     _|_|o|_|_|
     o|o|o|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    pattern = board.cut left:1, top:2, right:4, bottom:4
    expect(pattern.asciiArt left:0,top:0, bottom:5, right:5).to.eql """
     _|_|_|_|_|
     _|_|_|_|_|
     _|*|*|*|_|
     _|*|*|*|_|
     _|_|_|_|_|
    """
    expect(board.asciiArt left:0,top:0,bottom:5,right:5).to.eql """
     _|o|_|_|_|
     _|_|o|_|_|
     o|_|_|_|_|
     _|_|_|_|_|
     _|_|_|_|_|
    """
  
  it "can initialized from a match document", ->
    mdoc=
      id: null
      pattern1:
        base64String: 'eJxjYGBkZGZgYgQAACQACQ=='
        translation: [0,0]
        variant: 0
        score: null
      pattern2:
        base64String: 'eJxjYGBkYGBkYgAAABUABQ=='
        translation: [9,-8]
        variant: 1
        score: null
    expect(Board.fromMatch(mdoc).asciiArt()).to.eql """
    _|_|_|_|_|_|_|_|_|o|_|_|
    _|_|_|_|_|_|_|_|_|o|o|o|
    _|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|
    *|_|_|*|_|_|_|_|_|_|_|_|
    _|*|*|_|_|_|_|_|_|_|_|_|
    """
