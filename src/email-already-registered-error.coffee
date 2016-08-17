
module.exports = class EmailAlreadyRegisteredError extends require "./domain-error"
  constructor: ()->
    super(400,"Email already registered")
