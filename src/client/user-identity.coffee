React = require "react"
{h1,div,factory,input, button} = require "../react-utils"
kbpgp = require "kbpgp"
Promise = require "bluebird"

class UserIdentity extends React.Component
  constructor: (props)->
    super props


  #render: ->
  #  switch @state.state
  #    when "loading"
  #      span className="message spinner", "loading..."
  #    when "generating"
  #      span className="message spinner", "generating key pair..."
  #    when "missing"
  #      div "userid input-group"
  #        input type:text, placeholder: "User ID",
  #        button "Create"
  #    when "ready"
  #      span className="userid", @state.userId
