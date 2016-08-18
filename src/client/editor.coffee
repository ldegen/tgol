{div,factory} = require "../react-utils"
React = require "react"
Visualization = factory require "./visualization"
Panel = factory require "./panel"
Dispatcher = require "../dispatcher"
Board = require "../board"
Pattern = require "../pattern"
class Editor extends React.Component
  constructor: (props)->
    super props
    board = Board  """
    _|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|o|*|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|o|*|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|*|_|_|_|_|*|_|_|_|_|_|_|_|_|_|_|*|o|_|_|_|_|_|_|*|*|
    _|_|_|_|_|_|_|_|o|_|*|_|_|_|_|*|_|_|_|_|_|_|_|_|_|_|*|o|o|_|_|_|_|_|*|*|
    *|*|_|_|_|_|*|o|_|_|_|_|_|_|_|*|_|_|_|_|_|_|_|_|_|_|*|o|_|_|_|_|_|_|_|_|
    *|*|_|_|_|_|*|o|_|_|_|_|_|_|_|_|_|_|_|o|o|_|_|o|*|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|*|o|_|_|_|_|_|_|_|_|*|*|_|_|o|_|_|o|*|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|o|_|*|_|_|_|_|_|*|*|*|*|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
    _|_|_|_|_|_|_|_|_|_|*|_|_|_|_|_|_|_|o|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
    """
    @state=
      livingCells: board.livingCells()
      mode:"edit"
      window:
        top:0
        left:0
        bottom:10
        right:10
      selection:null
      pattern:null
      translate: [0,0]
      lru:[]
    @bus = Dispatcher()




    @play=
      name: "play"
      icon: "play.svg"
      action: =>
        @setState {mode:"play"}, @tick
    @back=
      name: "back"
      icon: "back.svg"
      action: => @setState 
        mode:"edit"
        selection:null
        pattern:null
    @fit=
      name: "fit"
      icon: "fit.svg"
      action: =>
        @setState window: @board().bbox()

    @select=
      name: "select",
      icon: "view-zoom-fit-symbolic.svg"
      action: (ev)=>
        @setState {mode:"select"}
    @copy=
      name: "copy"
      icon: "copy.svg"
      action: => 
        [[l,t],[r,b]] = @state.selection
        pattern = @board()
          .copy left:l,top:t,right:r,bottom:b
        @setState 
          mode: "pattern"
          pattern: pattern.cells
          translate: [0,0]
          selection: null
    @cut=
      name: "cut"
      icon: "cut.svg"
      action: => 
        [[l,t],[r,b]] = @state.selection
        box = {left:l,top:t,right:r,bottom:b}
        board = @board()
        pattern = board.cut box
        @setState 
          mode: "pattern"
          pattern: pattern.cells
          livingCells: board.livingCells()
          translate: [0,0]
          selection: null
    @paste=
      name: "paste"
      icon: "none"
      action: =>
        board = @board()
        pattern = new Pattern @patternCells()
        board.paste pattern, Math.round Math.random()
        @setState
          livingCells: board.livingCells()
    @details =
      name: "details"
      icon: "details.svg"
      link: =>
        pattern = new Pattern @patternCells()
        "patterns/"+encodeURIComponent pattern.minimize().encodeSync()
        

    commands=
      edit:[@play,@select, @fit ]
      select:[@copy, @back]
      pattern:[@back,@details]
      play:[@back, @fit]
    

    @tick= =>
      if @state.mode == "play"
        b=@board().next()
        @setState
          livingCells:b.livingCells()
          window: if b.livingCells().length>0 then b.bbox()
          ()=>window.requestAnimationFrame(@tick)

    @board= -> Board @livingCells()
    @topCommands= -> []
    @bottomCommands= ->commands[@state.mode] ? []
    @bus("selectionDone").onValue (ev)=>
      if not ev?
        @back.action()
      else
        @cut.action()
    @bus("toggle").onValue ([x,y]) =>
      @setState
        livingCells:
          @board()
            .toggle x,y,Math.round Math.random()
            .livingCells()
    @bus("zoom").onValue (window)=>
      @setState window:window
    @bus("selection").onValue (selection)=>
      @setState selection:selection
    @bus("drag").onValue (t)=>
      @setState translate:t
    @bus("drop").onValue (t)=>
      @setState 
        translate:[0,0]
        pattern: @patternCells t
    @bus("tap-pattern").onValue =>
      @paste.action()
  livingCells: ->
    @state.livingCells
  patternCells: (tl)->
    if @state.pattern?
      [dx,dy] = tl ? @state.translate
      new Pattern @state.pattern
        .translate dx,dy
        .cells
  render: ->
    (div className:"layout",
      (div id:"top-panel", className:"panel top",
        (Panel bus:@bus, commands: @topCommands())
      )
      (div id:"main-area", className:"main",
        Visualization
          bus:@bus
          livingCells:@livingCells()
          mode:@state.mode
          window:@state.window
          selection:@state.selection
          pattern:@state.pattern
          translate:@state.translate
      )
      (div id:"bottom-panel", className:"panel bottom",
        (Panel bus:@bus, commands: @bottomCommands())
      )
    )
  componentDidMount: ->
    console.log "mounted"
    s = localStorage.getItem "tgol.editor.state"
    if s?
      console.log "loading", s
      @setState JSON.parse s

  componentWillUnmount: ->
    s = JSON.stringify @state
    console.log "saving", s
    localStorage.setItem "tgol.editor.state", s

module.exports = Editor
