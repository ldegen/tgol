module.exports = (opts)->
  possibleOffsets: (p0,q0)->
    p = p0.normalize().bbox()
    q = q0.normalize().bbox()
    d = opts.distance ? 2
    w = d + Math.max p.right, q.right
    h = d + Math.max p.bottom, q.bottom

    [
      [-w, -h]
      [0,-h]
      [w,-h]
      [w,0]
      [w,h]
      [0,h]
      [-w,h]
      [-w,0]
    ]
  

  matchTemplate: (p0,q0)->
    rnd =()->Math.floor(opts.random()*8)
    v1 = rnd()
    v2 = rnd()
    p = p0.similarPatterns()[v1]
    q = q0.similarPatterns()[v2]
    id:null
    pattern1:
      base64String: p.minimize().encodeSync()
      translation: [0,0]
      variant: v1
      score:null
    pattern2:
      base64String: q.minimize().encodeSync()
      translation: @possibleOffsets(p,q)[rnd()]
      variant: v2
      score:null
    

