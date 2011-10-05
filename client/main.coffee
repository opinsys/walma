drawers = NS "PWI.drawers"

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

  socket.on "start", (history) ->
    for shape in history
      whiteboard[shape.type] shape.from, shape.to

    drawer.bind "draw", (shape) ->
      socket.emit "draw", shape

    socket.on "draw", (shape) ->
      whiteboard[shape.type] shape.from, shape.to

