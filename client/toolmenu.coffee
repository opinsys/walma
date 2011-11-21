
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

    @$(".dragArea").mousedown @startMove
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
      @last = e

  startMove: (e) =>
    e.preventDefault()
    @last = e

  stopMove: =>
    if @last
      @last = null
      false


class ToolButton extends Backbone.View

  constructor: (opts) ->
    super
    {@name} = opts
    {@description} = opts
    {@options} = opts

    # Display info as dummy option
    @options.unshift new Description opts

    source = $("script.menuButtonTemplate").html()
    @template = Handlebars.compile source

  render: ->
    $(@el).html @template @

    @$("button").bind "tap", =>
      @trigger "select", @name
      @model.set tool: @name


  select: ->
    $(@el).children().addClass("selected")

  unselect: ->
    $(@el).children().removeClass("selected")



# Base class for tool options
class Options extends Backbone.View

  constructor: (opts) ->
    super

    source = $("script.toolOptionsTemplate").html()
    @template = Handlebars.compile source

  render: ->
    $(@el).html @template @


# Dummy options view. Just shows some text.
class Description extends Options

  constructor: (opts) ->
    {@name, @description} = opts
    super

class toolmenu.ColorSelect extends Options
  name: "Color"
  description: "desc..."


class toolmenu.SizeSelect extends Options

  name: "Size"
  description: "desc..."



class toolmenu.ToolMenu extends Draggable

  constructor: (opts) ->
    super
    {@tools} = opts

    @selectedButton = null

    @buttons = for buttonOpts in opts.tools
      buttonOpts.model = @model
      button = new ToolButton buttonOpts

      do (button) =>
        button.bind "select", => @toolSelected button

      button

    @model.bind "change:tool", =>


    $("body").bind "mousedown touchstart", (e) =>
      if $(this.el).has(e.target).length is 0
        @closeMenu()

  toolSelected: (button) ->
    previous =  @selectedButton
    @selectedButton = button

    if previous is button
      @closeMenu()
    else
      @openMenu()

    for b in @buttons
      b.unselect()
    button.select()



  closeMenu: ->
    @$(".wrapper").removeClass "openDown"
    @selectedButton = null

  openMenu: ->
    @$(".wrapper").addClass "openDown"
    @menuContent = @$(".content")
    @menuContent.empty()

    for o in @selectedButton.options
      o.render()
      @menuContent.append o.el

  render: ->
    @$(".buttons").empty()
    for b in @buttons
      b.render()
      @$(".buttons").append b.el


