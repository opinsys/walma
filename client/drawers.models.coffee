Backbone = require "backbone"
_  = require 'underscore'

models = NS "PWB.drawers.models"

now = -> new Date().getTime()

class models.SettingsModel extends Backbone.Model

  defaults:
    size: 20
    color: "cyan"


class models.StatusModel extends Backbone.Model

  defaults:
    status: "starting"
    operationCount: 0
    inHistory: 0
    drawnFromHistory: 0
    historyDrawTime: 0

  constructor: ->
    super

    @bind "change", =>
      if @start
        diff = (now() - @start) / 1000
        @set historyDrawTime: diff, silent: true

  toJSON: ->
    json = super
    json.speed = parseInt json.operationCount / json.historyDrawTime
    json

  loadOperations: (history) ->

    operationCount = _.reduce history, (memo, draw) ->
      return memo unless draw?.shape?.moves
      memo + draw.shape.moves.length
    , 0

    @set
      operationCount: operationCount
      inHistory: operationCount


  incOperationCount: (amount) ->
    amount ?= 0
    @set operationCount: @get("operationCount") + amount

  incDrawnFromHistory: (amount) ->
    @start ?= now()
    amount ?= 0
    @set drawnFromHistory: @get("drawnFromHistory") + amount

  setDrawnHistory: ->
    @start = null
    @set drawnFromHistory: @get("inHistory")



  addDraw: (draw) ->
    @incOperationCount draw.shape.moves.length

  addShape: (shape) ->
    @incOperationCount shape.moves.length


