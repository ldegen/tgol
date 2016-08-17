describe "The Validator", ->
  NoSuchPatternError = require "../src/no-such-pattern-error"
  PatternTooLongError = require "../src/pattern-too-long-error"
  PatternAlreadyRegisteredError = require "../src/pattern-already-registered-error"
  EmailAlreadyRegisteredError = require "../src/email-already-registered-error"
  BadPinError = require "../src/bad-pin-error"
  Validator = require "../src/validator"
  validate = undefined
  Utils = require "../src/util"
  builder = require("../src/builder")()
  CGOL_HOME = undefined
  tdoc = undefined
  Repository = require "../src/repository"
  repo = undefined
  Promise = require "bluebird"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  merge = require "deepmerge"
  Pattern = require "../src/pattern"

  beforeEach ->
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
      .then ->
        tdoc = builder.tournament
          name: 'TestTournament'
        repo = Repository CGOL_HOME
        repo.saveTournament(tdoc)
      .then ->
        validate = Validator(repo, 'TestTournament')

  afterEach ->
    rmdir CGOL_HOME


  it "will reject patterns having more than 150 cells", ->
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
    expect(validate(pdoc)).to.be.rejectedWith(PatternTooLongError)


  it "will reject a pattern with an existing email if the overwrite-Flag is not set", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:'eJxjYGBkYGBkAiIAACMACA=='
      pin:"1234"
    pdoc2 = merge pdoc, base64String: 'eJxjYGBkYGBkYmBmAAAAJQAI'
    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validate(pdoc2)).to.be.rejectedWith(EmailAlreadyRegisteredError)

  it "will accept a pattern with an existing email if the overwrite-Flag is set", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:'eJxjYGBkYGBkAiIAACMACA=='
      pin:"1234"
    pdoc2 = merge pdoc,
      base64String: 'eJxjYGBkYGBkYmBmAAAAJQAI'
    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validate(pdoc2,true)).to.be.fulfilled

  it "will reject a pattern with an existing email if the PINs do not match", ->
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:'eJxjYGBkYGBkAiIAACMACA=='
      pin:"1234"
    pdoc2 = merge pdoc,
      base64String: 'eJxjYGBkYGBkYmBmAAAAJQAI'
      pin:"1245"

    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validate(pdoc2,true)).to.be.rejectedWith(BadPinError)


  it "will reject the pattern if it is already registered", ->
    pattern = new Pattern [1,5,7,8,12]
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:pattern.normalize().encodeSync()
      pin:"1234"
    pdoc2=
      name: "MyPattern2"
      author: "Jane Doe"
      mail:"jane@tarent.de"
      elo:1000
      base64String:pattern.normalize().encodeSync()
      pin:"1234"
    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validate(pdoc2)).to.be.rejectedWith(PatternAlreadyRegisteredError)


  it "will accept patterns if they do not violate beforementioned criteria", ->
    pattern1 = new Pattern [1,5,7,8,12]
    pattern2 = new Pattern [1,3,7,8,12]
    pdoc=
      name: "MyPattern"
      author: "John Doe"
      mail:"john@tarent.de"
      elo:1000
      base64String:pattern1.normalize().encodeSync()
      pin:"1234"
    pdoc2=
      name: "MyPattern2"
      author: "Jane Doe"
      mail:"jane@tarent.de"
      elo:1000
      base64String:pattern2.normalize().encodeSync()
      pin:"1234"
    expect(repo.savePattern(pdoc, tdoc.name)).to.be.fulfilled.then ->
      expect(validate(pdoc2)).to.be.fulfilled
