
tools = NS "PWB.drawers.tools"
{notImplemented} = NS "PWB.helpers"


class BaseTool
  _.extend @::, Backbone.Events

  name: "BaseTool" # Must match the class name

  constructor: (@opts) ->
    @model = @opts.model

    @sketchCanvas = @opts.sketch
    @mainCanvas = @opts.main


    @sketch = @sketchCanvas.getContext "2d"
    @main = @mainCanvas.getContext "2d"




  setColor: (color) ->
    @sketch.strokeStyle = color
    @sketch.fillStyle = color

  getColor:  -> @sketch.strokeStyle

  setSize: (width) ->
    @sketch.lineWidth = width

  getSize: -> @sketch.lineWidth


  draw: ->
    stats.update()
    @main.drawImage @sketchCanvas, 0, 0
    @clear()


  clear: ->
    @sketch.clearRect 0, 0, @mainCanvas.width, @mainCanvas.height

  begin: ->
    @moves = []

  end: ->
    @trigger "draw", @toJSON()

  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"


  drawLine: (from, to) ->
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
    @draw()

  toJSON: ->
    color: @getColor()
    tool: @name
    size: @getSize()
    moves: @moves

class tools.Pencil extends BaseTool

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
class tools.Eraser extends tools.Pencil
  name: "Eraser"

  draw:  ->
    @main.globalCompositeOperation = "destination-out"
    super
    @main.globalCompositeOperation = "source-over"


  # Draw always on movement so that we can immediately see what we erase
  move: ->
    super
    @draw()


class tools.Line extends BaseTool

  name: "Line"

  down: (point) ->
    # Start drawing
    point = _.clone point
    point.op = "down"
    @moves.push @startPoint = point
    @lastPoint = point



  move: (to) ->
    from = @startPoint
    @clear()
    @drawLine from, to

    to = _.clone to
    to.op = "move"
    @lastPoint = to

  up:   ->
    # @drawLine @startPoint, @lastPoint
    @moves[1] = @lastPoint
    @draw()



