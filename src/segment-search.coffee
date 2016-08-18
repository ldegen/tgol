module.exports = (segments, d) ->
  upper = segments.length
  lower = 0
  while upper > lower
    i = ~~( (upper + lower)/2)
    if d < segments[i - 1]
      upper = i
    else if d >= segments[i]
      lower = i + 1
    else
      return i
    
