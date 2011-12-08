
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


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
