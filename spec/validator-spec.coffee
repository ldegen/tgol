describe "The Validator", ->
  Validator = require "../src/validator"
  validator = undefined
  Utils = require "../src/util"
  builder = require("../src/builder")() 
  CGOL_HOME = undefined
  tdoc = undefined
  Repository = require "../src/repository"
  repo = undefined
  Promise = require "bluebird"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"

  beforeEach ->
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
      .then ->
        validator = Validator(CGOL_HOME)
        tdoc = builder.tournament
          name: 'TestTournament'
        repo = Repository CGOL_HOME
        repo.saveTournament(tdoc)

  afterEach ->
    rmdir CGOL_HOME


  it "will return false for patterns having more than 150 cells", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:""
      pin:"1234"
    cells =[]
    for i in [0...51]
      for j in [0...3]
        cells.push([i,j])
    pdoc.base64String = Utils.encodeCoordinatesSync(cells)
    result = validator.validatePattern(pdoc)
    expect(result).to.be.false


  it "will throw an error if the author's mail adress is already in use for a pattern", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:""
      pin:"1234"
    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validator.isMailAlreadyInUse(pdoc.mail, 'TestTournament')).to.be.rejectedWith('Mail already in use!')