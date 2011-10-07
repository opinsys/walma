
tools = NS "PWB.drawers.tools"
{notImplemented} = NS "PWB.helpers"


class BaseTool extends Backbone.View

  name: "BaseTool" # Must match the class name

  constructor: (@opts) ->


    @sketchCanvas = @$("canvas.sketch").get 0
    @mainCanvas = @$("canvas.main").get 0

    @sketch = @sketchCanvas.getContext("2d")
    @main = @mainCanvas.getContext("2d")

  draw:  ->
    @main.drawImage @sketchCanvas, 0, 0
    @clear()

    @trigger "draw", @toJSON()

  clear: ->
    @sketch.clearRect 0, 0, @mainCanvas.width, @mainCanvas.height


  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"
  toJSON: notImplemented "toJSON"
  replay: notImplemented "replay"

class tools.Pencil extends BaseTool

  name: "Pencil"

  constructor: ->
    super
    @color = @opts.color
    @size = @opts.size

  down: (point) ->
    # Start drawing
    @moves = []
    point.op = "down"
    @moves.push point
    @lastPoint = point

    # TODO: draw a dot

  move: (to) ->
    to.op = "move"
    @moves.push to
    from = @lastPoint

    @sketch.moveTo from.x, from.y
    @sketch.lineTo to.x, to.y

    @sketch.stroke()
    @sketch.beginPath()
    @sketch.closePath()

    @lastPoint = to

  up: (point) ->
    @move point
    @draw()

  toJSON: ->
    color: @color
    tool: @name
    size: @size
    moves: @moves

  replay: (shape) ->
    # TODO: Sanitize method
    for point in shape.moves
      @[point.op] point
    @draw()

