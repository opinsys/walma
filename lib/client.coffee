_  = require 'underscore'
{EventEmitter} = require "events"
useragent = require 'useragent'

# Epic dataURL parser. Returns base64 encoded PNG
parseDataURL = (dataURL) ->
  base64data = dataURL.split(",")[1]
  new Buffer(base64data, "base64")

class exports.Client extends EventEmitter

  timeoutTime: 1000 * 5

  constructor: (opts) ->
    super
    {@socket} = opts
    {@model} = opts

    @model.addClient this

    {@id} = opts
    {@userAgent} = opts

    @state = "created"

    @socket.on "state", (state) =>
      @state = state

    @socket.on "ready", =>
      @socket.broadcast.to(@model.name).emit "clientJoined",
        @getClientInfo()

    @socket.on "persist", (cb) =>
      @model.persist =>
        cb()
        @updateAttrs persistent: true

    @socket.on "remove", (cb) =>
      @model.remove (err) =>
        throw err if err
        @socket.broadcast.to(@model.name).emit "remove"
        cb()

    @socket.on "backgroundData", (dataURL, cb) =>
      @model.saveImage "background", parseDataURL(dataURL), (err) =>
        if err
          # TODO: send error msg to user
          console.log "Error while saving background", err
          return cb? err
        @updateAttrs background: new Date().getTime()
        cb?()

    @socket.on "backgroundDelete", (cb=->) =>
      @model.deleteImage "background", cb
      @updateAttrs background: null

    @socket.on "publishedImageData", (dataURL, cb) =>
      @model.saveImage "publishedImage", parseDataURL(dataURL), (err) =>
        if err
          # TODO: send error msg to user
          console.log "Error while saving published image", err
          return cb err
        @updateAttrs publishedImage: true
        console.log "Saved published image"
        cb?()



    @socket.on "draw", (draw, cb) =>
      cb()
      console.log "Routing draw"
      @socket.broadcast.to(@model.name).emit "draw", draw
      @model.addDraw draw, (err, status) =>
        if err
          console.log "Failed to save draw to db: #{ err }"
          return
        if status?.needCache
          console.log "asking for cache"
          @fetchBitmap (err, bitmap) =>
            if err
              console.log "Could not get cache bitmap #{ err?.message }", err
            else
              buf = parseDataURL bitmap.data
              console.log "Saving cahce", buf.length
              @model.setCache bitmap.pos, buf


    @socket.on "disconnect", =>

      console.log "Disconnecting", @model.toString()

      @socket.broadcast.to(@model.name).emit "clientParted",
        @getClientInfo()

      @destroy()

    @socket.on "bitmap", (bitmap) =>
      console.log "#{ @id } sent a bitmap", bitmap.data?.length, "k"


  destroy: ->
    @model.removeClient this
    @socket.removeAllListeners()
    @removeAllListeners()
    delete @model

  getClientInfo: ->
    id: @id
    userAgent: @userAgent
    browser: useragent.parse(@userAgent).toAgent()

  updateAttrs: (attrs) ->
    @socket.broadcast.to(@model.name).emit "updateAttrs", attrs

  join: ->
    console.log "joining", @model.name

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

      clients = for c in @model.clients
        c.getClientInfo()

      @startWith
        resolution: @model.resolution
        background: doc.background
        publishedImage: !! doc.publishedImage
        draws: history
        latestCachePosition: latest
        persistent: !!doc.persistent
        clients: clients



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


