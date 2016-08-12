describe "The Matchmaker", ->
  Matchmaker = require "../src/matchmaker"
  matcher = undefined
  patterns = undefined

  beforeEach ->
    matcher = Matchmaker()
    patterns = 
      [
        {mail:"1300@test.com"
        elo:1300}
        {mail:"1200@test.com"
        elo:1200}
        {mail:"900@test.com"
        elo:900}
        {mail:"800@test.com"
        elo:800}
        {mail:"900b@test.com"
        elo:900}
      ]

  it "can select two equally strong patterns from an array", ->
    matchedPatterns = matcher.matchForElo(patterns)
    eloToMatch = matchedPatterns[1].elo
    expect(matchedPatterns[0].elo).to.be.within(eloToMatch-100, eloToMatch+100)
    expect(matchedPatterns[0].mail).to.not.eql(matchedPatterns[1].mail)
    expect(matchedPatterns.length).to.eql(2)