
describe "The Service", ->
  Promise = require "bluebird"
  Builder = require "../src/builder"
  Repository = require "../src/repository"

  path = require "path"
  fs = require "fs"
  request = Promise.promisify require "request"
  mkdir = Promise.promisify require "mkdirp"
  exec = require("child_process").exec
  rmdir = (dir) ->
    new Promise (resolve,reject) ->
      exec "rm -rf '#{dir}'", (error, stdout, stderr)->
        if error?
          reject error
        else
          resolve()

  #rimraf = require "rimraf"
  #rmdir = (dir)->
  #  opts =
  #    glob:false
  #    emfileWait: 10
  #  new Promise (resolve, reject) ->
  #    rimraf dir, opts, (err)->
  #      if err?
  #        reject err
  #      else
  #        resolve()
  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile
  Utils = require "../src/util"
  loadYaml = require "../src/load-yaml"
  Server = require "../src/server"
  CGOL_HOME = undefined
  builder = undefined
  repo = undefined
  pdoc = undefined

  this.timeout(20000)

  _now = undefined
  log = (s)->
    #now = Date.now()
    #d = if _now? then now - _now else 0
    #_now = now
    #console.log s, d

  property = (name)->(obj)->obj[name]


  server = undefined
  settings = loadYaml path.resolve __dirname, "../settings.yaml"
  settings.port = 9988

  base = "http://localhost:#{settings.port}"
  
  profiler = require "v8-profiler"
  before ->
    server = Server "/tmp", settings
    server.start()
      .then -> log "server started, warming up"
      .then -> request base+"/js/vendor.js" # triggers minification of vendor code
      .then -> request base+"/js/client.js" # triggers concatenation of our own client code
      .then -> log "ready to go"

    #profiler.startProfiling('1', true)  
  after ()->
    server
      .stop()
      .then -> log "server stopped"
    #profiler
      #.stopProfiling()
      #.export()
      #.pipe(fs.createWriteStream('/tmp/profile.json'))
      #.on 'finish', ->done()
  beforeEach ->
    builder = Builder()
    CGOL_HOME = tmpFileName @test
    log "beforeEach"
    rmdir CGOL_HOME
      .then -> log "rmdir complete"
      .then -> mkdir CGOL_HOME
      .then -> log "mkdir complete"
      .then ->
        repo = Repository CGOL_HOME
        tdoc = builder.tournament
          name:'TestTournament'
          patterns:[
            {name:'MyPattern'
            author:'John Doe'
            mail:'john@tarent.de'
            elo:1000
            base64String:'lkjfazakjds=='
            pin:'12345'}
            {name:'MyOtherPattern'
            author:'Jonathan Doe'
            mail:'jonathan@tarent.de'
            elo:1100
            base64String:'iuzaiszdgig=='
            pin:'12345'}
            {name:'Ridiculously Strong Pattern'
            author:'Jane Doe'
            mail:'jane@tarent.de'
            elo:9001
            base64String:'ItsOver9000OMG='
            pin:'98765'}
          ]
          matches:[
            id:'match1'
            pattern1:
              base64String:'lkjfazakjds=='
              translation:'1/1'
              modulo:1
              score:100
            pattern2:
              base64String:'iuzaiszdgig=='
              translation:'2/2'
              modulo:2
              score:200
            pin:45678
          ]
        repo.saveTournament(tdoc)
      .then -> log "saveTournament complete"
      .then ->
          server.switchWorkspace CGOL_HOME
      .then -> log "workspace switched"
  afterEach ->
    log "afterEach"

##################################################################################################

  it "reports its own version and a links to all tournaments", ->
    repo.saveTournament(builder.tournament name: 'onkels')
    repo.saveTournament(builder.tournament name: 'tanten')
    expect(request "#{base}/api").to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      expect(JSON.parse resp.body).to.eql
        version: require("../package.json").version
        tournaments: [
          '/TestTournament'
          '/onkels'
          '/tanten'
        ]


  it "can persist an uploaded pattern", ->
    pdoc=
      name:'MyPattern'
      author:'Joanne Doe'
      mail:'uploaded@tarent.de'
      elo:1000
      base64String:'asfkjsdffjc'
      pin:'12345'
    auth =
      url:base+'/api/TestTournament/patterns'
      method: 'POST'
      json:
        pdoc:
          name:'MyPattern'
          author:'Joanne Doe'
          mail:'uploaded@tarent.de'
          elo:1000
          base64String:'asfkjsdffjc'
          pin:'12345'
    expect(request auth).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      pfile = path.join CGOL_HOME, 'TestTournament', 'patterns', pdoc.mail+'.yaml'
      expect(loadYaml pfile).to.eql pdoc


  it "can request if a pattern has already been uploaded to a tournament and return an empty pattern if not", ->
    expect(request(base+'/api/TestTournament/patterns/lkjtewqfsdufafazakjds==')).to.be.fulfilled.then (resp)->
      Promise.all [
        expect(resp.statusCode).to.eql 404
        expect(resp.body).to.be.empty
      ]


  it "can also request this and get the already uploaded pattern", ->
    expect(request(base+'/api/TestTournament/patterns/lkjfazakjds==')).to.be.fulfilled.then (resp)->
      Promise.all [
        expect(resp.statusCode).to.eql 200
        expect(JSON.parse resp.body).to.eql
          name:'MyPattern'
          author:'John Doe'
          mail:'john@tarent.de'
          elo:1000
          base64String:'lkjfazakjds=='
          pin:'12345'
      ]
  
  it "can persist an uploaded match", ->
    mdoc= 
      id:'match_101'
      pattern1:
        base64String:'kjafdscaASDasdkjaA'
        translation:'-1/4'
        modulo:3
        score:0
      pattern2:
        base64String:'ASDlkajsdazASDalksmAS'
        translation:'5/-8'
        modulo:7
        score:0
      pin:673428
    auth = 
      url:base+'/api/TestTournament/matches'
      method:'POST'
      json:
        mdoc:
         id:'match_101'
         pattern1:
           base64String:'kjafdscaASDasdkjaA'
           translation:'-1/4'
           modulo:3
           score:0
         pattern2:
           base64String:'ASDlkajsdazASDalksmAS'
           translation:'5/-8'
           modulo:7
           score:0
         pin:673428
    expect(request auth).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      mfile = path.join CGOL_HOME, 'TestTournament', 'matches', mdoc.id+'.yaml'
      expect(loadYaml mfile).to.eql mdoc


  it "can return scores for the matches to be displayed on a leaderboard", ->
    request "#{base}/api/TestTournament/leaderboard"
      .then (resp)->
        expect(resp.statusCode).to.eql 200
        expect(JSON.parse resp.body).to.be.an('array')
        expect(JSON.parse(resp.body)[0]).to.be.an('object').which.has.a.property('score')
        expect(JSON.parse(resp.body)[0]).to.be.an('object').which.has.a.property('name')
        expect(JSON.parse(resp.body)[0]).to.be.an('object').which.has.a.property('games')
        

  it "can get a collection of all patterns and matches in a tournament", ->
    expect(request(base+'/api/TestTournament')).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      expect(JSON.parse resp.body).to.have.a.property('patterns').which.is.an('array')
      expect(JSON.parse resp.body).to.have.a.property('matches').which.is.an('array')
      expect(JSON.parse(resp.body).patterns).to.have.a.lengthOf 3
      expect(JSON.parse(resp.body).matches).to.have.a.lengthOf 1
      expect(JSON.parse(resp.body).patterns).to.include
        name:'MyPattern'
        author:'John Doe'
        mail:'john@tarent.de'
        elo:1000
        base64String:'lkjfazakjds=='
        pin:'12345'
      expect(JSON.parse(resp.body).matches).to.include
        id:'match1'
        pattern1:
          base64String:'lkjfazakjds=='
          translation:'1/1'
          modulo:1
          score:100
        pattern2:
          base64String:'iuzaiszdgig=='
          translation:'2/2'
          modulo:2
          score:200
        pin:45678


  it "can request two equally strong patterns to form the next match", ->
    expect(request(base+'/api/TestTournament/matchmaker')).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      expect(JSON.parse resp.body).to.be.an('array').which.has.lengthOf 2
      expect(JSON.parse resp.body).to.include
        name:'MyPattern'
        author:'John Doe'
        mail:'john@tarent.de'
        elo:1000
        base64String:'lkjfazakjds=='
        pin:'12345'
      expect(JSON.parse resp.body).to.include
        name:'MyOtherPattern'
        author:'Jonathan Doe'
        mail:'jonathan@tarent.de'
        elo:1100
        base64String:'iuzaiszdgig=='
        pin:'12345'
      expect(JSON.parse resp.body).to.not.include
        name:'Ridiculously Strong Pattern'
        author:'Jane Doe'
        mail:'jane@tarent.de'
        elo:9001
        base64String:'ItsOver9000OMG='
        pin:'98765'
