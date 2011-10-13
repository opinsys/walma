
{drawers} = NS "PWB"
{tools} = NS "PWB.drawers"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"


socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window
room = window.location.pathname.substring(1) or "_main"



$ ->
  $("h1").text _.capitalize room
  if Stats?
    window.stats = new Stats
    $("body").append stats.domElement
  else
    window.stats =
      update: ->

  window.model = toolModel = new models.ToolModel
  startup = []
  startup.push -> $(".loading").remove()

  statusModel = new models.StatusModel

  status = new views.Status
    el: ".status"
    model: statusModel

  if hasTtouch
    drawer = new drawers.TouchDrawer
      el: "canvas.sketch"
  else
    drawer = new drawers.MouseDrawer
      el: "canvas.sketch"


  toolModel.bind "change:tool", ->
    tool = new tools[toolModel.get "tool"]
      el: ".whiteboard"
      model: toolModel

    tool.bind "draw", (shape) ->
      statusModel.addShape shape

      socket.emit "draw",
        shape: shape
        user: "esa"
        time: (new Date()).getTime()

    drawer.use tool


  toolSettings = new views.ToolSettings
    el: ".tool_settings"
    model: toolModel


  socket.on "draw", (draw) ->
    statusModel.addDraw draw

    tool = new tools[draw.shape.tool]
      el: ".whiteboard"
      sketch: ".remoteSketch"

    # TODO: buffer during history draw
    tool.replay draw.shape


  statusModel.set status: "connecting"
  socket.on "connect", ->
    statusModel.set status: "downloading history"
    socket.emit "join", room

  socket.on "disconnect", ->
    statusModel.set status: "server disconnected"

  socket.on "start", (history) ->
    statusModel.set status: "drawing history"
    statusModel.loadOperations history

    now = -> new Date().getTime()

    start = now()
    operations = 0
    async.forEachSeries history, (draw, cb) ->

      tool = new tools[draw.shape.tool]
        el: ".whiteboard"
        sketch: ".remoteSketch"

      tool.replay draw.shape
      operations += draw.shape.moves.length

      # If redrawing the history takes more than 500ms take a timeout and allow
      # the UI to draw itself.
      if now() - start > 400
        start = now()
        statusModel.incDrawnFromHistory operations
        operations = 0
        setTimeout ->
          cb()
        , 5
      else
        cb()


    , (err) ->
        throw err if err
        statusModel.drawnHistory()
        fn() for fn in startup
        statusModel.set status: "ready"

    null


# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "background-color", that.data "color"


