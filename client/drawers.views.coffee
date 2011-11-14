
Backbone = require "backbone"

views = NS "PWB.drawers.views"




class views.ToolSelection extends Backbone.View

  constructor: ->
    super

    @toolBar = $(@el)

    @current =
      x: @toolBar.offset().left
      y: @toolBar.offset().top

    @size =
      width: $(@el).width()
      height: $(@el).height()

    $(@el).mousedown @startMove
    $(window).mouseup @stopMove
    $(window).mousemove @move

    $(@el).bind "touchstart", (e) =>
      @startMove e.originalEvent.touches[0]
      false

    $('body').bind "touchend", (e) =>
      @stopMove e.originalEvent.touches[0]
      false

    $('body').bind "touchmove", (e) =>
      @move e.originalEvent.touches[0]
      false

  move: (e) =>
    if @last

      diffPoint =
        x: e.pageX - @last.pageX
        y: e.pageY - @last.pageY


      newPoint =
        x: @current.x + diffPoint.x
        y: @current.y + diffPoint.y



      if newPoint.x > 0 and newPoint.x + @size.width < $(window).width()
        @toolBar.css "left", "#{ newPoint.x }px"

      if newPoint.y > 0 and newPoint.y + @size.height < $(window).height()
        @toolBar.css "top", "#{ newPoint.y }px"


      @current = newPoint
      @last = e

  startMove: (e) =>
    @last = e

  stopMove: =>
    if @last
      @last = null
      false



class views.BaseMenu extends Backbone.View

  constructor: ->
    super
    @$(".toggle").bind "tap", => @openOptions()

  openOptions: =>
    @$(".options").animate width: "show", 150, =>
      $(window).one "tap", => @closeOptions()

  closeOptions: =>
    @$(".options").animate(width: "hide", 150)



class views.Menu extends views.BaseMenu

  constructor: ->
    super

    @$(".remote").bind "tap", =>
      @model.set remote: !@model.get "remote"

    @$(".publish").bind "tap", =>
      @trigger "publish"

    @model.bind "change:remote", => @render()



  render: ->
    if @model.get "remote"
      @$(".remote").addClass "selected"
    else
      @$(".remote").removeClass "selected"

class views.ColorSelector extends views.BaseMenu

  events:
    "tap .options button": "change"

  option: "color"

  constructor: ->
    super

    # load default value
    if not @model.get @option
      options = {}
      options[@option] = @$("button.selected").data "value"
      @model.set options

    @render()

    @model.bind "change", @render

    @styleButtons()


  styleButtons: ->
    @$(".options button").each ->
      $el = $ this
      $el.css "background-color", $el.data "value"



  change: (e) =>
    setting = $(e.currentTarget)

    options = {}
    options[@option] = color = setting.data("value")
    @model.set options


  renderSelected: ->
    @$(".selected").removeClass "selected"
    selected = @$("[data-value='#{ @model.get @option  }']")
    selected.addClass "selected"

  render: =>
    @renderSelected()
    @$("button.toggle").css "background-color", @model.get @option



class views.SizeSelector extends views.ColorSelector
  option: "size"
  styleButtons: ->
    @$(".options button").each ->
      $el = $ this
      $el.html "#{$el.data "value"}px"

  render: =>
    @renderSelected()
    @$("button.toggle").html "#{ @model.get @option }px"


class views.ToolSelector extends views.ColorSelector
  option: "tool"
  styleButtons: ->

  render: =>
    @renderSelected()
    @$("button.toggle").html "#{ @model.get @option }"


class views.Status extends Backbone.View

  constructor: ->
    super
    source = $(".status-template").html()
    @template = Handlebars.compile source
    @model.bind "change", => @render()

  render: ->
    $(@el).html @template @model.toJSON()


