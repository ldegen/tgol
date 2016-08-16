module.exports = ->
  Pattern = require "./pattern"
  
  validatePattern = (pdoc)->
    pattern = new Pattern(pdoc.base64String)
    if pattern.cells.length > 150
      false
    else
     true
    
  validatePattern:validatePattern