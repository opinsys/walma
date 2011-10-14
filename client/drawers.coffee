
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

  constructor: (@opts) ->
    super
    @sketchCanvas = @$("canvas.sketch")
    @mainCanvas = @$("canvas.main")
    @user = @opts.user


  use: (Tool) ->
    if @tool
      @tool.unbind()
      delete @tool

    @tool = new Tool
      model: model
      sketch: @sketchCanvas.get(0)
      main: @mainCanvas.get(0)

    @tool.bind "draw", (shape) =>
      @trigger "draw",
        shape: shape
        user: @user
        time: (new Date()).getTime()




class drawers.ReplayDrawer extends BaseDrawer

  replay: (draw) ->
    @tool.replay draw.shape


class drawers.MouseDrawer extends BaseDrawer

  events:
    "mousedown canvas.sketch": "startDrawing"

  constructor: ->
    super
    $(window).mouseup @stopDrawing
    $(window).mousemove @cursorMove
    @positionEl = @sketchCanvas.get 0


  startDrawing: (e) =>
    @out = false
    @down = true
    @tool.begin()
    @tool.down @lastPoint = @getCoords e
    false

  cursorMove: (e) =>

    return if not @down

    # Mouse went ouf of canvas. 
    if e.target isnt @positionEl and not @out
      # Lift up the cursor from last know point
      @tool.up @lastPoint
      @out = true
      return


    if e.target is @positionEl
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
    x: e.pageX - @sketchCanvas.offsetLeft
    y: e.pageY - @sketchCanvas.offsetTop

