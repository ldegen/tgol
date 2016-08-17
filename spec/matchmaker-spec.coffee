describe "The Matchmaker", ->
  Matchmaker = require "../src/matchmaker"
  matcher = undefined
  patterns = undefined
  matches = undefined

  beforeEach ->
    matcher = Matchmaker()
    patterns = 
      [
        {base64String:"aldskjfa"
        elo:1300}
        {base64String:"120adfaskmcz7aölkapij"
        elo:1200}
        {base64String:"adfaskmcz7aölkapijom"
        elo:900}
        {base64String:"adfaskmcz7aölkapijomasf"
        elo:800}
        {base64String:"9adfaskmcz7aölkapij"
        elo:900}
      ]
    matches = 
      [
        {pattern1:
          base64String:"aldskjfa"
        pattern2:
          base64String:"120adfaskmcz7aölkapij"}
        {pattern1:
          base64String:"aldskjfa"
        pattern2:
          base64String:"9adfaskmcz7aölkapij"}
        {pattern1:
          base64String:"aldskjfa"
        pattern2:
          base64String:"adfaskmcz7aölkapijom"}
        {pattern1:
          base64String:"aldskjfa"
        pattern2:
          base64String:"adfaskmcz7aölkapijomasf"}
        {pattern1:
          base64String:"aldskjfa"
        pattern2:
          base64String:"9adfaskmcz7aölkapij"}
        {pattern1:
          base64String:"120adfaskmcz7aölkapij"
        pattern2:
          base64String:"adfaskmcz7aölkapijom"}
      ]

  it "can select two equally strong patterns from an array", ->
    matchedPatterns = matcher.matchForElo(patterns, matches)
    eloToMatch = matchedPatterns[1].elo
    expect(matchedPatterns[0].elo).to.be.within(eloToMatch-100, eloToMatch+100)
    expect(matchedPatterns[0].base64String).to.not.eql(matchedPatterns[1].base64String)
    expect(matchedPatterns.length).to.eql(2)