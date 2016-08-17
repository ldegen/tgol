module.exports = (weights, random) ->
  if typeof random != 'function'
    random = Math.random
  acc = []
  i = 0
  while i < weights.length
    acc[i] = weights[i]
    if i > 0
      acc[i] += acc[i - 1]
    i++
  s = acc[acc.length - 1]
  if s == 0
    throw new Error('weights sum up to zero?!')
  if s != 1
    acc = acc.map((v) ->
      v / s
    )
  search0 = require('./segment-search')

  search = (d) ->
    search0 acc, d

  ->
    d = random()
    search d