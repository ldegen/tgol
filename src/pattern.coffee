isArray = require("util").isArray
merge = require "deepmerge"
BBox = require "./bbox"
AsciiArt = require "./ascii-art"
Util = require "./util"


class Pattern
  constructor: (input, bbox)->
    throw new Error "you forgot to use 'new', doh!" if not (this instanceof Pattern)
    
    @cells = Util.cells(input)
    
    if bbox?
      @_bbox= if bbox instanceof BBox then bbox else new BBox bbox



  indexOf: (x,y)->
    return i for cell,i in @cells when cell[0]==x and cell[1]==y
  alive: (x,y)->
    return @indexOf(x,y)?

  asciiArt:(extent={})->
    AsciiArt.render @cells, extent:extent

  encode: -> Util.encodeCoordinates @cells
  encodeSync: -> Util.encodeCoordinatesSync @cells

  bbox: ->@_bbox?=new BBox @cells
  translate: (dx,dy)->
    [dx,dy] = dx if isArray dx
    cells = ([x+dx,y+dy] for [x,y] in @cells)
    bbox = @_bbox?.translate(dx,dy)
    new Pattern cells, bbox
  normalize: ->
    {left,top}=@bbox()
    @translate 0-left, 0-top
  transpose: ()->
    cells = ([y,x] for [x,y] in @cells)
    bbox = @_bbox?.transpose()
    new Pattern cells, bbox
  vflip: ()->
    cells = ([x,-y] for [x,y] in @cells)
    new Pattern cells, @_bbox?.vflip()
  hflip: ()->
    cells = ([-x,y] for [x,y] in @cells)
    new Pattern cells, @_bbox?.hflip()
  codes: ()->
    @_cantorCodes ?= @cells.map(Util.cantorCode).sort (a,b)->a-b
  compareTo: (o)->
    myCodes = @codes().slice().reverse()
    otherCodes = o.codes().slice().reverse()
    for i in [0...Math.max(myCodes.length, otherCodes.length)]
      a=myCodes[i] ? -1
      b=otherCodes[i] ? -1
      return a-b if a!=b
    return 0
  similarPatterns: ->
    [
      a=@normalize()
      a=a.vflip().normalize()
      a=a.transpose().normalize()
      a=a.vflip().normalize()
      a=a.transpose().normalize()
      a=a.vflip().normalize()
      a=a.transpose().normalize()
      a=a.vflip().normalize()
    ]

  minimize: ->
    min = null
    min = a for a in @similarPatterns() when not min? or (a.compareTo(min) < 0)
    min = new Pattern min.codes().sort()
    min
  clip: (spec)->
    box = new BBox spec
    new Pattern @cells.filter (p)-> box.includes p

  cut: (spec)->
    box = new BBox spec
    new Pattern @cells.filter (p)-> not box.includes p

  union: (other)->
    x=null
    newCells = @cells.concat other.cells
      .sort()
      .filter (cell)-> 
        if cell.toString() != x?.toString()
          x = cell
          return true
    new Pattern newCells

Pattern.decode = (s)-> Util.decodeCoordinates(s).then (cells)->new Pattern cells

module.exports= Pattern
