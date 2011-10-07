

views = NS "PWB.drawers.views"

class views.ToolSettings extends Backbone.View

  defaults:
    color: "black"
    size: 3

  constructor: ->
    super
    currentSize = parseInt @$(".size input").val(), 10
    console.log "CURR", currentSize
    @model.set size: currentSize or @defaults.size

  events:
    "click .color button": "changeColor"
    "keyup .size input": "changeSize"

  changeColor: (e) =>
    @model.set color: $(e.currentTarget).data("color")

  changeSize: (e) =>
    @model.set size: parseInt $(e.currentTarget).val(), 10


