module.exports = (repo, tournamentName)->
  Pattern = require "./pattern"
  Promise = require "bluebird"
  NoSuchPatternError = require "./no-such-pattern-error"
  PatternTooLongError = require "./pattern-too-long-error"
  PatternAlreadyRegisteredError = require "./pattern-already-registered-error"
  EmailAlreadyRegisteredError = require "./email-already-registered-error"
  BadPinError = require "./bad-pin-error"

  only =(Constructor)->
    # catch Errors of given type, rethrow everything else
    (e)-> 
      throw e if not (e instanceof Constructor)

  raise = (Constructor)->
    -> 
      throw new Constructor

  validPattern = (pdoc)->
    pattern = new Pattern(pdoc.base64String)
    if pattern.cells.length > 150
      Promise.reject new PatternTooLongError()
    else
      Promise.resolve()


    

  patternUnique = (pdoc)->
    repo
      .getPatternByBase64ForTournament pdoc.base64String, tournamentName
      .then raise PatternAlreadyRegisteredError
      .catch only NoSuchPatternError

  checkOverwrite = (pdoc,allowOverwrite)->
    repo.getPatternByEmailForTournament pdoc.mail, tournamentName
      .then (existingDoc)->
        if allowOverwrite
          throw new BadPinError() if existingDoc.pin != pdoc.pin
        else
          throw new EmailAlreadyRegisteredError()
      .catch only NoSuchPatternError
    
      

  (pdoc, allowOverwrite)->
    validPattern pdoc
      .then -> patternUnique pdoc
      .then -> checkOverwrite pdoc, allowOverwrite
