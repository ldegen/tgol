module.exports = ->
  tournaments = []
  patterns = []
  matches = []
  toArray = (args)->
    Array::slice.call args
  flatten = (args)->
    Array::concat.apply [],args

  spec2obj = (spec, pk='name')->
    return spec if typeof spec == "object"
    "#{pk}":spec


  merge = ()->
    args = flatten arguments
    defaults = spec2obj args[0]
    doc = {}
    for spec in args
      overrides = spec2obj spec
      doc[key] = overrides[key] for key of defaults when overrides[key]?
    doc

  match = ()->
    defaults=
      id:"match_"+matches.length
      pattern1:
        base64String:'pattern1'
        translation:"1/1"
        modulo:0
        score:0
      pattern2:
        base64String:'pattern2'
        translation:"2/2"
        modulo:1
        score:0
      pin:'t0ps3cr3t'
    doc = merge defaults, toArray arguments
    matches.push doc
    doc
  pattern = ()->
    defaults=
      name:"pattern_"+patterns.length
      author:"someone_"+patterns.length
      mail:"gol"+patterns.length+"@tarent.de"
      elo:100
      base64String:"abcdef=="
      pin:'t0ps3cr3t'
    doc = merge defaults, toArray arguments
    patterns.push doc
    doc
  tournament = ()->
    defaults=
      name:"tournament_"+tournaments.length
      pin:'t0ps3cr3t'
      patterns:[]
      matches:[]
    doc = merge defaults, toArray arguments
    tournaments.push doc
    doc.patterns = (pattern spec for spec in doc.patterns)
    doc.matches = (match spec for spec in doc.matches)
    doc

  pattern:pattern
  tournament:tournament
  match:match
  buildTournaments: ->tournaments
