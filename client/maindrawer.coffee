
Backbone = require "backbone"
_  = require 'underscore'

maindrawer = NS "PWB.maindrawer"

if document?.createElement?
  createCanvas = -> document.createElement "canvas"
else
  Canvas = require "canvas"
  createCanvas = -> new Canvas

tools = require "drawtools"

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window
now = -> new Date().getTime()

resizeCanvas = (width, height, canvas, cb=->) ->
  img = new Image
  data = canvas.toDataURL()
  canvas.width = width
  canvas.height = height
  img.onload = =>
    canvas.getContext("2d").drawImage img, 0, 0
    cb()
  img.src = data


class maindrawer.Main

  _.extend @::, Backbone.Events

  constructor: (opts) ->
    {@id} = opts

    # Draw count
    @drawCount = 0

    {@roomName} = opts

    # Tool settings model
    {@settings} = opts

    # Status model
    {@status} = opts

    # Main canvas
    {@mainCanvas} = opts

    # Client buffer canvas
    {@bufferCanvas} = opts

    # Buffer for remote users.
    @bufferCanvasRemote = createCanvas()


    # Socket for communicating with other drawers
    {@socket} = opts

    {@input} = opts


    @resolution =
      width: 0
      height: 0

    @setTool()
    @bindEvents()

  setTool: =>
    tool = new tools[@settings.get "tool"]
      model: @settings
      bufferCanvas: @bufferCanvas
      mainCanvas: @mainCanvas

    tool.bind "shape", (shape) =>
      @drawCount += 1
      @socket.emit "draw",
        shape: shape
        user: "Epeli"

    @input.use tool

  bindEvents: ->
    @socket.on "draw", @replay
    @status.set status: "Downloading history"
    @socket.on "start", (history) =>
      @drawCount = history.draws.length
      console.log "Need to draw", history.draws.length, "shapes"
      console.log "Got", history.latestCachePosition, "for free from cache"
      @drawCount += history.latestCachePosition or 0

      @updateResolution history.resolution

      @resizeMainCanvas =>
        if history.latestCachePosition
          bitmapUrl = "/#{ @roomName }/bitmap/#{ history.latestCachePosition }"
          console.log "Downloading cache from", bitmapUrl
          @status.set status: "Downloading bitmap"
          cacheImage = new Image
          cacheImage.src = bitmapUrl
          cacheImage.onload = => @drawHistory history.draws, cacheImage
        else
          @drawHistory history.draws


    @settings.bind "change:tool", @setTool

    @socket.on "connect", =>
      @socket.emit "join",
        room: @roomName
        id: @id
        useragent: navigator.userAgent
    @socket.on "getbitmap", =>
      console.log "I should send bitmap! pos:#{ @drawCount }", @id
      @socket.emit "bitmap",
        pos: @drawCount
        data: @mainCanvas.toDataURL()


  drawHistory: (draws, img) =>
    @status.set status: "drawing history"
    @status.loadOperations draws

    if img
      @mainCanvas.getContext("2d").drawImage img, 0, 0

    operations = 0
    start = now()
    async.forEachSeries draws, (draw, cb) =>

      return cb() unless draw

      @replay draw

      operations += draw.shape.moves.length

      # If redrawing the history takes more than 500ms take a timeout and allow
      # the UI to draw itself.
      if now() - start > 400
        start = now()
        @status.incDrawnFromHistory operations
        operations = 0
        setTimeout =>
          cb()
        , 5
      else
        cb()


    , (err) =>
        throw err if err
        @status.setDrawnHistory()
        @status.set status: "ready"
        @trigger "ready"

    null

  replay: (draw) =>
    @status.addDraw draw

    for point in draw.shape.moves
      @updateResolution point

    tool = new tools[draw.shape.tool]
      bufferCanvas: @bufferCanvasRemote
      mainCanvas: @mainCanvas

    tool.replay draw.shape
    @drawCount += 1



  # Keep main canvas size as big as needed
  updateResolution: (point) ->

    if point.x > @resolution.width
      @resolution.width = point.x
      @dirtyCanvasSize = true
    if point.y > @resolution.height
      @resolution.height = point.y
      @dirtyCanvasSize = true

  resizeMainCanvas: (cb=->) ->
      # Main canvas should not ever get smaller
    if @dirtyCanvasSize
      @bufferCanvasRemote.width = @resolution.width
      @bufferCanvasRemote.height = @resolution.height
      resizeCanvas @resolution.width, @resolution.height, @mainCanvas, cb
      @dirtyCanvasSize = false
    else
      cb()

  resizeDrawingArea: (width, height) ->
    @bufferCanvas.width = width
    @bufferCanvas.height = height
    @bufferCanvasRemote.width = width
    @bufferCanvasRemote.height = height
    @input.tool.updateSettings()
    @updateResolution
      x: width
      y: height
    @resizeMainCanvas()



