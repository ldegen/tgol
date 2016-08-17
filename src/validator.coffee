module.exports = (repo, tournamentName)->
  Pattern = require "./pattern"
  Promise = require "bluebird"
  NoSuchPatternError = require "./no-such-pattern-error"
  PatternTooLongError = require "./pattern-too-long-error"
  PatternAlreadyRegisteredError = require "./pattern-already-registered-error"
  EmailAlreadyRegisteredError = require "./email-already-registered-error"

  expectError =(constructor,p)->
      p.then(
        -> throw new Error("expected promise to be rejected")
        (e)->
          if e instanceof constructor
            return e
          else
            throw e
      )


  validPattern = (pdoc)->
    pattern = new Pattern(pdoc.base64String)
    if pattern.cells.length > 150
      Promise.reject new PatternTooLongError()
    else
      Promise.resolve()


  mailUnique = (pdoc)->
    expectError NoSuchPatternError, repo.getPatternByEmailForTournament pdoc.mail, tournamentName
      .catch -> 
        throw new EmailAlreadyRegisteredError()
    

  patternUnique = (pdoc)->
    expectError NoSuchPatternError, repo.getPatternByBase64ForTournament pdoc.base64String, tournamentName
      .catch -> 
        throw new PatternAlreadyRegisteredError()


  (pdoc)->
    validPattern pdoc
      .then -> patternUnique pdoc
      .then -> mailUnique pdoc
