Backbone = require "backbone"
_  = require 'underscore'

models = NS "PWB.drawers.models"

now = -> new Date().getTime()

class models.SettingsModel extends Backbone.Model

  constructor: ->
    super

    if localStorage.settings
      $.extend @attributes, JSON.parse localStorage.settings

    @bind "change", => @save()

  save: ->
    localStorage.settings = JSON.stringify @attributes


class models.StatusModel extends Backbone.Model

  defaults:
    status: "starting"

    cachedDraws: 0
    startDraws: 0
    userDraws: 0
    remoteDraws: 0

    totalDraws: 0


  constructor: ->
    super
    @loading = true
    @bind "change", =>
      if @get("status") is "ready"
        @loading = false
      @set totalDraws:(
        @get("cachedDraws") +
        @get("userDraws") +
        @get("remoteDraws") +
        @get("startDraws")
      )


  addUserDraw: (i=1)->
    @set userDraws: @get("userDraws") + i

  addRemoteDraw: (i=1)->
    if not @loading
      @set remoteDraws: @get("remoteDraws") + i

