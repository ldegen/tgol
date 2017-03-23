merge = require "deepmerge"
BBox = require "./bbox"
Pattern = require "./pattern"
AsciiArt = require "./ascii-art"
Util = require "./util"
Board = (spec)->
  _livingCells = Util.cells spec, parseColors:true
  _bbox=null


  bbox = ()->
    if _livingCells.length>0
      _bbox = new BBox _livingCells if not _bbox
      _bbox.data()
  livingCells = ()->
    _livingCells.slice()


  indexOf = (x,y)-> new Pattern(_livingCells).indexOf(x,y)
  alive = (x,y)->new Pattern(_livingCells).alive(x,y)

  kill = (i)->
    [[x,y]] = _livingCells.splice i,1
    if _bbox?.touches [x,y]
      _bbox = null
  spawn =(x,y,z)->
    c= [x,y,z]
    _livingCells.push c
    _bbox?.add c

  toggle = (x,y,z)->
    i = indexOf x,y
    if i?
      kill i
    else
      spawn x,y,z
    this

  cycle = (x, y, max=1)->
    i = indexOf(x,y) 
    if i?
      z = _livingCells[i][2]
      if z>= max
        kill i
      else
        _livingCells[i][2] = z+1
    else
      _livingCells.push [x,y,0]
      _bbox=null
    this

    
  paste = (pattern, z)->
    for [x,y] in pattern.cells
      i = indexOf x,y
      if i?
        _livingCells[i][2]=z
      else
        _livingCells.push [x,y,z]
    _bbox=null

  copy = (spec)->
    bbox = new BBox spec
    cells = ([x,y] for [x,y] in _livingCells when bbox.includes [x,y])
    new Pattern cells

  cut = (spec)->
    bbox = new BBox spec
    remaining =  []
    deleted = []
    for [x,y,z] in _livingCells
      if bbox.includes [x,y]
        deleted.push [x,y]
      else
        remaining.push [x,y,z]
    _livingCells = remaining
    _bbox = null
    new Pattern deleted

  neighbours = ([x,y])->
    [
      [x-1,y-1], [x,y-1], [x+1,y-1]
      [x-1,y],            [x+1,y]
      [x-1,y+1], [x,y+1], [x+1,y+1]
    ]
  next = ()->
    #FIXME: this code assumes that only colors 0 and 1 are used!!
    counters={} #"x,y" : [[x, y], counterA, counterB ]
    live={} # "x,y": color

    # We are only interested in cells that have living neighbours *now*.
    # (Remember that cells without living neighbours do not live in the next
    # generation.) Since neighbourhood is symmetric, we can simply iterate the
    # neighbours of all living cells.  For these cells, we accumulate two
    # counters, one for each color. I.e. for each neighbour n and each color c,
    # we count how many times the n was found when expanding the neighbourhood
    # of a living cell of color c.
    #
    # We also build a hash table for quickly looking up the color of all cells
    # that are currently alive.
    for [x,y,z] in _livingCells
      live[[x,y]]=z
      for neighbour in neighbours [x,y]
        if counters[neighbour]?
          counters[neighbour][1+z]++
        else
          counters[neighbour]=[neighbour,1-z,z]

    # Any cell that is alive in the next generation *does* have an entry in our
    # counters table.  So we run over the entries of our counters-table and
    # apply the usual GoL ruleset.  For determining the color of newborn cells,
    # we use the "Immigration" rule (also known as "Black and White").
    nextCells = []
    for _,[cell,colorA,colorB] of counters
      z = live[cell]
      livingNeighbours = colorA + colorB

      #  +--- dead cell is  reborn---+      +--- living cell survives ---------+
      #  |     (if z is undefined)   |      |                                  |
      if   livingNeighbours == 3        or    z? and 2 <= livingNeighbours <=3
        z = z ? (if colorA > colorB then 0 else 1)
        [x,y] = cell
        nextCells.push [x,y,z]

    Board nextCells

  livingCells:livingCells
  bbox:bbox
  alive:alive
  toggle:toggle
  cycle:cycle
  asciiArt: (extent)->
    AsciiArt.render _livingCells, extent:extent
  next:next
  paste:paste
  copy:copy
  cut:cut

Board.fromMatch = (mdoc)->
  board = Board([])
  p1 = new Pattern mdoc.pattern1.base64String
    .similarPatterns()[mdoc.pattern1.variant]
    .translate mdoc.pattern1.translation
  p2 = new Pattern mdoc.pattern2.base64String
    .similarPatterns()[mdoc.pattern2.variant]
    .translate mdoc.pattern2.translation

  board.paste p1,0
  board.paste p2,1
  board

module.exports= Board
