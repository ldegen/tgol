React = require "react"
qr = require "qr-image"
Pattern = require "../pattern"
{label, h1,h2,ul,li,p,div,factory,input, button, span, img} = require "../react-utils"
Promise = require "bluebird"
request = Promise.promisify require "request"

Visualization = factory require "./visualization"
module.exports = class PatternDetail extends React.Component
  constructor: (props)->
    super props

    @state =
      name:""
      author:""
      mail:""
      pin:""
      elo:""
      status: "loading"

  componentWillReceiveProps: (newProps)->
    @fetchPatternInfo(newProps.params.spec) if newProps.params.spec != @props.params.spec
  componentDidMount: -> @fetchPatternInfo(@props.params.spec)
  fetchPatternInfo: (spec)->
    request "#{location.origin}/api/froscon2016/patterns/#{encodeURIComponent spec}"
      .then (resp)=>
        console.log "resp", resp
        @handleServerResponse resp

  handleUserInput: (name)->(ev)=>
    @setState "#{name}": ev.target.value

  handleServerResponse: (resp)=>
    @transition("response", resp)

  handleNavEvent: (name)->(ev)=>
    @transition(name,ev)

  transition: (event, data)->
    sourceState = @steps[@state.status]
    result = sourceState[event]?.call(this,data) ? @state.status
    if typeof result == "string"
      result = status: result
    targetName = result.status
    console.log "transition", @state.status, event, targetName 
    targetState = @steps[targetName]
    targetState.enter?(data)
    @setState result


  render: ->@steps[@state.status].render.call this

  labelValue: (label, value)->
    div
      className: "label-value"
      span
        className: "label"
        label
      span
        className: "value"
        value
  checkbox: (name, labelText)=>
    div(
      input
        type:"checkbox"
        name:name
        id:name
        value: @state[name]
        onChange: @handleUserInput(name)
      label htmlFor:name, labelText
    )
  textInput: (name, label)=>
    input
      type:"text"
      placeholder:label
      name:name
      value: @state[name]
      onChange: @handleUserInput(name)
  navButton: (name, label)->
    button
      value:"name"
      onClick: @handleNavEvent name
      label


  steps:
    error:
      render: ->
        div(
          h1 ":-( Stop Dave, I'm afraid..."
        )
    qr:
      render: ->
        img
          className: "qr-code"
          src:"data:image/png;base64," + qr.imageSync( window.location.toString(), type:"png").toString("base64")
    loading:
      response: (resp)->
        switch resp.statusCode
          when 404
            "unknown"
          when 200
            body = JSON.parse resp.body
            body.status = "known"
            body
          else
            "error"
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          h1 "Looking up Pattern..."

          Visualization
            livingCells:pattern.cells
            window:pattern.bbox()
        )
    submitting:
      response: (resp)->
        switch resp.statusCode
          when 400
            switch resp.body.type
              when "EmailAlreadyRegisteredError"
                "confirmOverwrite"
              else
                "error"
          when 401
            "badPIN"
          when 200
            body = resp.body
            body.status = "known"
            body
          else
            "error"
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          h1 "Uploading Pattern..."

        )

    unknown:
      submit: -> "submit"
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          h1 "(Yet) Unknown Pattern"

          Visualization
            livingCells:pattern.cells
            window:pattern.bbox()
          div
            className: "field-group"
            @textInput "name", "Name"
            @textInput "author", "Author"
            @labelValue "Status:", @state.status
            @labelValue "Cells:", pattern.cells.length
            @labelValue "Dimensions:", pattern.bbox().width()+" x "+pattern.bbox().height()
            @navButton "submit", "Submit for Tournament"
        )
    known:
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          h1 "Pattern: #{@state.name}"
          h2 "by: #{@state.author}"

          Visualization
            livingCells:pattern.cells
            window:pattern.bbox()
          div
            className: "field-group"
            @labelValue "Cells:", pattern.cells.length
            @labelValue "Dimensions:", pattern.bbox().width()+" x "+pattern.bbox().height()
        )
    confirmOverwrite:
      render: ->
        div(
          h1 "Confirm Overwrite"
        )
    badPIN:
      render: ->
        div(
          h1 "Bad PIN"
        )
    submit:
      submit: ()->
        request
          url: "#{location.origin}/api/froscon2016/patterns"
          method: "POST"
          json:pdoc:
            name: @state.name
            author: @state.author
            mail: @state.mail
            base64String:@props.params.spec
            pin: @state.pin
         .then @handleServerResponse, @handleError
         "submitting"
      render: ->
        div(
          h1 "Please authenticate"
          div
            className: "field-group"
            @textInput "mail", "Email"
            @textInput "pin", "PIN"
            ul
              li """
                 Mit der Teilnahme am Wettbewerb bestätigst Du, dass
                 wir dich unter dieser Adresse kontaktieren dürfen, z.B. um dich über Gewinne sowie das Endergebnis
                 des Wettbewerbs zu benachrichtigen. Wir verwenden diese Adresse
                 ausschließlich im Rahmen dieses Wettbewerbs und geben Sie nicht an
                 Dritte weiter.
                 """
              li """
                 Die Emailadresse verwenden wir zum Identifizieren des Autors eines Musters.
                 Jedes Muster ist fest einer Emailadresse zugeordnet.
                 Es kann immer nur ein Muster gleichzeitig mit dieser Emailadresse verwendet werden.
                 Wenn du das erste mal ein Muster mit dieser Adresse anmeldest, legst du eine PIN fest.
                 Du musst die selbe PIN angeben, wenn du später das mit der Emailadresse verknüpfte Muster ersetzen möchtest.
                 Das ist während der gesamten Laufzeit des Wettbewerbs möglich.
                 """
            @checkbox "agree", "Ich verstehe und bin einverstanden."
            @navButton "submit", "Upload"
        )
