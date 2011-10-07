
tools = NS "PWB.drawers.tools"
{notImplemented} = NS "PWB.helpers"


class BaseTool extends Backbone.View

  name: "BaseTool" # Must match the class name

  constructor: (@opts) ->
    super


    @sketchCanvas = @$("canvas.sketch").get 0
    @mainCanvas = @$("canvas.main").get 0

    @sketch = @sketchCanvas.getContext("2d")
    @main = @mainCanvas.getContext("2d")


    # @sketch.fillStyle = '#000000'
    @sketch.strokeStyle = "black"
    @sketch.lineWidth = 3

  setColor: (color) ->
    @sketch.strokeStyle = color

  getColor:  -> @sketch.strokeStyle

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

    if @model
      console.log "have model", this
      @model.bind "change", =>
        # Can we get information which attr changed here?
        console.log "setting color to",  @model.get "color"
        @setColor @model.get "color"

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
    color: @sketch.strokeStyle
    tool: @name
    size: @size
    moves: @moves

  replay: (shape) ->
    # TODO: Sanitize method
    @setColor shape.color

    for point in shape.moves
      @[point.op] point
    @draw()

