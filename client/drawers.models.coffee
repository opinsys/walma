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

  getBackgroundURL: ->
    "#{ window.location.origin }/#{ @get "roomName" }/#{ @get "position" }/bg"

  getPublishedImageURL: ->
    "#{ window.location.origin }/#{ @get "roomName" }/#{ @get "position" }/published.png"


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


  addClient: (client) ->
    clients = @get("clients") or {}
    clients[client.id] = client
    @set clients: clients

  removeClient: (client) ->
    clients = @get("clients") or {}
    delete clients[client.id]
    @set clients: clients


  getClientCount: ->
    _.size @get("clients") or {}


  addUserDraw: (i=1)->
    @set userDraws: @get("userDraws") + i

  addRemoteDraw: (i=1)->
    if not @loading
      @set remoteDraws: @get("remoteDraws") + i

