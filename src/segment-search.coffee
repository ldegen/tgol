module.exports = (segments, d) ->
  i = Math.floor(segments.length / 2)
  while i < segments.length and i >= 0
    if d < segments[i - 1]
      i = Math.floor(i / 2)
    else if d >= segments[i]
      i = i + Math.ceil((segments.length - i) / 2)
    else
      break
  Math.max 0, Math.min(segments.length - 1, i)