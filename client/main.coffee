
{drawers} = NS "PWB"
{tools} = NS "PWB.drawers"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"


socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window
room = window.location.pathname.substring(1) or "_main"



$ ->
  $("h1").text _.capitalize room
  if Stats?
    window.stats = new Stats
    $("body").append stats.domElement
  else
    window.stats =
      update: ->

$ ->

  canvases = $ "canvas"
  main = $("canvas.main").get 0
  keepMaximized = ->
    # console.log "redeize"
    # snapshot = new Image
    # snapshot.src = main.toDataURL("image/png", "")
    # snapshot.onload = ->
    #   console.log "drawing", x, y
    #   main.getContext("2d").drawImage snapshot, 0, 0

    canvases.attr "width", x = $(document).width() - 350
    canvases.attr "height", y = $(document).height() - 150


  keepMaximized()

$ ->

  window.model = toolModel = new models.ToolModel
  startup = []
  startup.push -> $(".loading").remove()

  statusModel = new models.StatusModel

  status = new views.Status
    el: ".status"
    model: statusModel

  if hasTouch
    Drawer = drawers.TouchDrawer
  else
    Drawer = drawers.MouseDrawer

  drawer = new Drawer
    el: ".whiteboard"
    model: toolModel
    user: "Esa"


  drawer.bind "draw", (draw) ->
    statusModel.addShape draw.shape
    socket.emit "draw", draw


  toolModel.bind "change:tool", ->
    drawer.use tools[toolModel.get "tool"]


  toolSettings = new views.ToolSettings
    el: ".tool_settings"
    model: toolModel


  socket.on "draw", (draw) ->
    statusModel.addDraw draw

    # TODO: buffer during history draw
    return unless draw
    tool = new tools[draw.shape.tool]
      sketch: $("canvas.sketch").get(0)
      main: $("canvas.main").get(0)

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

      return cb() unless draw
      tool = new tools[draw.shape.tool]
        sketch: $("canvas.sketch").get(0)
        main: $("canvas.main").get(0)

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


