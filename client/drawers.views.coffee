

views = NS "PWB.drawers.views"

class views.ToolSettings extends Backbone.View

  defaults:
    color: "black"
    tool: "Pencil"
    size: 3

  constructor: ->
    super
    currentSize = parseInt @$(".size input").val(), 10
    console.log "CURR", currentSize
    @model.set size: currentSize or @defaults.size

  events:
    "click .color button": "changeColor"
    "click .tool button": "changeTool"
    "keyup .size input": "changeSize"

  changeTool: (e) =>
    @model.set tool: $(e.currentTarget).data("tool")

  changeColor: (e) =>
    @model.set color: $(e.currentTarget).data("color")

  changeSize: (e) =>
    @model.set size: parseInt $(e.currentTarget).val(), 10


