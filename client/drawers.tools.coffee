
tools = NS "PWB.drawers.tools"
{notImplemented} = NS "PWB.helpers"


class BaseTool extends Backbone.View

  name: "BaseTool" # Must match the class name

  constructor: (@opts) ->
    super

    @sketchCanvas = @$( @opts.sketch or "canvas.sketch").get 0
    @mainCanvas = @$("canvas.main").get 0

    @sketch = @sketchCanvas.getContext("2d")
    @main = @mainCanvas.getContext("2d")

    if @model
      @model.bind "change", @updateCanvasSettings
      @updateCanvasSettings()



  setColor: (color) ->
    @sketch.strokeStyle = color
    @sketch.fillStyle = color

  getColor:  -> @sketch.strokeStyle

  setSize: (width) ->
    @sketch.lineWidth = width

  getSize: -> @sketch.lineWidth


  draw:  ->
    @main.drawImage @sketchCanvas, 0, 0
    @clear()


  clear: ->
    @sketch.clearRect 0, 0, @mainCanvas.width, @mainCanvas.height

  begin: ->
    @moves = []

  end: ->
    console.log "END"
    @trigger "draw", @toJSON()

  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"

  updateCanvasSettings: =>
    console.log "updating", this, @model, arguments
    @setColor @model.get "color"
    @setSize @model.get "size"

  replay: (shape) ->
    @setColor shape.color
    @setSize shape.size

    # TODO: Sanitize op
    @begin()
    for point in shape.moves
      @[point.op] point
    @draw()
    @end()

  toJSON: ->
    color: @getColor()
    tool: @name
    size: @getSize()
    moves: @moves

class tools.Pencil extends BaseTool

  name: "Pencil"

  constructor: ->
    super
    @sketch.lineCap = "round"



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

    @sketch.beginPath()
    @sketch.moveTo from.x, from.y
    @sketch.lineTo to.x, to.y

    @sketch.stroke()
    @sketch.closePath()

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


