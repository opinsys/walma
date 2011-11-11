
Backbone = require "backbone"
_  = require 'underscore'

maindrawer = NS "PWB.maindrawer"

if document?.createElement?
  createCanvas = -> document.createElement "canvas"
else
  Canvas = require "canvas"
  createCanvas = -> new Canvas

tools = require "drawtools"

now = -> new Date().getTime()


class maindrawer.Main

  _.extend @::, Backbone.Events

  constructor: (opts) ->
    {@id} = opts

    # Draw count
    @drawCount = 0

    # Tool settings model
    {@model} = opts

    # Status model
    {@status} = opts

    {@area} = opts


    # Socket for communicating with other drawers
    {@socket} = opts

    {@input} = opts


    @setTool()
    @bindEvents()

  setTool: =>

    tool = new tools[@model.get "tool"]
      model: @model
      area: @area

    tool.bind "shape", (shape) =>
      @drawCount += 1
      console.log "We have #{ @drawCount } draws"
      @socket.emit "draw",
        shape: shape
        user: "Epeli"
      @status.addUserDraw()

    @input.use tool

  bindEvents: ->
    @socket.on "draw", @replay
    @socket.on "start", (history) =>
      @status.set
        cachedDraws: history.latestCachePosition or 0
        startDraws: history.draws.length

      @drawCount = history.latestCachePosition or 0
      console.log "Need to draw #{history.draws.length} shapes"
      console.log "Got #{history.latestCachePosition} for free from cache"

      @area.update history.resolution.x, history.resolution.y
      @area.resize =>
        if history.latestCachePosition
          bitmapUrl = "/#{ @model.get "roomName" }/#{ @model.get "position" }/bitmap/#{ history.latestCachePosition }"
          @status.set status: "downloading cache"
          cacheImage = new Image
          cacheImage.onload = => @drawHistory history.draws, cacheImage
          cacheImage.src = bitmapUrl
        else
          @drawHistory history.draws


    @model.bind "change:tool", @setTool

    @status.set status: "Connecting"
    if @socket.socket.connected
      @join()
    else
      @socket.on "connect", => @join()

    @socket.on "getbitmap", =>
      console.log "I should send bitmap! pos:#{ @drawCount }", @id
      @socket.emit "bitmap",
        pos: @drawCount
        data: @area.getDataURL()


  join: ->
    @status.set
      status: "downloading history"
      transport: @socket.socket.transport.name

    @socket.emit "join",
      room: @model.get "roomName"
      position: @model.get "position"
      id: @id
      userAgent: navigator.userAgent

  drawHistory: (draws, img) =>
    console.log "Drawing history", draws.length
    @status.set status: "drawing history"

    if img
      @area.drawImage img

    operations = 0
    start = now()

    @status.set startDraws: draws.length

    async.forEachSeries draws, (draw, cb) =>

      return cb() unless draw

      @replay draw

      operations += draw.shape.moves.length

      # If redrawing the history takes more than 500ms take a timeout and allow
      # the UI to draw itself.
      if now() - start > 400
        start = now()
        operations = 0
        setTimeout =>
          cb()
        , 5
      else
        cb()


    , (err) =>
        throw err if err
        @status.set status: "ready"
        @trigger "ready"

    null

  replay: (draw) =>

    for point in draw.shape.moves
      @area.updateFromPoint point

    tool = new tools[draw.shape.tool]
      area: @area

    @area.resize =>
      tool.replay draw.shape
      @drawCount += 1
      @status.addRemoteDraw()



