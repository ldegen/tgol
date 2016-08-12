module.exports = ->
  matchForElo = (patterns)->
    loop
      patternA = patterns[Math.floor(Math.random() * patterns.length)]
      patternB = patterns[Math.floor(Math.random() * patterns.length)]
      if patternA.mail == patternB.mail
        continue
      else if patternA.elo >= patternB.elo-100 && patternA.elo <= patternB.elo+100
        pair = [
          patternA
          patternB
        ]
        break
    pair

  matchForElo:matchForElo