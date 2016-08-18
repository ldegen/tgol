module.exports = (opts)->
  vars = (p0,q0)->
    {right:w1,bottom:h1} = p0.normalize().bbox()
    {right:w2,bottom:h2} = q0.normalize().bbox()
    d = opts.distance ? 2
    w = w1+w2+2*d
    h = h1+h2+2*d
    w1:w1
    h1:h1
    w2:w2
    h2:h2
    d:d
    w:w
    h:h
    N:2*(w+h)

  possibleOffsetPairs: (p0,q0)->
    vars p0,q0
      .N

  offsetPair: (p,q,j)->
    {d,w2,h2,w,h,N} = vars p,q
    t1 = [w2+d,h2+d]
    i = j % N
    t2 = switch
      when i < w then [i,0]
      when i < w+h then [w,i-w]
      when i < 2*w+h then [2*w+h-i,h]
      when i < N then [0,N-i]
      else
        throw new Error("häh?")
    [t1,t2]

  

  matchTemplate: (p0,q0)->
    rnd =(n)->Math.floor((opts.random ? Math.random)()*n)
    v1 = rnd(8)
    v2 = rnd(8)
    p = p0.similarPatterns()[v1]
    q = q0.similarPatterns()[v2]
    N = @possibleOffsetPairs p,q
    [t1,t2] = @offsetPair p,q,rnd(N)
    id:null
    pattern1:
      base64String: p.minimize().encodeSync()
      translation: t1
      variant: v1
      score:null
    pattern2:
      base64String: q.minimize().encodeSync()
      translation: t2
      variant: v2
      score:null
    

