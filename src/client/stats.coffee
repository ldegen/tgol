{div,factoryi, span,h1,h2} = require "../react-utils"
React = require "react"
module.exports = class Stats extends React.Component
  constructor: (props)->
    super props
  renderPlayer: (i)->
    p = @props.patterns?[i]
    div className: "player-#{i+1}",
      div className: "player-name",
        h1 p?.name ? "???"
        h2 "by #{p?.author ? "???"}"
      div className: "player-score",
        span p?.score?.toFixed(2) ? "???"

  render: ->
    
    (div className: "stats",
      @renderPlayer 0
      div className: "generation",
        span className:"label", "Generation"
        span className:"value", @props.generation
      @renderPlayer 1
    )
    
