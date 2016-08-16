module.exports = class NoSuchPatternError extends Error
  constructor: ()->
    super("No such Pattern")
