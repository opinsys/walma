
drawarea = NS "PWB.drawarea"

Backbone = require "backbone"
_  = require 'underscore'

resizeCanvas = (width, height, canvas, cb=->) ->
  img = new Image
  data = canvas.toDataURL("image/png")
  canvas.width = width
  canvas.height = height
  img.onload = =>
    canvas.getContext("2d").drawImage img, 0, 0
    cb()
  img.src = data



class drawarea.DrawArea
  _.extend @::, Backbone.Events

  constructor: (opts) ->
    @width = 0
    @height = 0
    @bgURL = null
    @bgIMG = null

    # Canvases
    {@main} = opts
    {@localBuffer} = opts
    {@remoteBuffer} = opts

    # Simple div that is fast to resize
    if opts.soft
      @soft = $ opts.soft

    @dirty = false

  getDataURL: ->
    @main.toDataURL("image/png")

  getDataURLWithBackground: (cb) ->
    if not @bgURL
      cb null, @getDataURL()
      return

    img = new Image
    canvas = document.createElement "canvas"
    canvas.width = @width
    canvas.height = @height
    img.onload = =>
      ctx = canvas.getContext "2d"
      ctx.drawImage img, 0, 0
      ctx.drawImage @main 0, 0
      cb null, canvas.toDataURL("image/png")

    img.src = @bgURL


  drawImage: (img) ->
    @main.getContext("2d").drawImage img, 0, 0


  setBackground: (url, cb=->) ->
    @bgURL = url
    img = new Image
    img.onload = =>
      $(@main).css "background-image", "url(#{ url })"
      @update img.width, img.height
      @resize cb
    img.src = url


  update: (width, height, resize) ->

    if width > @width
      @width = width
      @dirty = true

    if height > @height
      @height = height
      @dirty = true

    if resize
      @resize()

    @dirty

  updateFromPoint: (point) ->
    @update point.x, point.y

  softResize: ->
    @soft.css("width", @width).css("height", @height)

  resize: (cb=->) ->
    return cb() unless @dirty

    @softResize()
    resizeCanvas @width, @height, @main, =>


      for c in [@localBuffer, @remoteBuffer]
        c.width = @width
        c.height = @height

      @dirty = false
      console.log "Canvas resized", @width, @height
      @trigger "resize", @width, @height
      cb()

