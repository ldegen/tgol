module.exports = (repo)->
  Promise = require "bluebird"
  Repository = require "./repository"
  Elo = require "elo-rank"
  elo = Elo()
  scores={}
  eloNumbers={}
  games = {}
  init = true
  

  updateEloNumbers = (mdoc, tournamentName)-> 
    updateScores(mdoc)
    updateGames(mdoc)
    init = false


  getScores = (tournamentName)->
    if init
      repo.getMatchesForTournament(tournamentName)
      .then (matches)->
        for match in matches
          if not eloNumbers[match.pattern1.base64String]?
            eloNumbers[match.pattern1.base64String] = 1000
          
          if not eloNumbers[match.pattern2.base64String]?
            eloNumbers[match.pattern2.base64String] = 1000     
          updateScores(match)
          updateGames(match)
        init = false

    pairs = ([key,score] for key,score of eloNumbers)
    entryPromises = pairs.map ([key,score])->
      repo
        .getPatternByBase64ForTournament key, tournamentName
        .then (pdoc)-> 
          entry = {}
          entry['name'] = pdoc.name
          entry['author'] = pdoc.author
          entry['games'] = games[pdoc.base64String]
          entry['score'] = score
          entry['base64String'] = pdoc.base64String
          entry
        .catch (e)->
          console.log e
          return undefined
    Promise.all entryPromises


  updateScores = (mdoc)->
    if not eloNumbers[mdoc.pattern1.base64String]?
      eloNumbers[mdoc.pattern1.base64String] = 1000
          
    if not eloNumbers[mdoc.pattern2.base64String]?
      eloNumbers[mdoc.pattern2.base64String] = 1000

    elo1 = eloNumbers[mdoc.pattern1.base64String]
    elo2 = eloNumbers[mdoc.pattern2.base64String]
    expected1 = elo.getExpected(elo1, elo2)    
    expected2 = elo.getExpected(elo2, elo1)        
    
    if mdoc.pattern1.score > mdoc.pattern2.score
      eloNumbers[mdoc.pattern1.base64String] = elo.updateRating(expected1, 1, elo1) 
      eloNumbers[mdoc.pattern2.base64String] = elo.updateRating(expected2, 0, elo2) 
    else if mdoc.pattern1.score < mdoc.pattern2.score
      eloNumbers[mdoc.pattern1.base64String] = elo.updateRating(expected1, 0, elo1)
      eloNumbers[mdoc.pattern2.base64String] = elo.updateRating(expected2, 1, elo2)


  updateGames = (match)->
    if not games[match.pattern1.base64String]?
      games[match.pattern1.base64String] = 1
    else
      games[match.pattern1.base64String] += 1
    
    if not games[match.pattern2.base64String]?
      games[match.pattern2.base64String] = 1
    else
      games[match.pattern2.base64String] += 1

  
  updateEloNumbers:updateEloNumbers
  scores:scores
  eloNumbers:eloNumbers
  getScores:getScores
  games:games