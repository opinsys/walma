
Backbone = require "backbone"

views = NS "PWB.drawers.views"


class views.ToolSettings extends Backbone.View


  constructor: ->
    super
    currentSize = parseInt @$(".size input").val(), 10
    @model.set size: currentSize or @defaults.size
    @model.set color: @$(".color .selected").data("color")
    @model.set tool: @$(".tool .selected").data("tool")

    @sizeInput = $ ".size input"
    @model.bind "change:size", =>
      @sizeInput.val @model.get "size"


  events:
    "tap .color button": "changeColor"
    "tap .tool button": "changeTool"
    "tap .size button.bigger": "increaseSize"
    "tap .size button.smaller": "decreaseSize"
    "keyup .size input": "changeSize"

  changeTool: (e) =>
    setting = $(e.currentTarget)
    @model.set tool: setting.data("tool")

    @$(".tool .selected").removeClass "selected"
    setting.addClass "selected"

  changeColor: (e) =>
    console.log "Changing color"
    setting = $(e.currentTarget)
    @model.set color: color = setting.data("color")

    @$(".color .selected").removeClass "selected"
    setting.addClass "selected"

  increaseSize: (e) =>
    @model.set size: @model.get("size") + 10

  decreaseSize: (e) =>
    @model.set size: @model.get("size") - 10

  changeSize: (e) =>
    @model.set size: (e.currentTarget).val(), 10



class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

  render: ->
    $(@el).html @template @model.toJSON()


