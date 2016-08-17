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
      console.log('WEIGHTS:')
      console.log(weights)
      console.log('PATTERNARRAY:')
      console.log(patterns) 
      wr = WeightedRandom(weights)
      pattern1 = patterns[wr()]
      console.log('SELECTED:')
      console.log(pattern1)

      eqlPatterns = []
      for pattern in patterns
        if pattern.elo >= pattern1.elo - 100 && pattern.elo <= pattern1.elo + 100
          eqlPatterns.push pattern
      console.log('EQLPATTERNS:')
      console.log(eqlPatterns)

      eqlWeights = []
      for eqlPattern in eqlPatterns
        eqlWeights[eqlPatterns.indexOf(eqlPattern)] = weights[eqlPatterns.indexOf(eqlPattern)] 
        # for match in matches
        #   if eqlPattern.base64String == match.pattern1.base64String && eqlPattern.base64String == match.pattern2.base64String
        #     eqlWeights[eqlPatterns.indexOf(eqlPattern)] += 1
      console.log('EQLWEIGHTS:')
      console.log(eqlWeights)
  
      eqlWr = WeightedRandom(eqlWeights)
      pattern2 = eqlPatterns[eqlWr()]

      console.log('PATTERN2:')
      console.log(pattern2)

      if pattern1.base64String != pattern2.base64String
        return [pattern1, pattern2]
      else
        i++
    throw new Error('No matching pattern could be found :(')

  matchForElo:matchForElo