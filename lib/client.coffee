_  = require 'underscore'
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
      console.log "Disconnect: #{ @id }"
      @emit "disconect", @

  join: (roomName) ->
    @_socket.join roomName

  startWith: (history) ->
    @_socket.emit "start", history

  fetchBitmap: (cb) ->
    cb = _.once cb
    timeout = false

    timer = setTimeout ->
      timeout = true
      cb message: "Fetching timeout", reason: "timeout"
    , @timeoutTime

    @_socket.once "bitmap", (data) ->
      clearTimeout timer
      cb null, data unless timeout

    console.log "emiting!"
    @_socket.emit "getbitmap"


