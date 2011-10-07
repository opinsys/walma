
drawers = NS "PWB.drawers"
{notImplemented} = NS "PWB.helpers"

# Ideas from
# http://www.nogginbox.co.uk/blog/canvas-and-multi-touch
# http://dev.opera.com/articles/view/html5-canvas-painting/

# Python like decorator for sanitazing point positions on canvas.
# We don't care if cursor is out of bounds sometimes.
sanitizePoint = (fn) -> (e) ->
  # call the original function
  point = fn.call @, e

  # Sanitize ouput
  for key, attr of {width: "x", height: "y"}
    point[attr] = 0 if point[attr] < 0
    point[attr] = @el[key] if point[attr] > @el[key]

  point



class BaseDrawer extends Backbone.View

  use: (tool) ->
    @tool = tool
    @activate()

  activate: notImplemented "activate"




class drawers.MouseDrawer extends BaseDrawer

  events:
    "mousedown": "startDrawing"
    "mouseup": "stopDrawing"
    "mouseout": "stopDrawing"

  activate: ->
    if not @active
      @active = true

  startDrawing: (e) =>
    @down = true
    @tool.down @getCoords e
    $(@el).mousemove @cursorMove
    false

  cursorMove: (e) =>
    @tool.move @getCoords e


  stopDrawing: (e) =>
    e.preventDefault()

    # Only if mouse was down. This will be fired by mouseout too.
    if @down
      @tool.up @getCoords e

      # Stop drawing
      $(@el).unbind "mousemove", @cursorMove
      @down = false


  getCoords: sanitizePoint (e) ->
    if e.offsetX
      # Webkit
      x: e.offsetX,  y: e.offsetY
    else if e.layerX
      # Firefox
      x: e.layerX, y: e.layerY
    else
      console.log "could not get coords for", e



class drawers.TouchDrawer extends BaseDrawer

  constructor: ->
    super

  events:
    "touchstart": "fingerDown"
    "touchend": "fingerUp"
    "touchmove": "fingerMove"

  activate:  => drawers.MouseDrawer::activate.apply @, arguments

  fingerMove: (e) =>
    @tool.move @lastTouch = @getCoords e

  fingerDown: (e) =>
    @tool.down @lastTouch = @getCoords e
    false

  fingerUp: (e) =>
    @tool.up @lastTouch
    false

  getCoords: (e) ->
    e = e.originalEvent.touches[0]
    x: e.pageX - @el.offsetLeft
    y: e.pageY - @el.offsetTop

