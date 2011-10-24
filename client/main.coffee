
_  = require 'underscore' unless _
# _.mixin require 'underscore.string'

tools = require "drawtools"

{drawers} = NS "PWB"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"
helpers = NS "PWB.helpers"


socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window

room = window.location.pathname.substring(1) or "_main"
clientId = helpers.guidGenerator()




$ ->
  $("h1").text room

  canvases = $ "canvas"
  main = $("canvas.main").get 0

  keepMaximized = ->
    # console.log "redeize"
    # snapshot = new Image
    # snapshot.src = main.toDataURL("image/png", "")
    # snapshot.onload = ->
    #   console.log "drawing", x, y
    #   main.getContext("2d").drawImage snapshot, 0, 0

    # canvases.attr "width", x = $(document).width() - 350
    # canvases.attr "height", y = $(document).height() - 150
    canvases.attr "width", 800
    canvases.attr "height", 800


  keepMaximized()

$ ->

  window.model = toolModel = new models.ToolModel
  startup = []
  startup.push -> $("canvas.loading").removeClass "loading"
  startup.push -> $("div.loading").remove()
  position = 0

  statusModel = new models.StatusModel

  status = new views.Status
    el: ".status"
    model: statusModel

  if hasTouch
    Drawer = drawers.TouchDrawer
  else
    Drawer = drawers.MouseDrawer

  drawer = new Drawer
    el: ".whiteboard"
    model: toolModel
    user: "Esa"


  drawer.bind "draw", (draw) ->
    statusModel.addShape draw.shape
    socket.emit "draw", draw
    position += 1


  toolModel.bind "change:tool", ->
    drawer.use tools[toolModel.get "tool"]


  toolSettings = new views.ToolSettings
    el: ".tool_settings"
    model: toolModel


  socket.on "draw", (draw) ->
    statusModel.addDraw draw
    position += 1

    return unless draw
    tool = new tools[draw.shape.tool]
      sketch: $("canvas.remoteSketch").get(0)
      main: $("canvas.main").get(0)

    tool.replay draw.shape

  socket.on "getbitmap", ->
    console.log "I should send bitmap! pos:#{ position }", clientId
    socket.emit "bitmap",
      pos: position
      data: $("canvas.main").get(0).toDataURL()


  statusModel.set status: "connecting"
  socket.on "connect", ->
    statusModel.set status: "downloading history"
    socket.emit "join",
      room: room
      useragent: navigator.userAgent
      id: clientId

  socket.on "disconnect", ->
    statusModel.set status: "server disconnected"

  console.log "waiting for start"
  socket.on "start", (history) ->

    position = history.draws.length
    position += history.latestCachePosition or 0


    startHistoryDrawing = ->

      statusModel.set status: "drawing history"
      statusModel.loadOperations history.draws

      now = -> new Date().getTime()

      start = now()

      if history.latestCachePosition
        mainCtx.drawImage cacheImage, 0, 0

      operations = 0
      async.forEachSeries history.draws, (draw, cb) ->

        return cb() unless draw
        tool = new tools[draw.shape.tool]
          sketch: $("canvas.remoteSketch").get(0)
          main: $("canvas.main").get(0)

        tool.replay draw.shape
        operations += draw.shape.moves.length

        # If redrawing the history takes more than 500ms take a timeout and allow
        # the UI to draw itself.
        if now() - start > 400
          start = now()
          statusModel.incDrawnFromHistory operations
          operations = 0
          setTimeout ->
            cb()
          , 5
        else
          cb()


      , (err) ->
          throw err if err
          statusModel.drawnHistory()
          fn() for fn in startup
          statusModel.set status: "ready"

      null

    mainCtx = $("canvas.main").get(0).getContext "2d"

    if history.latestCachePosition
      cacheImage = new Image
      cacheImage.src = p = "/#{ room }/bitmap/#{ history.latestCachePosition }"
      console.log "loadin", p
      cacheImage.onload = ->
        console.log "loaded image"
        startHistoryDrawing()
    else
      startHistoryDrawing()

# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "background-color", that.data "color"


