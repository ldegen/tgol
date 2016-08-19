Bacon = require "baconjs"
React = require "react"
d3 = require "d3-selection"
d3Zoom = require "d3-zoom"
d3Brush = require "d3-brush"
d3Drag = require "d3-drag"

{div} = require "../react-utils"
fit = require "./fit-viewport"
debugPoint = require "./debug-point"
renderCells = require "./render-cells"
class Visualiztation extends React.Component
  constructor: (props)->

    @state =
      selection:null

    super props
    zoom = d3Zoom.zoom()
    drag = d3Drag.drag()
    brush = d3Brush.brush()

    #workaround for https://github.com/d3/d3-brush/issues/13
    brush.extent [[0,0],[9999,9999]]
    touchSupported = ->
      msTouchEnabled = window.navigator.msMaxTouchPoints
      generalTouchEnabled = 'ontouchstart' of document.createElement('div')
      msTouchEnabled or generalTouchEnabled

    muted = false
    @mute = ->muted=true
    @unmute = ->muted=false
    eventStream = (sel, name)->
      Bacon.fromBinder (sink)->
        sel.on name, (d,i,group) ->
          sink d3.event if not muted
        -> sel.on "name",null




    @viewport = ->
      [width,height] = @state.size
      {left,top,bottom,right} = @props.margin
      left: left
      top: top
      right: width-right
      bottom: height-bottom

    @transform = ->
      {scale:k, translate:[x,y]} = fit @props.window, @viewport()
      d3Zoom.zoomIdentity.translate(x,y).scale(k)
    @create = ->

      root = @getDOMNode()
      bus = @props.bus
      svg = d3.select root
        .append "svg"

      mouseCatcher = svg.append "rect"
        .classed "mouse-catcher", true
        .attr "x",0
        .attr "y",0
        .attr "width",1000
        .attr "height",1000
        .style "fill", "yellow"
        .style "opacity", 0
        .style "stroke", "magenta"
        .style "stroke-width", 15
      canvas = svg.append "g"
        .classed "canvas", true
      patternLayer = svg.append "g"
        .classed "pattern", true

      if bus?
        @wireGestures bus

      set = (property)->(obj0,value)->

        obj = {}
        obj[k]=v for k,v of obj0
        obj[property]=value
        obj

      identity = (obj)->obj
      resizeEvents = eventStream d3.select(window), "resize"
        .map ()->
          {width, height} = svg.node().getBoundingClientRect()
          [width,height]

      Bacon.update(
        @state,
        #[zoomEvents], set "zoomTransform"
        #[brushEvents], set "selection"
        [resizeEvents], set "size"
      ).onValue (v)=> @setState v


      {width,height} = svg.node().getBoundingClientRect()
      @setState size: [width,height]
      svg.call zoom
      patternLayer.call drag

    @wireGestures = (bus)->
      root = @getDOMNode()
      svg = d3.select(root).select("svg")
      patternLayer = svg.select("g.pattern")
      zoomEvents = eventStream zoom, "zoom.tgol"
        .filter =>@props.mode == "edit" or @props.mode == "pattern"
        .map (ev)=>
          t=ev.transform
          {top,left,bottom,right} = @viewport()
          worldWindow = {}
          [worldWindow.left,worldWindow.top] = t.invert [left,top]
          [worldWindow.right,worldWindow.bottom] = t.invert [right,bottom]
          worldWindow

      dragTransform = (ev)=>
        t=@transform()
        {x:x0,y:y0}=ev.subject
        {x,y}=ev
        [x0,y0] = t.invert([x0,y0]).map Math.floor
        [x,y] = t.invert( [x,y]).map Math.floor
        [x-x0,y-y0]

      dropEvents = eventStream drag, "end.tgol"
        .filter => @props.mode == "pattern"
        .map dragTransform

      dragEvents = eventStream drag, "drag.tgol"
        .filter => @props.mode == "pattern"
        .map dragTransform
        .skipDuplicates (a,b)->not a? and not b? or a? and b? and a.toString() == b.toString()
      
      
            

      tapEvents = (start, move, end)->
        #a property that is true when start is followed by move
        dragging = move.awaiting start
        #a tap is happens when an end event accurs while not dragging
        end.filter dragging.not()


      unprojectSelectionEvent = (ev)=>
        t = @transform()
        ev.selection?.map (p,i)->t.invert( p).map (c)->Math.round(c)

      brushEvents = eventStream brush, "brush.tgol"
        .filter =>@props.mode == "select"
        .map unprojectSelectionEvent
        #.skipDuplicates (a,b)->
          #a? and b? and a.toString() == b.toString()

      brushDoneEvents = tapEvents(
        eventStream brush, "start.tgol"
        brushEvents
        eventStream brush, "end.tgol"
      ).map unprojectSelectionEvent

      toggleEvents = undefined
      if touchSupported()
        touchStart = eventStream svg, "touchstart.tgol"
        touchMove = eventStream svg, "touchmove.tgol"
        touchEnd = eventStream svg, "touchend.tgol"

        toggleEvents = tapEvents touchStart, touchMove,touchEnd
          .flatMap (ev)->
            {top,left}=svg.node().getBoundingClientRect()
            Bacon.fromArray ([touch.clientX-left,touch.clientY-top] for touch in event.changedTouches)
      else
        toggleEvents = eventStream svg, "click.tgol"
          .map (ev)->
            {top,left}=svg.node().getBoundingClientRect()
            [ev.clientX-left,ev.clientY-top]
      toggleEvents = toggleEvents
        .filter =>@props.mode == "edit"
        .map (p)=>@transform().invert(p).map Math.floor

      bus("toggle").plug toggleEvents
      bus("zoom").plug zoomEvents
      bus("drag").plug dragEvents
      bus("drop").plug dropEvents
      bus("selection").plug brushEvents
      bus("selectionDone").plug brushDoneEvents
      bus("tap-pattern").plug eventStream patternLayer, "click"
    @destroy = ->
      #TODO: unwire gestures!
    @update = ->
      root = @getDOMNode()
      svg = d3.select(root).select("svg")
      canvas = svg.select("g.canvas")
      patternLayer = svg.select("g.pattern")

      {mode, livingCells,selection, pattern,translate} = @props
      zoomTransform = @transform()
      svg
        #.transition()
        #.duration 500
        .call zoom.transform, zoomTransform
        #.on "end", => @unmute "zoom.tgol"
      renderCells canvas, livingCells, [zoomTransform], selection
      [tx,ty]=translate
      renderCells patternLayer, pattern ? [], [zoomTransform,d3Zoom.zoomIdentity.translate(tx,ty)], null

      # manage the selection brush:
      #
      # select all brushes (of course there will be at most one!)
      # and bind to an array containing a single element if there is
      # a selection or none if there is no selection.
      selectionUi = svg
        .selectAll "g.brush"
        .data [1].filter ->mode=="select"

      transformedSelection = selection?.map (p)->zoomTransform.apply p
      # create a new selection widget if needed
      newSelectionUi = selectionUi.enter()
        .append "g"
        .attr "class", "brush"
        .call brush
      # update the selection widget to represent the actual selection state
      if transformedSelection?
        newSelectionUi
          .call brush.move, transformedSelection.slice() 
        #FIXME: in principle, we want to update the brush widget here, too
        #  it does not work for some reason I haven't yet figured out.
        #selectionUi.call brush.move, transformedSelection.slice()


      # remove the widget if it is not used any more
      selectionUi.exit()
        .remove()

      #{top:wt,left:wl,bottom:wb,right:wr}= @props.window
      #debugPoint canvas, [[wl,wt],[wr,wb]], "window"
      #debugPoint canvas, selection, "selection"
  @defaultProps:
    mode:"edit"
    # these are world coordinates, but not necessarily integers.
    # Example:
    # Assuming a matrix of 10x10 cells, if we set bottom to 9.5,
    # only the half of the bottom row will be visible.
    window:
      top:0.0
      left:0.0
      bottom:10.0
      right:10.0
    margin:
      top:15
      left:15
      bottom:15
      right:15
    livingCells:[]
    selection:null
    translate:[0,0]

  getDOMNode:->
    require("react-dom").findDOMNode this

  render: ->
    div className:"d3wrapper"
  componentDidMount: ->
    @create()
  componentDidUpdate: ->
    @mute()
    @update()
    @unmute()
  componentWillUnmount: ->
    @destroy()

module.exports = Visualiztation
