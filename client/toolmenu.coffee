
Backbone = require "backbone"
_  = require 'underscore'

toolmenu = NS "PWB.toolmenu"

class Draggable extends Backbone.View

  constructor: ->
    super
    @toolBar = $(@el)

    @current =
      x: @toolBar.offset().left
      y: @toolBar.offset().top

    @size =
      width: $(@el).width()
      height: $(@el).height()

    @usingTouch = false

    @$(".dragArea").mousedown (e) =>
      e.preventDefault()
      @startMove e unless @usingTouch

    $(window).mouseup (e) =>
      @stopMove e unless @usingTouch

    $(window).mousemove (e) =>
      @move e unless @usingTouch

    $(".dragArea").bind "touchstart", (e) =>
      @usingTouch = true
      @startMove e.originalEvent.touches[0]

    $('body').bind "touchend", (e) =>
      @stopMove e.originalEvent.touches[0]
      @usingTouch = false

    $("body").bind "touchmove", (e) =>
      @move e.originalEvent.touches[0]


  move: (e) =>


    return if not @down

    if not @_last
      console.log "setting last"
      return @_last = e

    console.log "TOUCH move", e.pageX, @_last.pageX, @_last is e

    diffPoint =
      x: e.pageX - @_last.pageX
      y: e.pageY - @_last.pageY


    newPoint = _.clone @current
    newX = @current.x + diffPoint.x
    newY = @current.y + diffPoint.y


    if newX > 0 and newX + @size.width < $(window).width()
      @toolBar.css "left", "#{ newX }px"
      newPoint.x = newX

    if newY > 0 and newY + @size.height < $(window).height()
      @toolBar.css "top", "#{ newY }px"
      newPoint.y = newY

    @current = newPoint

    @_last = e




  startMove: (e) =>
    @down = true
    console.log "TOUCH start"

  stopMove: =>
    console.log "stopping"
    if @down
      @last = null
      @down = false
      console.log "TOUCH end"






groupButtons = (buttons) ->

  for button in buttons then do (button) ->
    button.bind "select", ->
      button.select()
      for other in buttons when other isnt button
          other.unselect()


class Button extends Backbone.View

  events:
    "tap button": "tap"

  constructor: (opts) ->
    super
    {@field, @value, @label, @description} = opts
    {@label, @description} = opts
    {@icon} = opts

    source = $("script.menuButtonTemplate").html()
    @template = Handlebars.compile source

    @model.bind "change:#{ @field }", => @render()


  render: ->

    $(@el).html @template @

    if @model.get(@field) is @value
      @select()

    if @icon
      @$("button").css("background-image", "url(#{ @icon })")
      .text " "

  tap: ->
    if @value
      ob = {}
      ob[@field] = @value
      console.log "button tap setting", ob
      @model.set ob
    @trigger "select", @

  select: ->
    $(@el).children().addClass("selected")

  unselect: ->
    $(@el).children().removeClass("selected")


class ColorButton extends Button

  render: ->
    super
    @$("button").css "background-color", @value


# Base class for tool options
class Options extends Backbone.View

  constructor: (@opts) ->
    super

    source = $("script.toolOptionsTemplate").html()
    @template = Handlebars.compile source

  render: ->
    # First detach from DOM so that elements won't lose their event bindings.
    $(@el).children().detach()
    $(@el).html @template @


# Dummy options view. Just shows some text.
class Description extends Backbone.View

  constructor: (@opts) ->
    super
    {@label, @description} = @opts

    source = $("script.toolTitle").html()
    @template = Handlebars.compile source

  render: ->
    $(@el).html @template @

class toolmenu.ColorSelect extends Options
  label: "Color"
  description: ""

  constructor: ->
    super
    @colorButtons = for color in @opts.colors then do (color) =>
      button = new ColorButton
        model: @model
        field: "color"
        label: " "
        value: color
        description: "Tool color"

      button.render()
      button.bind "select", (e) => @trigger "select", e

      button



  render: ->
    super
    for button in @colorButtons
      button.render()
      @$(".buttons").append button.el


class toolmenu.SizeSelect extends Options

  label: "Size"
  description: ""

  constructor: ->
    super
    @sizeButtons = for size in @opts.sizes then do (size) =>
      button = new Button
        model: @model
        field: "size"
        label: "#{ size }px"
        value: size
        description: "Tool size"

      button.render()
      button.bind "select", (e) => @trigger "select", e

      button


  render: ->
    super
    for button in @sizeButtons
      @$(".buttons").append button.el
      button.render()


class toolmenu.SpeedSelect extends Options

  label: "Panning speed"
  description: "Use normal on tablets and desktop. Fast for large smartboards etc."


  constructor: ->
    super
    @sizeButtons = for speedOpt in @opts.speeds then do (speedOpt) =>
      button = new Button
        model: @model
        field: "panningSpeed"
        label: speedOpt.human
        value: speedOpt.speed
        description: speedOpt.human + " speed"

      button.render()

      button.bind "select", (e) => @trigger "select", e

      button


  render: ->
    super
    for button in @sizeButtons
      @$(".buttons").append button.el

class toolmenu.ToolMenu extends Draggable

  constructor: (opts) ->
    super
    {@tools} = opts

    @selectedButton = null

    @$(".buttons,.tabs").bind "mousemove mousedown", (e) ->
      e.preventDefault()


    @menus = {}

    @toolButtons = for tool in opts.tools then do (tool) =>
      tool.field = "tool"
      tool.model = @model
      button = new Button tool
      description = new Description tool
      description.render()

      for view in tool.subviews
        view.bind "select", => @closeMenu()

      # Allow progmatic menu selection
      @menus[tool.label] = -> button.tap()

      button.bind "select", =>
        @$(".content").children().detach()

        @$(".content").append description.el
        for view in tool.subviews
          view.render()
          @$(".content").append view.el

        @toolSelected button

      button

    groupButtons @toolButtons

    $("body").bind "mousedown touchstart", (e) =>
      if $(this.el).has(e.target).length is 0
        @closeMenu()

  events:
    "tap .close a": "closeMenu"

  toolSelected: (button) ->

    previous =  @selectedButton
    @selectedButton = button

    if previous is button
      @closeMenu()
    else
      @openMenu()


  closeMenu: ->
    @$(".wrapper").removeClass "openDown"
    @selectedButton = null
    @model.trigger "change:tool"

  openMenu: ->
    @$(".wrapper").addClass "openDown"

  render: ->
    $(@el).show()

    @$(".buttons").children().detach()

    for b in @toolButtons
      b.render()
      @$(".buttons").append b.el

    newWidth = @$(".dragArea").parent().width() +
      @$(".buttons").width() * (@toolButtons.length+1)

    @$(".buttons").css "width", "#{ newWidth }px"



