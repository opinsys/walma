

views = NS "PWB.drawers.views"

class views.ToolSettings extends Backbone.View


  constructor: ->
    super
    currentSize = parseInt @$(".size input").val(), 10
    @model.set size: currentSize or @defaults.size
    @model.set color: @$(".color .selected").data("color")
    @model.set tool: @$(".tool .selected").data("tool")


  events:
    "click .color button": "changeColor"
    "click .tool button": "changeTool"
    "keyup .size input": "changeSize"

  changeTool: (e) =>
    setting = $(e.currentTarget)
    @model.set tool: setting.data("tool")

    @$(".tool .selected").removeClass "selected"
    setting.addClass "selected"

  changeColor: (e) =>
    setting = $(e.currentTarget)
    @model.set color: setting.data("color")

    @$(".color .selected").removeClass "selected"
    setting.addClass "selected"



  changeSize: (e) =>
    @model.set size: parseInt $(e.currentTarget).val(), 10


class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

  render: ->
    $(@el).html @template @model.toJSON()


