React = require "react"
{div,p,table,h1,thead,tbody,tr,th,td,img,footer,factory,span} = require "../react-utils"
Promise = require "bluebird"
request = Promise.promisify require "request"
Util = require "../util"
Visualization = factory require "./visualization"
Bbox = require "../bbox"
{Link} =  require "react-router"
Link = factory Link
module.exports = class Leaderboard extends React.Component


  constructor: (props)->
    super props
    @state =
      scores:[]
  
  tableRow: (row)->
    cells = Util
      .cells row.base64String
      .map ([x,y])->[x,y,0]
    tr key:row.base64String,
      td( 
        span className:"name", row.name
        span className:"author", "by #{row.author}"
      )
      td row.games
      td row.score
      td(
        Link to: "/patterns/"+encodeURIComponent( row.base64String),
          Visualization
            livingCells:cells
            mode:"play"
            window: new Bbox cells 
      )
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
    div className: "leaderboard",
      div className: "header",h1 "GoL-Contest Leaderboard"
      div className:"background_container",
        div className:"wrapper",
          table id:"leaderboard",className:"pure-table pure-table-horizontal",
            thead className:"leaderHead",
              tr className:"leaderHeadRow",
                th className:"leaderHeadCell", "Name"
                th className:"leaderHeadCell", "Games played"
                th className:"leaderHeadCell", "Score"
                th className:"leaderHeadCell", "Pattern"
            tbody className:"leaderBody",
              (@tableRow row for row in @state.scores)
        footer(
          p className:"footer_paragraph",
            "Made by"
            img src:"/images/tarentLogoWeiss_12px.png"
            "2016"
        )
