
Backbone = require "backbone"
_  = require 'underscore'

toolmenu = NS "PWB.toolmenu"

class toolmenu.ToolMenu extends Backbone.View

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
