
{div,factory} = require "../react-utils"
React = require "react"
Visualization = factory require "./visualization"
Panel = factory require "./panel"
Dispatcher = require "../dispatcher"
Board = require "../board"
Stats = factory require "./stats"
Placement = require "../placement"
Pattern = require "../pattern"
Promise = require "bluebird"
request = Promise.promisify require "request"
merge = require "deepmerge"
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
    box = board.bbox()
    return "" if not box?
    {left, top} = box
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
    if @state.generation < 400 && not visited[key]
      visited[key] = true
      b=b.next()
      delay = (300 / (1 + Math.sqrt( @state.generation)))
      @setState ((prev, props)->
        score = (i)->
          pat = prev['pattern'+(i+1)]
          live = b
            .livingCells()
            .filter ([x,y,z])->z==i
            .length
          pat.score + live / pat.initialSize
        visited: visited
        generation: prev.generation + 1
        livingCells:b.livingCells()
        window: if b.livingCells().length>0 then b.bbox()
        pattern1: merge prev.pattern1, score: score 0
        pattern2: merge prev.pattern2, score: score 1

      ), ()=>
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
        mdoc = Placement(distance:2).matchTemplate(p1,p2)
        b = Board.fromMatch mdoc
        @setState
          livingCells: b.livingCells()
          window: if b.livingCells().length>0 then b.bbox()
          visited: {}
          match: mdoc
          pattern1:
            name:pdoc1.name
            author:pdoc1.author
            score:1
            initialSize:p1.cells.length
          pattern2:
            name:pdoc2.name
            author:pdoc2.author
            score:1
            initialSize:p2.cells.length
          @play

  matchOver: ->
    tournamentPin = localStorage.getItem 'tgol.froscon2016.secret'
    if tournamentPin != undefined
      request
        url: location.origin + "/api/froscon2016/matches"
        method:"POST"
        json: 
          mdoc: merge @state.match,
            pattern1:score: @state.pattern1.score
            pattern2:score: @state.pattern2.score
          pin:tournamentPin
      .then =>@prepareMatch()
    else
      =>@prepareMatch()

  componentDidMount: ->
    @prepareMatch()

  render: ->
    (div className:"layout arena application",
      #(div id:"top-panel", className:"panel top",
        #(Panel bus:@bus, commands: @topCommands())
      #)
      (div id:"main-area", className:"main arena",
        Visualization
          livingCells:@livingCells()
          mode:"play"
          window:@state.window
      )
      (div id:"bottom-panel", className:"panel bottom arena",
        Stats patterns:[@state.pattern1,@state.pattern2], generation:@state.generation, livingCells: @state.livingCells
      )
    )
