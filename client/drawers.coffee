
drawers = NS "PWI.drawers"


# Ideas from
# http://www.nogginbox.co.uk/blog/canvas-and-multi-touch
# http://dev.opera.com/articles/view/html5-canvas-painting/

class drawers.Whiteboard extends Backbone.View

  constructor: (opts) ->
    super


    @ctx = @el.getContext('2d')

    @ctx.lineWidth = 2
    @ctx.strokeStyle = "rgb(0, 0, 0)"
    @ctx.beginPath()



  line: (from, to) =>
    console.log "drawing", from, "to", to
    @ctx.moveTo from.x, from.y
    @ctx.lineTo to.x, to.y

    @ctx.stroke()
    @ctx.closePath()
    @ctx.beginPath()

    to






class drawers.TouchDrawer extends Backbone.View

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


class drawers.MouseDrawer extends Backbone.View

  constructor: (@opts) ->
    super
    @whiteboard = @opts.whiteboard

    @el.onmousedown = @startDraw
    @el.onmouseup = @stopDraw
    @lastPoint = null


  cursorMove: (e) =>
    @trigger "draw",
      type: "line"
      from: @lastPoint
      to: @lastPoint = @getCoords e



  startDraw: (e) =>
    @lastPoint = @getCoords e
    @el.onmousemove = @cursorMove

    return false

  stopDraw: (e) =>
    e.preventDefault()
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



