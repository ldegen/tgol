
describe "The Service", ->
  Promise = require "bluebird"
  path = require "path"
  fs = require "fs"
  request = Promise.promisify require "request"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile

  loadYaml = require "../src/load-yaml"
  Server = require "../src/server"
  CGOL_HOME = undefined 
  property = (name)->(obj)->obj[name]

  example = (gwt)->
    gwt.given = gwt.given ? ->[]
    ()->
      Promise
        .resolve(gwt.given())
        .then (tournaments)->
          Promise.all (persistTournament tournament for tournament in tournaments)
        .then(gwt.when)
        .then(gwt.then)
  
  server = undefined
  
  
  settings = loadYaml path.resolve __dirname, "../settings.yaml"
  settings.port = 9988

  base = "http://localhost:#{settings.port}"
  
  beforeEach ->
    CGOL_HOME = tmpFileName @test
    mkdir CGOL_HOME
      .then ->
        server = Server CGOL_HOME, settings
        server.start()
  afterEach ->
    server
      .stop()
      .then -> rmdir CGOL_HOME

  it "reports its own version", example
    when: -> request "#{base}/"
    then: (resp)->
      expect(resp.statusCode).to.eql 200
      expect(JSON.parse resp.body).to.eql
        version: require("../package.json").version