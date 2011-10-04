
views = NS "PWI.views"


# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window


# Ideas from http://www.nogginbox.co.uk/blog/canvas-and-multi-touch

class views.Whiteboard extends Backbone.View

  constructor: (opts) ->
    super

    @lastPoints = []

    @ctx = @el.getContext('2d')

    @ctx.lineWidth = 2
    @ctx.strokeStyle = "rgb(0, 0, 0)"
    @ctx.beginPath()


    $(@el).mousedown @startDraw

    @el.onmouseup = @stopDraw

    @el.ontouchstart = @startDraw
    @el.ontouchstop = @stopDraw
    @el.ontouchmove = @draw


  startDraw: (e) =>
    @lastPoints[0] = @getCoords e
    @el.onmousemove = @draw

    return false

  draw: (e) =>
    p = @getCoords e
    @lastPoints[0] = @drawLine @lastPoints[0].x, @lastPoints[0].y, p.x, p.y
    @ctx.stroke()
    @ctx.closePath()
    @ctx.beginPath()


  stopDraw: (e) =>
    e.preventDefault()
    console.log "drawig stopped"
    @el.onmousemove = null

  drawLine: (sX, sY, eX, eY) =>
    @ctx.moveTo sX, sY
    @ctx.lineTo eX, eY

    x: eX, y: eY

  getCoords: (e) ->
    if e.offsetX
      x: offsetX,  y: offsetY
    else if e.layerX
      # Browser
      x: e.layerX, y: e.layerY
    else
      x: x.pageX - @el.offsetLeft
      t: x.pageY - @el.offsetTop

