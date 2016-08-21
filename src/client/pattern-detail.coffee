React = require "react"
qr = require "qr-image"
merge = require "deepmerge"
Pattern = require "../pattern"
{label, h1,h2,ul,li,p,div,factory,input, button, span, img} = require "../react-utils"
Promise = require "bluebird"
request = Promise.promisify require "request"
{Link} = require "react-router"
Link = factory Link

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
  linkButton: (to,label,opts={})->
    opts = to:to, className: "button"
    Link opts, label
  

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
          h1 "Bitte Pattern benennen"

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
            @navButton "submit", "Pattern an Server schicken", disabled: not @valid()
            @navButton "qr", "QR-Code anzeigen"
        )
    known:
      qr: -> "qr"
      render: ->
        pattern = new Pattern @props.params.spec

        div(
          className: "form"
          h1 "Dein Pattern nimmt jetzt am Turnier teil!"
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
            @linkButton "/editor?p=#{encodeURIComponent @props.params.spec}", "Kopieren"
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
            Da immer nur ein Muster pro Email-Adresse gleichzeitig am
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
        @state.mail.trim() and @state.pin.trim()
      render: ->
        div(
          className: "form"
          h1 "Am Turnier teilnehmen!"
          div
            className: "field-group"
            @textInput "mail", "Email"
            @textInput "pin", "PIN"
            ul
              li """
                 Wir speichern Eure E-Mail-Adresse ausschließlich, um Euch über die Ergebnisse des GoL-Contest zu infomieren!
                 """
                Link(
                  to:'http://www.tarent.de/GoL2016/datenschutz.html'
                  target:'_blank'
                  'Datenschutzerklärung') 
              li """
                 Darüber hinaus verwenden wir die E-Mail zum Identifizieren des Autors eines Musters. 
                 Jedes Muster ist fest einer E-Mail zugeordnet — es kann immer nur ein Muster pro E-Mail aktiv sein. 
                 Wenn du das erste mal ein Muster mit dieser E-Mail anmeldest, legst du eine PIN fest. 
                 Wenn du später das mit der E-Mail verknüpfte Muster ersetzen möchtest brauchst Du Deine PIN. 
                 Das ist während der gesamten Laufzeit des Wettbewerbs möglich.
                 """
              li """
                 Der Rechtsweg ist ausgeschlossen!
                 """
            @navButton "abort", "Zurück"
            @navButton "submit", "Ja, ich nehme teil!", disabled: not @valid()
        )
