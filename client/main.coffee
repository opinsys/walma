drawers = NS "PWB.drawers"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window

$ ->
  whiteboard = new drawers.Whiteboard
    el: ".whiteboard"


  if hasTtouch
    drawer = new drawers.TouchDrawer
      el: ".whiteboard"
  else
    drawer = new drawers.MouseDrawer
      el: ".whiteboard"

  drawer.bind "draw", (shape) ->
    whiteboard[shape.type] shape.from, shape.to

  room = window.location.pathname.substring(1) or "main"

  socket.on "connect", ->
    socket.emit "join", room

  socket.on "disconnect", ->
    $("h1").html "disconneted :("

  socket.on "start", (history) ->
    size = JSON.stringify(history).length
    $("h1").after "<p>Loaded around #{ size / 1024 }kB from history</p>"
    for shape in history
      whiteboard[shape.type] shape.from, shape.to

    drawer.bind "draw", (shape) ->
      socket.emit "draw", shape

    socket.on "draw", (shape) ->
      whiteboard[shape.type] shape.from, shape.to

