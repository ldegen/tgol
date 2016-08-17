module.exports = class DomainError extends Error
  constructor: (code, msg)->
    super msg
    @code=code
    @message=msg
    @name=@constructor.name
