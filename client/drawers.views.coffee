
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"



class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

  render: ->
    $(@el).html @template @model.toJSON()


