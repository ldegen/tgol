describe "The Segment Search", ->
  search = require "../src/segment-search"
  it "finds i for a value d and an ascending sequence a_0, ... a_n-1 such that a_{i-1} ≤ d < a_i ", ->
    segments = [0.125,0.25,0.375,0.5,0.625, 0.75, 0.875,1]
    s = (d)->search segments, d
    expect(s 0).to.eql 0
    expect(s 1).to.be.undefined
    expect(s 0.5).to.eql 4
    expect(s 0.4).to.eql 3
    expect(s 1.1).to.be.undefined
    expect(s -1).to.eql 0
