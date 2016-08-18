
{div,factory} = require "../react-utils"
React = require "react"
Visualization = factory require "./visualization"
Panel = factory require "./panel"
Dispatcher = require "../dispatcher"
Board = require "../board"
Placement = require "../placement"
Pattern = require "../pattern"
Promise = require "bluebird"
request = Promise.promisify require "request"
module.exports = class Arena extends React.Component
  constructor: (props) ->
    super props
    @state =
      livingCells:[]
      generation:0
      window:
        top:0
        left:0
        bottom:10
        right:10
  fit: -> 
    @setState window: @board().bbox()
  play: ->
    @setState generation:0, @tick
 
  _key: (board)->
    {left, top} = board.bbox()
    board.livingCells()
      .map ([x,y,z])->[x-left, y-top,z]
      .sort ([ax,ay],[bx,b_y])->
        if ax != bx
          ax-bx
        else
          ay-b_y
      .toString()


  livingCells: ->@state.livingCells
  board:-> Board @livingCells()
  tick: =>
    b=@board()
    key = @_key b
    visited = @state.visited
    if @state.generation < 200 && not visited[key]
      visited[key] = true
      b=b.next()
      delay = (300 / (1 + Math.sqrt( @state.generation)))
      @setState
        visited: visited
        generation: @state.generation + 1
        livingCells:b.livingCells()
        window: if b.livingCells().length>0 then b.bbox()
        ()=>
          window.setTimeout(
            =>window.requestAnimationFrame(@tick)
            delay
          )
    else
      @matchOver()
  prepareMatch: ->
    request location.origin + "/api/froscon2016/matchmaker"
      .then (resp)=>
        [pdoc1, pdoc2] = JSON.parse resp.body
        p1 = new Pattern pdoc1.base64String
        p2 = new Pattern pdoc2.base64String
        mdoc = Placement(distance:5).matchTemplate(p1,p2)
        b = Board.fromMatch mdoc
        @setState 
          livingCells: b.livingCells()
          window: if b.livingCells().length>0 then b.bbox()
          visited: {}
          @play
        
  matchOver: ->
    @prepareMatch() 
  componentDidMount: ->
    @prepareMatch()

  render: ->
    (div className:"layout",
      #(div id:"top-panel", className:"panel top",
        #(Panel bus:@bus, commands: @topCommands())
      #)
      (div id:"main-area", className:"main arena",
        Visualization
          livingCells:@livingCells()
          mode:"play"
          window:@state.window
      )
      #(div id:"bottom-panel", className:"panel bottom",
        #(Panel bus:@bus, commands: @bottomCommands())
      #)
    )
