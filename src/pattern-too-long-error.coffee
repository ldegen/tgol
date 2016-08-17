module.exports = class PatternTooLongError extends require "./domain-error"
  constructor: ()->
    super(400,"Pattern to long (too many living cells)")
