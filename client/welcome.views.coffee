
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


supportedBrowser = do ->
  result = true

  if typeof FormData isnt "function"
    console.log "No form data support"
    result = false

  if not Modernizr.canvas
    console.log "No canvas support"
    result = false

  if Modernizr.canvas
    c = document.createElement("canvas")
    data = c.toDataURL("image/png")
    if data.indexOf("data:image/png") isnt 0
      console.log "No canvas.toDataURL support"
      result = false


  result

class views.Welcome extends Backbone.View

  constructor: ->
    super

    source = $("script.welcomeTemplate").html()
    @template = Handlebars.compile source

  events:
    "tap button.close": "close"

  close: ->
    @trigger "select"

  render: ->
    $(@el).html @template()
    if supportedBrowser
      @$(".notSupported").hide()
    else
      @$(".notSupported").show()

