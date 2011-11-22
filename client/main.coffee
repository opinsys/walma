
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
  $(document).scroll (e) ->
    console.log "SCRolling"
    false


  $("body").bind "touchmove", (e) -> e.preventDefault()


  [__, roomName, position] = window.location.pathname.split("/")
  toolSettings = new models.ToolSettings



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
      value: "Pencil"
      label: "Pencil"
      description: "Free drawing tool"
      options: [ sizeSelect, colorSelect ]
    ,
      value: "Line"
      label: "Line"
      description: "Lines"
      options: [ sizeSelect, colorSelect ]
    ,
      value: "Circle"
      label: "Circle"
      description: "Circles"
      options: [ colorSelect ]
    ,
      value: "Move"
      label: "Move"
      description: "Pan drawing area"
      options: [ speedSelect ]
    ]

  toolMenu.render()

  socket = io.connect().of("/drawer")

  roomModel = new models.RoomModel
    socket: socket

  roomModel.set
    roomName: roomName
    position: parseInt position, 10

  notifications = new Notification


  ## OLDIES
  new views.ToolSelection
    el: ".toolSettings"
  .render()

  new views.ColorSelector
    el: ".colorSelector"
    model: toolSettings
  .render()


  new views.SizeSelector
    el: ".sizeSelector"
    model: toolSettings
  .render()


  new views.ToolSelector
    el: ".toolSelector"
    model: toolSettings
  .render()


  menu = new views.Menu
    el: ".menu"
    model: toolSettings

  menu.render()

  ## /OLDIES


  area = new DrawArea
    el: ".whiteboard"

  window._area = area

  menu.bind "publish", ->

    linkView = new views.PublicLink
      el: ".lightbox"
      model: roomModel
      area: area

    linkView.render()

    linkView.bind "published", -> notifications.info "Drawing published"


  statusView = new views.Status
    el: ".status"
    model: status = new models.StatusModel

  status.set status: "starting"


  socket.on "clientJoined", (client) ->
    status.addClient client
    notifications.info "#{ client.browser } joined. We have now #{ status.getClientCount() } other users"


  socket.on "clientParted", (client) ->
    status.removeClient client
    notifications.info "#{ client.browser } parted. We have now #{ status.getClientCount() } other users"

  navigation = new views.Navigation
    socket: socket
    model: roomModel
    settings: toolSettings
    el: ".navigation"

  navigation.render()

  if hasTouch
    Input = drawers.TouchInput
  else
    Input = drawers.MouseInput

  bg = new Background
    model: roomModel
    el: "canvas.main"
    socket: socket
    area: area

  bg.bind "bgsaved", -> notifications.info "Background saved"


  main = new maindrawer.Main
    model: roomModel
    toolSettings: toolSettings
    id: helpers.guidGenerator()
    area: area
    socket: socket
    status: status
    input: new Input
      el: "canvas.localBuffer"

  main.bind "ready", ->
    $("canvas.loading").removeClass "loading"
    $("div.loading").remove()
    # http://www.html5rocks.com/en/mobile/mobifying.html#toc-optimizations-scrolling
    window.scrollTo 0, 100



