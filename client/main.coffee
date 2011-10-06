
{drawers} = NS "PWB"
{tools} = NS "PWB.drawers"

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

  if hasTtouch
    drawer = new drawers.TouchDrawer
  else
    drawer = new drawers.MouseDrawer
      el: "canvas.sketch"

  drawer.use new tools.Pencil
    el: ".whiteboard"

  # socket.on "connect", ->
  #   socket.emit "join", room

  # socket.on "disconnect", ->
  #   $("h1").html "disconneted :("

  # socket.on "start", (history) ->
  #   size = JSON.stringify(history).length
  #   $("h1").after "<p>Loaded around #{ size / 1024 }kB from history</p>"
    # for shape in history
    #   whiteboard[shape.type] shape.from, shape.to

    # TODO: to tool
    # drawer.bind "draw", (shape) ->
    #   socket.emit "draw", shape

    # socket.on "draw", (shape) ->
    #   whiteboard[shape.type] shape.from, shape.to

