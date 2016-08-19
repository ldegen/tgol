
describe "The Service", ->
  Promise = require "bluebird"
  Builder = require "../src/builder"
  Repository = require "../src/repository"
  Pattern = require "../src/pattern"
  merge = require "deepmerge"
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

  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile
  Utils = require "../src/util"
  loadYaml = require "../src/load-yaml"
  loadMatchesLog = (matchfile)->
    fs
      .readFileSync(matchfile)
      .toString()
      .split('\n')
      .filter (s)->s.trim()
      .map (line)->JSON.parse line
  Server = require "../src/server"
  CGOL_HOME = undefined
  builder = undefined
  repo = undefined
  pdoc = undefined
  mdoc = undefined

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
  settings = merge settings,
    port: 9988
    minify:
      client:false
      vendor:false
    sourceMaps:
      client:false
      vendor:false
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
        mdoc = 
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
            mdoc
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
    p = new Pattern [1,5,7,8,12]
    pdoc=
      name:'MyPattern'
      author:'Joanne Doe'
      mail:'uploaded@tarent.de'
      elo:1000
      base64String:p.minimize().encodeSync()
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
          base64String:p.encodeSync()
          pin:'12345'
    expect(request auth).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      pfile = path.join CGOL_HOME, 'TestTournament', 'patterns', pdoc.mail+'.yaml'
      expect(loadYaml pfile).to.eql pdoc


  it "can request if a pattern has already been uploaded to a tournament", ->
    expect(request(base+'/api/TestTournament/patterns/lkjtewqfsdufafazakjds==')).to.be.fulfilled.then (resp)->
      Promise.all [
        expect(resp.statusCode).to.eql 404
      ]


  it "can also request this and get the already uploaded pattern", ->
    expect(request(base+'/api/TestTournament/patterns/lkjfazakjds==')).to.be.fulfilled.then (resp)->
      Promise.all [
        expect(resp.statusCode).to.eql 200
        expect(JSON.parse resp.body).to.eql
          name:'MyPattern'
          author:'John Doe'
          mail:'john@tarent.de'
          base64String:'lkjfazakjds=='
          pin:'12345'
      ]
  
  it "can persist an uploaded match", ->
    mdoc= 
      pattern1:
        base64String:'kjafdscaASDasdkjaA'
        translation:[-1,4]
        variant:3
        score:0
      pattern2:
        base64String:'ASDlkajsdazASDalksmAS'
        translation:[5,-8]
        variant:7
        score:0
      pin:673428
    auth = 
      url:base+'/api/TestTournament/matches'
      method:'POST'
      json:
        mdoc:
         pattern1:
           base64String:'kjafdscaASDasdkjaA'
           translation:[-1,4]
           variant:3
           score:0
         pattern2:
           base64String:'ASDlkajsdazASDalksmAS'
           translation:[5,-8]
           variant:7
           score:0
         pin:673428
    expect(request auth).to.be.fulfilled.then (resp)->
      expect(resp.statusCode).to.eql 200
      mfile = path.join CGOL_HOME, 'TestTournament', 'matches.log'
      matches = loadMatchesLog mfile
      expect(matches[matches.length-1]).to.eql mdoc


  it "can return scores for the matches to be displayed on a leaderboard", ->
    auth = 
      url:"#{base}/api/TestTournament/matches"
      method:'POST'
      json:
        mdoc:
          id:'match2'
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
    # console.log auth
    expect(request auth).to.be.fulfilled.then ->
      expect(request "#{base}/api/TestTournament/leaderboard").to.be.fulfilled
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
        base64String:'lkjfazakjds=='
        pin:'12345'
      expect(JSON.parse(resp.body).matches).to.include
        pattern1:
          base64String:'lkjfazakjds=='
          translation:[1,1]
          variant:1
          score:100
        pattern2:
          base64String:'iuzaiszdgig=='
          translation:[2,2]
          variant:2
          score:200


  xit "can request two equally strong patterns to form the next match", ->
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
