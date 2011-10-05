drawers = NS "PWI.drawers"

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window

$ ->
  whiteboard = new drawers.Whiteboard
    el: ".whiteboard"


  if hasTtouch
    drawer = new drawers.TouchDrawer
      whiteboard: whiteboard
      el: ".whiteboard"
  else
    drawer = new drawers.MouseDrawer
      whiteboard: whiteboard
      el: ".whiteboard"

  drawer.bind "draw", (shape) ->
    whiteboard[shape.type] shape.from, shape.to

