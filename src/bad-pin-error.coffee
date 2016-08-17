module.exports = class BadPinError extends require "./domain-error"
  constructor: ()->
    super(401,"PIN does not match that of the existing pattern")
