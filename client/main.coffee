
{drawers} = NS "PWB"
{tools} = NS "PWB.drawers"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTtouch = 'ontouchstart' of window
room = window.location.pathname.substring(1) or "_main"

$ ->

  window.model = toolModel = new models.ToolModel

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
    console.log "using now tool:", tool

    tool.bind "draw", (shape) ->
      socket.emit "draw",
        shape: shape
        user: "esa"
        time: (new Date()).getTime()

    drawer.use tool


  toolSettings = new views.ToolSettings
    el: ".tool_settings"
    model: toolModel


  socket.on "draw", (draw) ->

    tool = new tools[draw.shape.tool]
      el: ".whiteboard"
      sketch: ".remoteSketch"
    tool.replay draw.shape


  socket.on "connect", ->
    socket.emit "join", room

  socket.on "disconnect", ->
    $("h1").html "disconneted :("

  progress = $("h1")
  progress.text "downloading history"
  socket.on "start", (history) ->
    size = JSON.stringify(history).length

    $("h1").after "<p>Loaded around #{ size / 1024 }kB from history</p>"
    now = -> new Date().getTime()

    start = now()
    i = 0
    async.forEachSeries history, (draw, cb) ->
      i += 1
      tool = new tools[draw.shape.tool]
        el: ".whiteboard"
        sketch: ".remoteSketch"
      tool.replay draw.shape

      if now() - start > 500
        progress.text "#{ i+1 } / #{ history.length }"
        start = now()
        setTimeout ->
          cb()
        , 10
      else
        cb()


    , (err) ->
        throw err if err
        progress.text "#{ i } / #{ history.length } operations drawn"

    null


# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "color", that.data "color"


