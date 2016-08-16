describe "The Validator", ->
  Validator = require "../src/validator"
  validator = Validator()
  Utils = require "../src/util"
  Builder = require "../src/builder"
  CGOL_HOME = undefined
  tdoc = undefined
  Repository = require "../src/repository"

  it "will return false for patterns having more than 150 cells", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:""
      pin:"1234"
    cells =[]
    for i in [0...50]
      for j in [0...4]
        cells.push([i,j])
    pdoc.base64String = Utils.encodeCoordinatesSync(cells)
    result = validator.validatePattern(pdoc)
    expect(result).to.be.false