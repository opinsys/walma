
{EventEmitter} = require "events"

class exports.Client extends EventEmitter

  timeoutTime: 1000 * 5

  constructor: (@_socket, opts) ->
    super
    @id = opts.id
    @userAgent = opts.userAgent

    @state = "created"

    @_socket.on "state", (state) =>
      @state = state
      @emit "state", state, @

    @_socket.on "draw", (draw) =>
      @emit "draw", draw

    @_socket.on "disconect", =>
      console.log "Disconnect: #{ @userAgent }"
      @emit "disconect", @

  startWith: (history) ->
    console.log "starting with 2", history
    @_socket.emit "start", history

  fetchBitmap: (cb) ->
    timeout = false
    setTimeout ->
      timeout = true
      cb message: "Fetching timeout", reason: "timeout"
    , @timeoutTime

    @_socket.once "bitmap", (data) ->
      cb null, data unless timeout

    @_socket.emit "getbitmap"




