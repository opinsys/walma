
tools = NS "PWB.drawers.tools"
{notImplemented} = NS "PWB.helpers"


class BaseTool extends Backbone.View
  constructor: (@opts) ->

    @color = @opts.color?

    @sketchCanvas = @$("canvas.sketch").get 0
    @mainCanvas = @$("canvas.main").get 0

    @sketch = @sketchCanvas.getContext("2d")
    @main = @mainCanvas.getContext("2d")

  draw: ->
    @main.drawImage @sketchCanvas, 0, 0
    @clear()

  clear: ->
    @sketch.clearRect 0, 0, @mainCanvas.width, @mainCanvas.height

  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"
  toJSON: notImplemented "toJSON"
  replay: notImplemented "replay"

class tools.Pencil extends BaseTool

  down: (point) ->
    # Start drawing
    @moves = []
    @moves.push point
    @lastPoint = point

    # TODO: draw a dot

  move: (to) ->
    console.log "moving", this
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



