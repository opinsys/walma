
drawers = NS "PWI.drawers"




# Ideas from http://www.nogginbox.co.uk/blog/canvas-and-multi-touch

class drawers.Whiteboard extends Backbone.View

  constructor: (opts) ->
    super


    @ctx = @el.getContext('2d')

    @ctx.lineWidth = 2
    @ctx.strokeStyle = "rgb(0, 0, 0)"
    @ctx.beginPath()



  drawLine: (from, to) =>
    console.log "need to draw from", from, "to", to
    @ctx.moveTo from.x, from.y
    @ctx.lineTo to.x, to.y

    @ctx.stroke()
    @ctx.closePath()
    @ctx.beginPath()

    to






class drawers.TouchDrawer extends Backbone.View

  constructor: (@opts) ->
    super
    @whiteboard = @opts.whiteboard

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
      p = @getCoords e.touches[i]
      @lastPoints[i] = @whiteboard.drawLine @lastPoints[i], p

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
    to = @getCoords e
    @lastPoint = @whiteboard.drawLine @lastPoint, to


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

# Draw to Canvas using socket.io
class drawers.SockectDrawer


