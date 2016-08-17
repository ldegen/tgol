module.exports = class BadPinError extends require "./domain-error"
  constructor: ()->
    super(404,"PIN does not match that of the existing pattern")
