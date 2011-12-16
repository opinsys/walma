Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


# alert "#{ BrowserDetect.OS } #{ BrowserDetect.browser } #{ navigator.userAgent }"


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

  # iPad does not have FormData or file inputs, but otherwise it works very
  # well. So don't show warning.
  if BrowserDetect.OS is "iPad"
    return true

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

