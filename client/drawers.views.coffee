

views = NS "PWB.drawers.views"

class views.ToolSettings extends Backbone.View

  events:
    "click .color button": "changeColor"

  changeColor: (e) =>
    @model.set color: $(e.currentTarget).data("color")


