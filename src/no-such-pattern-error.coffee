module.exports = class NoSuchPatternError extends require "./domain-error"
  constructor: ()->
    super(404,"No such Pattern")
