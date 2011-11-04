
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

  eraseDot: (point) ->
    point = _.clone point
    point.op = "move"

    # Set compositing back to destination-out if some remote user changes it.
    if @main.globalCompositeOperation isnt "destination-out"
      @setErasing()

    @main.beginPath()
    @main.arc(point.x, point.y, @getSize() / 2, 0, (Math.PI/180)*360, true);
    @main.fill()
    @main.closePath()
    @moves.push point

  setErasing: ->
    @main.globalCompositeOperation = "destination-out"
    @origStoreStyle = @main.strokeStyle
    @main.strokeStyle = "rgba(0,0,0,0)"

  begin: ->
    super
    @setErasing()

  down: (point) -> @eraseDot point
  move: (point) -> @eraseDot point
  up: (point) -> @eraseDot point

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


class exports.Move
  _.extend @::, Backbone.Events

  name: "Move"
  treshold: 4
  speedUp: @::treshold

  constructor: (opts) ->
    {@drawArea} = opts

  begin: ->
  end: ->
  updateSettings: ->


  down: (point) ->
    @startPoint = @lastPoint = point
    @count = 0


  move: (point) ->
    @count += 1

    if @lastPoint and @count >= @treshold
      # console.log "y", $(window).scrollTop(), @lastPoint.y, point.y, "diff", @lastPoint.y - point.y
      diffX = @lastPoint.x - point.x
      diffY = @lastPoint.y - point.y
      toX = $(window).scrollLeft() + diffX * @speedUp
      toY = $(window).scrollTop() + diffY * @speedUp
      # console.log "from", $(window).scrollLeft(), $(window).scrollTop(), "to", toX, toY

      # console.log "position", $(document).width() - $(window).width() - $(window).scrollLeft(), diffX

      scroll toX, toY
      @lastPoint = null
      @count = 0
    else
      @lastPoint = point


  up: (point) ->
    @expand point, true

  expand: (point, force=false) ->
    diffX = @startPoint.x - point.x
    diffY = @startPoint.y - point.y

    if not force and diffX < 50 and diffY < 50
      return

    console.log "EXPANDING"

    areaWidth = $(document).width()
    areaHeight = $(document).height()

    console.log "Width", areaWidth - $(window).width() - $(window).scrollLeft()
    offScreenX = !!!(areaWidth - $(window).width() - $(window).scrollLeft())
    offScreenY = !!!(areaHeight - $(window).height() - $(window).scrollTop())

    if offScreenX and diffX > 0
      areaWidth += diffX
      dirt = true
      console.log "REALLY EXPANDING width"
    if offScreenY and diffY > 0
      areaHeight += diffY
      dirt = true
      console.log "REALLY EXPANDING height"

    if dirt
      @drawArea.updateResolution
        x: areaWidth
        y: areaHeight

      @drawArea.resizeMainCanvas()

class exports.FastMove extends exports.Move

  name: "FastMove"
  speedUp: @::treshold * 4


