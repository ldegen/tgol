merge = require "deepmerge"
Bbox = require "./bbox" 
module.exports =
  render: (cells,opts0={})->
    defaults =
      colorChars: "*o"
      emptyChar:'_'
      extent:{}
    opts = merge defaults, opts0
    {left,top,right,bottom} = merge new Bbox(cells), opts.extent ? {}
    color = (x,y)->
      return c ? 0 for [a,b,c] in cells when a==x and b==y
    alive = (x,y)->
      return color(x,y)?
    char = (x,y)->
      c=color x,y
      if c? then opts.colorChars[c] else opts.emptyChar

    ( for y in [top...bottom]
        ( for x in [left...right]
            char(x,y)+'|'
        ).join ''
    ).join '\n'

  parse: (s,opts0={})->
    defaults =
      parseColors:false
      colorChars: "*o"
      emptyChar:'_'
    opts = merge defaults, opts0
    cells = []
    rows = s
      .replace /\|/g, ''
      .split '\n'
    for row,y in rows
      for char,x in row
        if char != opts.emptyChar
          if opts.parseColors
            cells.push [x,y,opts.colorChars.indexOf(char)] 
          else
            cells.push [x,y]
    cells
