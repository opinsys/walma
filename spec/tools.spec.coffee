


if document?.createElement?
  createCanvas = -> document.createElement "canvas"
else
  Canvas = require "canvas"
  createCanvas = -> new Canvas

tools = require "drawtools"

describe "Pencil", ->
  beforeEach ->
    @pencil = new tools.Pencil
      main: createCanvas()
      sketch: createCanvas()

    @pencil.begin()

    @pencil.down
      x: 100
      y: 100

    @pencil.move
      x: 150
      y: 130

    @pencil.move
      x: 190
      y: 170

    @pencil.up
      x: 250
      y: 230

    @pencil.end()

  it "records movement", ->
    expect(@pencil.toJSON().moves.length).toBe 4

    moves = (move.op for move in @pencil.toJSON().moves)
    expect(moves).toEqual ["down", "move", "move", "move"]


describe "Line", ->
  beforeEach ->
    @line = new tools.Line
      main: createCanvas()
      sketch: createCanvas()

    @line.begin()

    @line.down
      x: 100
      y: 100

    @line.move
      x: 150
      y: 130

    @line.move
      x: 190
      y: 170

    @line.up
      x: 250
      y: 230

    @line.end()

  it "records only start and end point", ->
    expect(@line.toJSON().moves.length).toBe 2

describe "Circle", ->
  beforeEach ->
    @circle = new tools.Circle
      main: createCanvas()
      sketch: createCanvas()

    @circle.begin()

    @circle.down
      x: 100
      y: 100

    @circle.move
      x: 150
      y: 150

    @circle.move
      x: 200
      y: 200

    @circle.up
      x: 200
      y: 200

    @circle.end()


  it "has drawn a circle", ->
    expect(@circle.moves).toEqual  [ { x : 100, y : 100, op : 'down' }, { x : 200, y : 200, op : 'move' } ]


