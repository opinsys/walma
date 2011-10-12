
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

  constructor: ->
    super
    $(window).mouseup @stopDrawing
    $(window).mousemove @cursorMove

  events:
    "mousedown": "startDrawing"
    # "mouseout": "mouseOut"


  mouseOut: =>
    @mouseOnCanvas = false

  activate: ->
    if not @active
      @active = true

  startDrawing: (e) =>
    @out = false
    @down = true
    @tool.begin()
    @tool.down @lastPoint = @getCoords e
    console.log "user is drawing", @tool.sketch.strokeStyle
    false

  cursorMove: (e) =>

    return if not @down

    # Mouse went ouf of canvas. 
    if e.target isnt @el and not @out
      # Lift up the cursor from last know point
      @tool.up @lastPoint
      @out = true
      return

    if e.target is @el
      if @out
        # Came back to canvas! Put cursor down
        @tool.down @lastPoint = @getCoords e
      else
        @tool.move @lastPoint = @getCoords e

      @out = false


  stopDrawing: (e) =>
    e.preventDefault()

    # Only if mouse was down.
    if @down
      @tool.up @lastPoint
      @tool.end()

      # Stop drawing
    $(document).unbind "mousemove", @cursorMove
    @down = false


  getCoords: (e) ->
    if e.offsetX?
      # Webkit
      x: e.offsetX,  y: e.offsetY
    else if e.layerX?
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
    @tool.begin()
    @tool.down @lastTouch = @getCoords e

    false

  fingerUp: (e) =>
    @tool.up @lastTouch
    @tool.end()
    false

  getCoords: (e) ->
    e = e.originalEvent.touches[0]
    x: e.pageX - @el.offsetLeft
    y: e.pageY - @el.offsetTop

