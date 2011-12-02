
PWB = NS "PWB"

{DrawArea} = PWB.drawarea
{Background} = PWB.background

{drawers} = NS "PWB"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"
{Notification} = NS "PWB.notification"
toolmenu = NS "PWB.toolmenu"
helpers = NS "PWB.helpers"

maindrawer = NS "PWB.maindrawer"

Backbone = require "backbone"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window
if not hasTouch and typeof DocumentTouch isnt "undefined"
  hasTouch = document instanceof DocumentTouch


$ ->
  $(".color button").each ->
    $el = $ this
    $el.css "background-color", $el.data "value"

  $(".size button").each ->
    $el = $ this
    $el.html  $el.data "value"


$ ->

  statusView = new views.Status
    el: ".status"
    model: status = new models.StatusModel
  statusView.render()

  window.socket = io.connect().of("/drawer")
  setSocketStatus = ->
    s = ""

    for name in [ "open", "connected", "connecting", "reconnecting"]
      if socket.socket[name]
        s += name + " "

    status.set socketStatus: $.trim s

  socket.on "connect", setSocketStatus
  socket.on "disconnect", setSocketStatus
  setInterval setSocketStatus, 1000

  $("body").bind "touchmove", (e) -> e.preventDefault()


  [__, roomName, position] = window.location.pathname.split("/")
  toolSettings = new models.ToolSettings

  roomModel = new models.RoomModel
    socket: socket

  area = new DrawArea
    model: roomModel
    el: ".whiteboard"



  roomModel.set
    roomName: roomName
    position: parseInt position, 10

  navigation = new views.Navigation
    socket: socket
    model: roomModel
    settings: toolSettings
    el: ".navigation"

  miscMenu = new views.MiscMenu
    el: ".group.miscMenu"
    model: roomModel
    area: area
    settings: toolSettings


  colorSelect = new toolmenu.ColorSelect
    model: toolSettings
    colors: [ "black", "white", "red", "green", "blue", "yellow", "pink" ]
  colorSelect.render()

  sizeSelect = new toolmenu.SizeSelect
    model: toolSettings
    sizes: [ 5, 10, 20, 50, 100 ]
  sizeSelect.render()

  speedSelect = new toolmenu.SpeedSelect
    model: toolSettings
    speeds: [
      speed: 4
      human: "Normal"
    ,
      speed: 10
      human: "Fast"
    ]
  speedSelect.render()


  toolMenu = new toolmenu.ToolMenu
    el: ".menuContainer"
    model: toolSettings
    tools: [
      label: "Menu"
      description: ""
      subviews: [ miscMenu ]
    ,
      value: "Pencil"
      label: "Pencil"
      description: "Free drawing tool"
      subviews: [ sizeSelect, colorSelect ]
    ,
      value: "Line"
      label: "Line"
      description: "Lines"
      subviews: [ sizeSelect, colorSelect ]
    ,
      value: "Circle"
      label: "Circle"
      description: "Circles"
      subviews: [ colorSelect ]
    ,
      value: "Eraser"
      label: "Eraser"
      description: "Erase drawings"
      subviews: [ sizeSelect ]
    ,
      value: "Move"
      label: "Pan"
      description: "Pan drawing area"
      subviews: [ speedSelect ]
    ]

  toolMenu.render()



  notifications = new Notification
  socket.on "disconnect", ->
    notifications.error "Disconnected. Please reload page"


  miscMenu.bind "publish", ->
    notifications.info "Drawing published"


  status.set status: "starting"


  socket.on "clientJoined", (client) ->
    status.addClient client
    notifications.info "#{ client.browser } joined. We have now #{ status.getClientCount() } other users"


  socket.on "clientParted", (client) ->
    status.removeClient client
    notifications.info "#{ client.browser } parted. We have now #{ status.getClientCount() } other users"


  if hasTouch
    Input = drawers.TouchInput
  else
    Input = drawers.MouseInput


  roomModel.bind "background-saved", -> notifications.info "Background saved"


  main = new maindrawer.Main
    model: roomModel
    toolSettings: toolSettings
    id: helpers.guidGenerator()
    area: area
    socket: socket
    status: status
    input: new Input
      el: "canvas.localBuffer"

  main.bind "timeout", ->
    notifications.error "Timeout occurred when saving the drawing. Bad network connection."

  status.bind "change:lag", ->
    lag = status.get "lag"
    if lag > 1000 * 5
      notifications.warning "Network connection is really slow. (#{ lag }ms)"

  main.bind "ready", ->
    $("canvas.loading").removeClass "loading"
    $("div.loading").remove()
    # http://www.html5rocks.com/en/mobile/mobifying.html#toc-optimizations-scrolling
    window.scrollTo 0, 100



