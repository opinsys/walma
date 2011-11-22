
Backbone = require "backbone"
_  = require 'underscore'

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



class BaseInput extends Backbone.View

  constructor: (@opts) -> super

  use: (tool) ->
    console.log "using tool", tool.myid
    @tool.unbind() if @tool
    @tool = tool


class drawers.MouseInput extends BaseInput


  constructor: ->
    super
    $(window).mousedown @startDrawing
    $(window).mousemove @cursorMove
    $(window).mouseup @stopDrawing

  startDrawing: (e) =>

    return if e.target isnt @el
    @down = true

    @tool.begin()
    @tool.down @lastPoint = @getCoords e

    false



  cursorMove: (e) =>
    return if not @down


    @tool.move @lastPoint = @getCoords e


  stopDrawing: (e) =>
    return if not @down
    e.preventDefault()
    @down = false

    @tool.up @lastPoint
    @tool.end()



  getCoords: (e) ->
    x: e.pageX - @el.offsetLeft
    y: e.pageY - @el.offsetTop



class drawers.TouchInput extends BaseInput

  constructor: ->
    super


  events:
    "touchstart": "down"
    "touchend": "up"
    "touchmove": "move"

  move: (e) =>
    e.preventDefault()
    @tool.move @lastTouch = @getCoords e


  down: (e) =>
    e.preventDefault()
    @tool.begin()
    @tool.down @lastTouch = @getCoords e


  up: (e) =>
    e.preventDefault()
    @tool.up @lastTouch
    @tool.end()

  getCoords: (e) ->
    e = e.originalEvent.touches[0]
    x: e.pageX - @el.offsetLeft
    y: e.pageY - @el.offsetTop

