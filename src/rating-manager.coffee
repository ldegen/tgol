module.exports = (repo)->
  Promise = require "bluebird"
  Elo = require "elo-rank"
  elo = Elo()
  scores={}
  eloNumbers={}
  

  updateEloNumbers = (mdoc, tournamentName)->
    repo.getMatchesForTournament(tournamentName)
      .then (matches)->
        for match in matches
          if eloNumbers[match.pattern1.base64String] == undefined
            eloNumbers[match.pattern1.base64String] = 1000
          
          if eloNumbers[match.pattern2.base64String] == undefined
            eloNumbers[match.pattern2.base64String] = 1000

        elo1 = eloNumbers[mdoc.pattern1.base64String]
        elo2 = eloNumbers[mdoc.pattern2.base64String]
        expected1 = elo.getExpected(elo1, elo2)    
        expected2 = elo.getExpected(elo2, elo1)        
        if mdoc.pattern1.score > mdoc.pattern2.score
          eloNumbers[mdoc.pattern1.base64String] = elo.updateRating(expected1, 1, elo1) 
          eloNumbers[mdoc.pattern2.base64String] = elo.updateRating(expected2, 0, elo2) 
        else
          eloNumbers[mdoc.pattern1.base64String] = elo.updateRating(expected1, 0, elo1)
          eloNumbers[mdoc.pattern2.base64String] = elo.updateRating(expected2, 1, elo2)


  getScores = (tournamentName)->
    repo.getMatchesForTournament(tournamentName)
      .then (matches)->
        pairs = ([key,score] for key,score of eloNumbers)
        entryPromises = pairs.map ([key,score])-> 
          repo
            .getPatternByBase64ForTournament key, tournamentName
            .then (pdoc)-> 
              entry = {}
              entry['name'] = pdoc.name
              entry['author'] = pdoc.author
              entry['score'] = score
              entry['base64String'] = pdoc.base64String
              entry
        Promise.all entryPromises
       

  calculateScores = (matches)->
    for match in matches
        if scores[match.pattern1.base64String] == undefined 
          scores[match.pattern1.base64String] = 0
          scores[match.pattern1.base64String] += match.pattern1.score
        else
          scores[match.pattern1.base64String] += match.pattern1.score
        
        if scores[match.pattern2.base64String] == undefined 
          scores[match.pattern2.base64String] = 0
          scores[match.pattern2.base64String] += match.pattern2.score
        else
          scores[match.pattern2.base64String] += match.pattern2.score
  
  updateEloNumbers:updateEloNumbers
  scores:scores
  eloNumbers:eloNumbers
  getScores:getScores