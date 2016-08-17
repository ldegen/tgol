describe 'The wheighted random choice', ->
  notSoRandom = undefined
  WeightedRandom = require('../src/weighted-random')
  beforeEach ->
    `var WeightedRandom`

    notSoRandom = ->
      data = Array::slice.call(arguments)
      i = 0
      ->
        r = data[i++ % data.length]
        r

    WeightedRandom = require('../src/weighted-random')
    return
  it 'randomly picks an integer from an interval [0,N[ according to a given (discrete) distribution', ->
    random = notSoRandom(0, 1 / 4, 2 / 4, 3 / 4)
    wr = WeightedRandom([
      0.0
      0.5
      0.25
      0.25
    ], random)
    counters = 
      0: 0
      1: 0
      2: 0
      3: 0
    i = 0
    while i < 100
      counters[wr()]++
      i++
    expect(counters).to.eql
      0: 0
      1: 50
      2: 25
      3: 25
    return
  it 'normalizes the distribution (such that propabilities sum up to 1)', ->
    random = notSoRandom(0, 1 / 4, 2 / 4, 3 / 4)
    wr = WeightedRandom([
      0
      12
      6
      6
    ], random)
    counters = 
      0: 0
      1: 0
      2: 0
      3: 0
    i = 0
    while i < 100
      counters[wr()]++
      i++
    expect(counters).to.eql
      0: 0
      1: 50
      2: 25
      3: 25
    return
  return