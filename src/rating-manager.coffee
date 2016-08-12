module.exports = ->
  Elo = require "elo-rank"
  elo = Elo()

  updateELOForPlayerA = (eloRankA, eloRankB, result)->
      expectedA = elo.getExpected(eloRankA, eloRankB)
      expectedB = elo.getExpected(eloRankB, eloRankA)
      if result == 1
        eloRankA = elo.updateRating(expectedA, 1, eloRankA)
        eloRankA
      else
        eloRankA = elo.updateRating(expectedA, 0, eloRankA)
        if eloRankA < 0
          eloRankA = 0
        eloRankA

  updateELOForPlayerA:updateELOForPlayerA