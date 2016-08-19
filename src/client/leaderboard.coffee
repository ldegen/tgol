React = require "react"
{div,p,table,h1,thead,tbody,tr,th,td,img,footer} = require "../react-utils"

module.exports = class Leaderboard extends React.Component


  constructor: (props)->
    super props
    @state =
      rows:[
        author: "Roman"
        games: 10
        score:1010
        base64String: "lalala"
      ,
        author: "Roman"
        games: 10
        score:1010
        base64String: "lalelu"
      ,
        author: "Roman"
        games: 10
        score:1010
        base64String: "lumpi"
      ]
  
  tableRow: (row)->
    tr key:row.base64String,
      td row.author
      td row.games
      td row.score
      td row.base64String
    
  render: ->
    div className: "leaderboard",
      div className:"background_container",
        div className:"wrapper",
          h1 "Leaderboard"
          table id:"leaderboard",className:"pure-table pure-table-horizontal",
            thead className:"leaderHead",
              tr className:"leaderHeadRow",
                th className:"leaderHeadCell", "Name"
                th className:"leaderHeadCell", "Games played"
                th className:"leaderHeadCell", "Score"
                th className:"leaderHeadCell", "Pattern"
            tbody className:"leaderBody",
              (@tableRow row for row in @state.rows)
          footer(
            p className:"footer_paragraph",
              "Made by"
              img src:"/images/tarentLogoWeiss_12px.png"
              "2016"
          )
