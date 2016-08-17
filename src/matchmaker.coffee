module.exports = ->
  WeightedRandom = require "./weighted-random"

  matchForElo = (patterns, matches)->
    i = 0
    while i < 10
      weights = []
      for pattern in patterns
        weights[patterns.indexOf(pattern)] = 0 
        for match in matches
          if pattern.base64String == match.pattern1.base64String || pattern.base64String == match.pattern2.base64String
            weights[patterns.indexOf(pattern)] += 1
            
      wr = WeightedRandom(weights)
      pattern1 = patterns[wr()]

      eqlPatterns = []
      for pattern in patterns
        if pattern.elo >= pattern1.elo - 100 && pattern.elo <= pattern1.elo + 100
          eqlPatterns.push pattern

      eqlWeights = []
      for eqlPattern in eqlPatterns
        eqlWeights[eqlPatterns.indexOf(eqlPattern)] = weights[eqlPatterns.indexOf(eqlPattern)] 
  
      eqlWr = WeightedRandom(eqlWeights)
      pattern2 = eqlPatterns[eqlWr()]

      if pattern1.base64String != pattern2.base64String
        return [pattern1, pattern2]
      else
        i++
    throw new Error('No matching pattern could be found :(')

  matchForElo:matchForElo