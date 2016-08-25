React = require "react"
{div,p,table,h1,thead,tbody,tr,th,td,img,footer,factory,span} = require "../react-utils"
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
  
  tableRow: (row)->
    cells = Util
      .cells row.base64String
      .map ([x,y])->[x,y,0]
    div id: row.base64String, key:row.base64String,
      div(
        span className:"base64String", row.base64String
        span className:"name", row.name
        span className:"author", "by #{row.author}"
      )
      Link to: "/patterns/"+encodeURIComponent( row.base64String),
        Visualization
          livingCells:cells
          mode:"play"
          window: new Bbox cells 
      
  componentDidMount: ->
    @updateScores()
    @_interval = setInterval @updateScores, 1000
  componentWillUnmount: ->
    clearInterval @_interval
  updateScores: =>
    request location.origin + "/api/froscon2016/leaderboard"
      .then (resp)=>
        @setState scores:JSON.parse resp.body
  render: ->
    div className: "svgs",
      (@tableRow row for row in @state.scores)
