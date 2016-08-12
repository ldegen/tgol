React = require "react"
qr = require "qr-image"
Pattern = require "../pattern"
{h1,div,factory,input, button, span, img} = require "../react-utils"
kbpgp = require "kbpgp"
Promise = require "bluebird"
request = Promise.promisify require "request"

generate_rsa = Promise.promisify (options, callback)->
  kbpgp.KeyManager.generate_rsa options, callback
export_pgp_private = Promise.promisify (keyman, options, callback)->
  keyman.export_pgp_private options, callback
export_pgp_public = Promise.promisify (keyman, options, callback)->
  keyman.export_pgp_public options, callback
sign = Promise.promisify (keyman, options, callback)->
  keyman.sign options, (err)->callback err, keyman
options =
  userid: "John Doe <john.doe@tarent.de>"
  #primary:
  #  nbits: 4096
  #  flags: F.certify_keys | F.sign_data | F.auth | F.encrypt_comm | F.encrypt_storage
  #  expire_in : 0
#johnP = generate_rsa options
#  .then (john)-> sign john, {}

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
      status: "pending"

  componentWillReceiveProps: (newProps)->
    @fetchPatternInfo(newProps.params.spec) if newProps.params.spec != @props.params.spec
  componentDidMount: -> @fetchPatternInfo(@props.params.spec)
  fetchPatternInfo: (spec)->
    request "#{location.origin}/api/froscon2016/patterns/#{encodeURIComponent spec}"
      .then (resp)=>
        switch resp.statusCode
          when 404
            @setState status:"unknown"
          when 200
            body = JSON.parse resp.body
            body.status = "known"
            @setState body
          else
            @setState status:"error"
  uploadPattern: ()=>
    @setState status:"pending"
    request 
      url: "#{location.origin}/api/froscon2016/patterns"
      method: "POST"
      json:pdoc:
        name: @state.name
        author: @state.author
        mail: @state.mail
        elo:1000
        base64String:@props.params.spec
        pin: @state.pin
     .then (()=>@fetchPatternInfo @props.params.spec), (err)->@setState status:"error"

  handleUserInput: (name)->(ev)=>
    @setState "#{name}": ev.target.value

  render: ->
    pattern = new Pattern @props.params.spec

    labelValue = (label, value)->
      div
        className: "label-value"
        span
          className: "label"
          label
        span
          className: "value"
          value
    textInput = (name, label)=>
      input
        type:"text"
        placeholder:label
        name:name
        value: @state[name]
        onChange: @handleUserInput(name)
    div(
      h1 "Pattern Details"
      Visualization
        livingCells:pattern.cells
        window:pattern.bbox()
      img
        className: "qr-code"
        src:"data:image/png;base64," + qr.imageSync( window.location.toString(), type:"png").toString("base64")
      div
        className: "field-group"
        textInput "name", "Name"
        textInput "author", "Author"
        textInput "mail", "Email"
        textInput "pin", "PIN"
        labelValue "Status:", @state.status
        labelValue "Cells:", pattern.cells.length
        labelValue "Dimensions:", pattern.bbox().width()+" x "+pattern.bbox().height()
        button
          value:"claim!"
          onClick: @uploadPattern
          "Upload!"
    )
