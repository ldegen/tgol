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


  matchForElo: (patterns,matches)->
    patternLU = {}
    counters = []
    for pattern,i in patterns
      patternLU[pattern.base64String] = i
      counters[i]=0
    
    for match in matches
      i = patternLU[match.pattern1.base64String]
      j = patternLU[match.pattern2.base64String]
      counters[i]++
      counters[j]++

    weights = counters.map (c)->1/(c+1)

    rnd = WeightedRandom weights
    i = rnd()
    console.log "i",i
    j=i
    while weights.length > 1 and j==i
      j= rnd()
    console.log "j", j 

    [patterns[i], patterns[j]]
