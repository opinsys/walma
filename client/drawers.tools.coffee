
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

    @trigger "draw", @toJSON()

  clear: ->
    @sketch.clearRect 0, 0, @mainCanvas.width, @mainCanvas.height


  down: notImplemented "down"
  up: notImplemented "up"
  move: notImplemented "move"
  toJSON: notImplemented "toJSON"
  replay: notImplemented "replay"
  updateCanvasSettings: notImplemented "updateCanvasSettings"

class tools.Pencil extends BaseTool

  name: "Pencil"

  constructor: ->
    super
    @sketch.lineCap = "round"


  updateCanvasSettings: =>
    @setColor @model.get "color"
    @setSize @model.get "size"

  down: (point) ->
    # Start drawing
    point = _.clone point
    point.op = "down"
    @moves = []
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

  toJSON: ->
    color: @getColor()
    tool: @name
    size: @getSize()
    moves: @moves

  replay: (shape) ->
    # TODO: Sanitize method
    @setColor shape.color
    @setSize shape.size

    for point in shape.moves
      @[point.op] point
    @draw()

