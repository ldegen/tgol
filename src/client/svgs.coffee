React = require "react"
{a,div,p,table,h1,thead,tbody,tr,th,td,img,footer,factory,span} = require "../react-utils"
Promise = require "bluebird"
request = Promise.promisify require "request"
Util = require "../util"
Visualization = factory require "./visualization"
Bbox = require "../bbox"
{Link} =  require "react-router"
Link = factory Link
module.exports = class Svgs extends React.Component


  constructor: (props)->
    super props
    @state =
      scores:[]
  
  tableRow: (row,i)->
    cells = Util
      .cells row.base64String
      .map ([x,y])->[x,y,0]
    div id: row.base64String, className: "slot", key:row.base64String,
      div className:"meta",
        span className:"position", i+1
        span className:"score", row.score
        span className:"base64String", row.base64String
        span className:"name", row.name
        span className:"author", "by #{row.author}"
      
      a href:"here goes data uri",
        Visualization
          livingCells:cells
          mode:"play"
          window: new Bbox cells 
          magicHook: @magic
      
  componentDidMount: ->
    @updateScores()
  updateScores: =>
    request location.origin + "/api/froscon2016/leaderboard"
      .then (resp)=>
        @setState scores:JSON.parse resp.body
  render: ->
    div className: "svgs",
      (@tableRow row,i for row,i in @state.scores)
  magic: =>
    # this is a hack!
    elms=Array.prototype.slice.call(document.getElementsByTagName("svg"))
    elms.forEach (svg)->
      a=svg.parentElement.parentElement
      a.href="data:image/svg+xml;base64,"+btoa(svg.outerHTML)
  #componentDidUpdate: => @magic()
