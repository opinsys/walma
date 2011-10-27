
Backbone = require "backbone"
_  = require 'underscore'
notImplemented = (f) -> f


class BaseTool
  _.extend @::, Backbone.Events

  name: "BaseTool" # Must match the class name

  constructor: (opts) ->
    {@model} = opts
    {@bufferCanvas} = opts
    {@mainCanvas} = opts

    @sketch = @bufferCanvas.getContext "2d"
    @main = @mainCanvas.getContext "2d"

    @updateSettings()

    if @model
      @model.bind "change", =>
        @updateSettings()


  updateSettings: ->
    if @model
      @setColor @model.get "color"
      @setSize @model.get "size"

  setColor: (color) ->
    @sketch.strokeStyle = color
    @sketch.fillStyle = color

  getColor:  -> @sketch.strokeStyle

  setSize: (width) ->
    @sketch.lineWidth = width

  getSize: -> @sketch.lineWidth


  draw: ->
    @main.globalCompositeOperation = "source-over"
    @main.drawImage @bufferCanvas, 0, 0
    @clear()


  clear: ->
    @sketch.clearRect 0, 0, @bufferCanvas.width, @bufferCanvas.height

  begin: ->
    @moves = []

  end: ->
    @trigger "shape", @toJSON()

  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"


  drawLine: (from, to) ->
    if not from.x? or not to.x?
      return
    @sketch.lineCap = "round"
    @sketch.beginPath()
    @sketch.moveTo from.x, from.y
    @sketch.lineTo to.x, to.y

    @sketch.stroke()
    @sketch.closePath()


  replay: (shape) ->
    @begin()
    @setColor shape.color
    @setSize shape.size

    # TODO: Sanitize op
    for point in shape.moves
      @[point.op] point

    @end()
    @draw()

  toJSON: ->
    color: @getColor()
    tool: @name
    size: @getSize()
    moves: @moves

class exports.Pencil extends BaseTool

  name: "Pencil"


  down: (point) ->
    # Start drawing
    point = _.clone point
    point.op = "down"
    @moves.push point
    @lastPoint = point

    # Draw a dot at the begining of the path. This is not required for Firefox,
    # but Webkits (Chrome & Android) won't draw anything if user just clicks
    # the canvas.
    @drawDot point

  drawDot: (point) ->
    @sketch.beginPath()
    @sketch.arc(point.x, point.y, @getSize() / 2, 0, (Math.PI/180)*360, true);
    @sketch.fill()
    @sketch.closePath()


  move: (to) ->
    to = _.clone to
    to.op = "move"
    @moves.push to
    from = @lastPoint

    @drawLine from, to

    @lastPoint = to

  up: (point) ->
    @move point
    @draw()




# Eraser is basically just a pencil where compositing is turned inside out
class exports.Eraser extends BaseTool
  name: "Eraser"

  draw: ->

  drawDot: (point) ->
    point = _.clone point
    point.op = "move"

    @main.beginPath()
    @main.arc(point.x, point.y, @getSize() / 2, 0, (Math.PI/180)*360, true);
    @main.fill()
    @main.closePath()
    @moves.push point

  begin: ->
    super
    @main.globalCompositeOperation = "destination-out"
    @origStoreStyle = @main.strokeStyle
    @main.strokeStyle = "rgba(0,0,0,0)"

  down: (point) ->
    @drawDot point

  move: (point) ->
    @drawDot point

  up: (point) ->
    @drawDot point

  end: ->
    @main.globalCompositeOperation = "source-over"
    @main.strokeStyle = @origStoreStyle
    super


class exports.Line extends BaseTool

  name: "Line"

  begin: ->
    super
    @lastPoint = null

  down: (point) ->
    # Start drawing
    if @lastPoint is null
      point = _.clone point
      point.op = "down"
      @moves.push @startPoint = point
      @lastPoint = point


  drawShape: @::drawLine

  move: (to) ->
    from = @startPoint
    @clear()
    @drawShape from, to

    to = _.clone to
    to.op = "move"
    @lastPoint = to

  up:   ->
    # @drawLine @startPoint, @lastPoint
    @moves[1] = @lastPoint

  end: ->
    @draw()
    super


class exports.Circle extends exports.Line

  name: "Circle"

  drawShape: (from, to) ->
    radius = Math.sqrt( Math.pow(@startPoint.x - to.x, 2) + Math.pow(@startPoint.y - to.y, 2) )
    @sketch.moveTo @startPoint.x, @startPoint.y + radius

    @sketch.beginPath()
    @sketch.arc(@startPoint.x, @startPoint.y, radius, 0, (Math.PI/180)*360, true);
    @sketch.fill()
    # @sketch.stroke()
    @sketch.closePath()



