drawers = NS "PWI.drawers"

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window

$ ->
  whiteboard = new drawers.Whiteboard
    el: ".whiteboard"


  if hasTtouch
    new drawers.TouchDrawer
      whiteboard: whiteboard
      el: ".whiteboard"
  else
    new drawers.MouseDrawer
      whiteboard: whiteboard
      el: ".whiteboard"



