
{drawers} = NS "PWB"
{tools} = NS "PWB.drawers"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window
room = window.location.pathname.substring(1) or "main"

$ ->
  # whiteboard = new drawers.Whiteboard
  #   el: "canvas.main"

  # mainCanvas = $(".whiteboard").get 0
  # sketchCanvas = document.createElement "canvas"
  # sketchCanvas.

  toolModel = new models.ToolModel
  toolSettings = new views.ToolSettings
    el: ".tool_settings"
    model: toolModel

  if hasTtouch
    drawer = new drawers.TouchDrawer
  else
    drawer = new drawers.MouseDrawer
      el: "canvas.sketch"

  pencil = new tools.Pencil
    el: ".whiteboard"
    model: toolModel

  pencil.bind "draw", (shape) ->
    console.log "Sending", shape
    socket.emit "draw",
      shape: shape
      user: "esa"
      time: (new Date()).getTime()

    console.log shape

  drawer.use pencil

  socket.on "draw", (draw) ->

    console.log "got", draw, tools
    tool = new tools[draw.shape.tool]
      el: ".whiteboard"
      sketch: ".remoteSketch"
    tool.replay draw.shape


  socket.on "connect", ->
    socket.emit "join", room

  socket.on "disconnect", ->
    $("h1").html "disconneted :("

  socket.on "start", (history) ->
    size = JSON.stringify(history).length

    $("h1").after "<p>Loaded around #{ size / 1024 }kB from history</p>"

    for draw in history
      tool = new tools[draw.shape.tool]
        el: ".whiteboard"
      tool.replay draw.shape


# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "color", that.data "color"


