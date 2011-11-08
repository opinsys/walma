
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

  drawImage: (img) ->
    @main.getContext("2d").drawImage img, 0, 0


  setBackground: (url, cb=->) ->
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

