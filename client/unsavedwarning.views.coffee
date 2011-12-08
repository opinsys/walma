
Backbone = require "backbone"
_  = require 'underscore'

views = NS "PWB.drawers.views"


class views.UnsavedWarning extends Backbone.View

  el: ".unsavedWarning"


  constructor: ({ @toolMenu }) ->
    super

    @model.bind "change:persistent", =>
      @render()

    @render()


  render: ->
    if @model.get "persistent"
      $(@el).hide()
    else
      $(@el).show()

  events:
    "tap": "openMenu"

  openMenu: ->
    @toolMenu.menus["Menu"]()
