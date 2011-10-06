
drawers = NS "PWB.drawers"
{notImplemented} = NS "PWB.helpers"

# Ideas from
# http://www.nogginbox.co.uk/blog/canvas-and-multi-touch
# http://dev.opera.com/articles/view/html5-canvas-painting/


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

  activate: ->
    if not @active
      @el.onmousedown = @mouseDown
      @el.onmouseup = @mouseUp
      @lastPoint = null
      @active = true

  mouseDown: (e) =>
    @tool.down @getCoords e
    @el.onmousemove = @cursorMove
    false

  cursorMove: (e) =>
    @tool.move @getCoords e
    # console.log "DOWn", @down


  mouseUp: (e) =>
    e.preventDefault()

    @tool.up @getCoords e

    # Stop drawing
    @el.onmousemove = null


  getCoords: (e) ->
    if e.offsetX
      # Webkit
      x: e.offsetX,  y: e.offsetY
    else if e.layerX
      # Firefox
      x: e.layerX, y: e.layerY
    else
      console.log "could not get coords for", e



