module.exports = (CGOL_HOME, settings)->
  Promise = require "bluebird"
  http = require "http"
  net = require "net"

  Service = require "./service"

  server = undefined

  service = Service CGOL_HOME
  startServer = ()->
    new Promise (resolve,reject)->
      try
        server = http.createServer service, settings
        server.listen settings.port, settings.host, resolve
      catch e
        reject e

  stopServer = ()->
    new Promise (resolve, reject)->
      try
        server.close resolve
      catch e
        reject e

  reload = (path)->
    service.switchWorkspace path
  start: startServer
  stop: stopServer
  switchWorkspace: reload

