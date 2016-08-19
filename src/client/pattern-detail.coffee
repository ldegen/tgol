React = require "react"
qr = require "qr-image"
merge = require "deepmerge"
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
      agree:false
      status: "loading"

  componentWillReceiveProps: (newProps)->
    @reset newProps.params.spec if newProps.params.spec != @props.params.spec
  componentDidMount: ->
    @reset @props.params.spec

  handleUserInput: (name)->(ev)=>
    @setState "#{name}": ev.target.value

  handleServerResponse: (resp)=>
    @transition("response", resp)

  handleNavEvent: (name)->(ev)=>
    @transition(name,ev)

  reset: (data)->
    @setState status:"loading", =>@steps.loading.enter.call this, data

  transition: (event, data)->
    sourceState = @steps[@state.status]
    result = sourceState[event]?.call(this,data) ? @state.status
    if typeof result == "string"
      result = status: result
    targetName = result.status
    console.log "transition", @state.status, event, targetName
    targetState = @steps[targetName]
    @setState result , ->
      targetState.enter?.call this,data

  valid: -> @steps[@state.status].valid.call this
  render: ->
    div className: "pattern-details application",
      @steps[@state.status].render.call this

  labelValue: (label, value)->
    div
      className: "label-value"
      span
        className: "label"
        label
      span
        className: "value"
        value
  checkbox: (name, labelText,className)=>
    div(
      className: className
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
  navButton: (name, label, opts = {})->
    opts = merge opts,
      value:"name"
      onClick: @handleNavEvent name
    button opts, label

  

  steps:
    error:
      render: ->
        div(
          h1 ":-( Stop Dave, I'm afraid..."
        )
    qr:
      back: -> "loading"
      render: ->
        div(
          img
            className: "qr-code"
            src:"data:image/png;base64," + qr.imageSync( window.location.toString(), type:"png").toString("base64")
          @navButton "back", "Zurück"
        )
    loading:
      enter: (spec)->
        if typeof spec != "string"
          spec = @props.params.spec
        request "#{location.origin}/api/froscon2016/patterns/#{encodeURIComponent spec}"
          .then @handleServerResponse, @handleError
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
      enter: ->
        request
          url: "#{location.origin}/api/froscon2016/patterns"
          method: "POST"
          json:
            allowOverride: @state.allowOverride
            pdoc:
              name: @state.name
              author: @state.author
              mail: @state.mail
              base64String:@props.params.spec
              pin: @state.pin
         .then @handleServerResponse, @handleError
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
      qr: -> "qr"
      valid: ->
        @state.name.trim() and @state.author.trim()
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          className: "form"
          h1 "(Yet) Unknown Pattern"

          Visualization
            livingCells:pattern.cells
            window:pattern.bbox()
          div
            className: "field-group"
            @textInput "name", "Name"
            @textInput "author", "Autor"
            @labelValue "Status:", @state.status
            @labelValue "Cells:", pattern.cells.length
            @labelValue "Dimensions:", pattern.bbox().width()+" x "+pattern.bbox().height()
            @navButton "submit", "Am Tournier anmelden", disabled: not @valid()
            @navButton "qr", "QR-Code anzeigen"
        )
    known:
      qr: -> "qr"
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          className: "form"
          h1 "Pattern: #{@state.name}"
          h2 "by: #{@state.author}"

          Visualization
            livingCells:pattern.cells
            window:pattern.bbox()
          div
            className: "field-group"
            @labelValue "Cells:", pattern.cells.length
            @labelValue "Dimensions:", pattern.bbox().width()+" x "+pattern.bbox().height()
            @navButton "qr", "QR-Code anzeigen"
        )
    confirmOverwrite:
      submit: ()->
        # this will cause a re-submit but with the override flag set.
        status: "submitting"
        allowOverride: true
      abort: -> "submit"
      render: ->
        div(
          className: "form"
          h1 "Confirm Overwrite"
          p """
            Du hast bereits ein Muster mit dieser Email-Adresse verknüpft.
            Da immter nur ein Muster pro Email-Adresse gleichzeitig am
            Wettbewerb teilnehmen kann, wird das vorherige Muster abgemeldet.
            Dein Punktestand wird zurückgesetzt -- Du fängst also mit dem neuen
            Muster wieder ganz von vorne an.
            """
          p """
            Ist das ganz bestimmt das, was du willst?
            """
          @navButton "abort", "Nein, abbrechen!"
          @navButton "submit", "Ja, überschreiben."
          
        )
    badPIN:
      back: -> "submit"
      render: ->
        div(
          h1 "Bad PIN"
          @navButton "back", "zurück"
        )
    submit:
      enter: ->
        # *allways* reset the override flag so the user
        # gets an extra chance to opt out of overwriting her pattern
        @setState allowOverride:false
      submit: ()->
         "submitting"
      abort: -> "loading"
      valid: ->
        @state.mail.trim() and @state.pin.trim() and @state.agree
      render: ->
        div(
          className: "form"
          h1 "Wie erreichen wir Dich?"
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
            @checkbox "agree", "Ich verstehe und bin einverstanden.", "agree"
            @navButton "abort", "Nein, lieber nicht."
            @navButton "submit", "Tu es!", disabled: not @valid()
        )
