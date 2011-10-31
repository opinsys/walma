
{drawers} = NS "PWB"
{views} = NS "PWB.drawers"
{models} = NS "PWB.drawers"
helpers = NS "PWB.helpers"

maindrawer = NS "PWB.maindrawer"

Backbone = require "backbone"

socket = io.connect().of("/drawer")

# http://modernizr.github.com/Modernizr/touch.html
hasTouch = 'ontouchstart' of window
if not hasTouch and typeof DocumentTouch isnt "undefined"
  hasTouch = document instanceof DocumentTouch



$ ->
  $(window).bind "touchstart", false
  $(window).bind "touchmove", false

  settings = new models.SettingsModel

  new views.ColorSelector
    el: ".colorSelector"
    model: settings


  new views.SizeSelector
    el: ".sizeSelector"
    model: settings

  new views.ToolSelector
    el: ".toolSelector"
    model: settings




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
  bg = new Background
    el: "canvas.main"
    socket: socket

  main = new maindrawer.Main
    roomName: window.location.pathname.substring(1) or "_main"
    id: helpers.guidGenerator()
    mainCanvas: $("canvas.main").get 0
    bufferCanvas: $("canvas.buffer").get 0
    settings: settings
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
    # http://www.html5rocks.com/en/mobile/mobifying.html#toc-optimizations-scrolling
    window.scrollTo 0, 100



class Background extends Backbone.View

  constructor: (opts) ->
    super
    {@socket} = opts
    @bindDrag()
    @socket.on "background", (url) =>
      console.log "got bg client"
      @setBackground url

    @socket.on "start", (history) =>
      if history.backgroundURL
        @setBackground history.backgroundURL

  bindDrag: ->

    $(document).bind "dragenter", (e) ->
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'

    $(document).bind "dragover", (e) ->
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'

    $(document).bind "dragleave", (e) -> e.preventDefault()
    $(document).bind "dragend", (e) -> e.preventDefault()
    $(document).bind "drop", (e) =>
      e.preventDefault()
      reader = new FileReader
      reader.onload = @fileRead
      reader.readAsDataURL e.originalEvent.dataTransfer.files[0]

  fileRead: (e) =>
    dataURL = e.target.result
    @setBackground dataURL
    @socket.emit "background", dataURL

  setBackground: (url) ->
    $(@el).css "background-image", "url(#{ url })"



# Just some styling
$ ->
  $("[data-color]").each ->
    that = $ @
    that.css "background-color", that.data "color"


