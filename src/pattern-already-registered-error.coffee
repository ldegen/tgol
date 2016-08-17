module.exports = class PatternAlreadyRegisteredError extends require "./domain-error"
  constructor: ()->
    super(400,"Pattern already registered")
