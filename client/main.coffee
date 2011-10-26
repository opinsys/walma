


{drawers} = NS "PWB"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"
helpers = NS "PWB.helpers"

maindrawer = NS "PWB.maindrawer"


socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window


$ ->
  console.log "start up"

  toolSettings = new models.SettingsModel
  toolSettingsView = new views.ToolSettings
    el: ".tool_settings"
    model: toolSettings

  statusView = new views.Status
    el: ".status"
    model: status = new models.StatusModel

  status.set status: "sgtarting"

  socket = io.connect().of("/drawer")

  if hasTouch
    Input = drawers.TouchInput
  else
    Input = drawers.MouseInput


  console.log  "creaign main"
  main = new maindrawer.Main
    roomName: window.location.pathname.substring(1) or "_main"
    id: helpers.guidGenerator()
    mainCanvas: $("canvas.main").get 0
    bufferCanvas: $("canvas.buffer").get 0
    settings: toolSettings
    socket: socket
    status: status
    input: new Input
      el: "canvas.buffer"
      user: "Esa"

  main.resizeDrawingArea window.innerWidth, window.innerHeight
  $(window).resize ->
    main.resizeDrawingArea window.innerWidth, window.innerHeight

  main.bind "ready", ->
    $("canvas.loading").removeClass "loading"
    $("div.loading").remove()




# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "background-color", that.data "color"


