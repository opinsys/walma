_  = require 'underscore'
{EventEmitter} = require "events"

class exports.Client extends EventEmitter

  timeoutTime: 1000 * 5

  constructor: (opts) ->
    super
    {@socket} = opts
    {@model} = opts

    {@id} = opts
    {@userAgent} = opts

    @state = "created"

    @socket.on "state", (state) =>
      @state = state

    @socket.on "bgdata", (background) =>

      # Epic dataURL parser
      base64data = background.split(",")[1]

      @model.setBackground new Buffer(base64data, "base64"), =>
        @socket.broadcast.to(@model.name).emit "background"


    @socket.on "draw", (draw) =>
      @socket.broadcast.to(@model.name).emit "draw", draw
      @model.addDraw draw, (err, status) =>
        if err
          console.log "Failed to save draw to db: #{ err }"
          return
        if status?.needCache
          @fetchBitmap (err, bitmap) =>
            if err
              console.log "Could not get cache bitmap #{ err.message } #{ client.id }"
            else
              @model.setCache bitmap.pos, bitmap.data


    @socket.on "disconect", =>
      console.log "Disconnect: #{ @id }"

    @socket.on "bitmap", (bitmap) =>
      console.log "#{ @id } sent a bitmap", bitmap.data?.length, "k"

  join: ->
    @socket.join @model.name

    @model.fetch (err, doc) =>
      return cb err if err

      while (latest = doc.cache.pop()) > doc.history.length
        console.log "We have newer cache than history!", latest, ">", doc.history.length

      console.log "History is", doc.history.length, "cache:", latest

      if latest
        history = doc.history.slice latest
      else
        history = doc.history

      console.log "Sending history ", history.length

      @startWith
        resolution: @model.resolution
        background: doc.background
        draws: history
        latestCachePosition: latest



  startWith: (history) ->
    @socket.emit "start", history


  fetchBitmap: (cb=->) ->
    cb = _.once cb
    timeout = false

    timer = setTimeout ->
      timeout = true
      cb message: "Fetching timeout", reason: "timeout"
    , @timeoutTime

    @socket.once "bitmap", (bitmap) ->
      clearTimeout timer
      cb null, bitmap unless timeout

    @socket.emit "getbitmap"


