module.exports = (CGOL_HOME)->
  Pattern = require "./pattern"
  Promise = require "bluebird"
  path = require "path"
  fs = require "fs"
  stat = Promise.promisify fs.stat


  validatePattern = (pdoc)->
    pattern = new Pattern(pdoc.base64String)
    if pattern.cells.length > 150
      false
    else
     true


  isMailAlreadyInUse = (mail, tournamentName)->
    file = path.join CGOL_HOME, tournamentName, "patterns", mail+'.yaml'
    stat file
      .then ((stats)-> throw new Error("Mail already in use!") if stats.isFile()), (e)-> true
    
    
  validatePattern:validatePattern
  isMailAlreadyInUse:isMailAlreadyInUse