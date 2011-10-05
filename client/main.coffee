views = NS "PWI.views"

$ ->
  whiteboard = new views.Whiteboard
    el: ".whiteboard"

  new views.MouseDrawer whiteboard



