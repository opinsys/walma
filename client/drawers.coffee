
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
    point.attr = @el[key] if point[attr] > @el[key]

  point



class BaseDrawer extends Backbone.View

  use: (tool) ->
    @tool = tool
    @activate()

  activate: notImplemented "activate"

class drawers.TouchDrawer extends BaseDrawer

  constructor: (@opts) ->
    super

    @el.ontouchstart = @startDraw
    @el.ontouchend = @stopDraw
    @el.ontouchmove = @fingerMove

    @lastPoints = []

  startDraw: (e) =>

    for touch, i in e.touches
      @lastPoints[i] = @getCoords touch

    false

  stopDraw: (e) ->
    e.preventDefault()

  fingerMove: (e) =>
    for touch, i in e.touches

      @trigger "draw",
        type: "line"
        from: @lastPoints[i]
        to: @lastPoints[i] = @getCoords e.touches[i]


    false

  getCoords: (e) ->
    x: e.pageX - @el.offsetLeft
    y: e.pageY - @el.offsetTop


class drawers.MouseDrawer extends BaseDrawer

  events:
    "mousedown": "startDrawing"
    "mouseup": "stopDrawing"
    "mouseout": "stopDrawing"

  activate: ->
    if not @active
      @lastPoint = null
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



