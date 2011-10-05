
views = NS "PWI.views"


# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window


# Ideas from http://www.nogginbox.co.uk/blog/canvas-and-multi-touch

class views.Whiteboard extends Backbone.View

  constructor: (opts) ->
    super


    @ctx = @el.getContext('2d')

    @ctx.lineWidth = 2
    @ctx.strokeStyle = "rgb(0, 0, 0)"
    @ctx.beginPath()



  drawLine: (from, to) =>
    @ctx.moveTo from.x, from.y
    @ctx.lineTo to.x, to.y

    @ctx.stroke()
    @ctx.closePath()
    @ctx.beginPath()

    to



class views.MouseDrawer

  constructor: (@whiteboard) ->
    @el = @whiteboard.el
    @el.onmousedown = @startDraw
    @el.onmouseup = @stopDraw
    @lastPoint = null

    # @el.ontouchstart = @startDraw
    # @el.ontouchstop = @stopDraw
    # @el.ontouchmove = @draw

  cursorMove: (e) =>
    to = @getCoords e
    console.log "drawing", to
    @lastPoint = @whiteboard.drawLine @lastPoint, to


  startDraw: (e) =>
    console.log "start"
    @lastPoint = @getCoords e
    @el.onmousemove = @cursorMove

    return false

  stopDraw: (e) =>
    e.preventDefault()
    console.log "drawing stopped"
    @el.onmousemove = null


  getCoords: (e) ->
    if e.offsetX
      x: offsetX,  y: offsetY
    else if e.layerX
      # Browser
      x: e.layerX, y: e.layerY
    else
      x: x.pageX - @el.offsetLeft
      t: x.pageY - @el.offsetTop


