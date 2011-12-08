
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

    $(window).bind "hashtagchange", (e, tags) =>
      @active = tags.has "debug"
      @render()

  show: ->
    $(@el).show()

  hide: ->
    $(@el).hide()


  render: ->
    if @active
      $(@el).html @template @model.toJSON()
      @show()
    else
      @hide()

