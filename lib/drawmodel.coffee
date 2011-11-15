
_  = require 'underscore'

{GridStore} = require "mongodb"

mustBeOpened = (fn ) -> ->
  if not @_doc
    throw new Error "Cannot call before doc is loaded"

  fn.apply this, arguments

class exports.Drawing

  Drawing.collection = null
  Drawing.db = null

  cacheInterval: 10

  constructor: (@name, @position) ->
    @position = parseInt @position, 10

    @resolution =
      x: 0
      y: 0

    throw "Collection must be set" unless Drawing.collection
    @clients = {}
    @drawsAfterLastCache = 0

  # Unique string name for single slide. Used for Socket.io rooms
  getCombinedRoomName: ->
    "#{ @name }/#{ @position }"

  updateResolution: (point) ->
    @resolution.x = point.x if point.x > @resolution.x
    @resolution.y = point.y if point.y > @resolution.y



  addDraw: mustBeOpened (draw, cb=->) ->

    if not draw?.shape?.moves
      console.log "missing moves", draw
    else
      for point in draw.shape.moves
        @updateResolution point


    Drawing.collection.update
      name: @name,
      position: @position
    , $push: history: draw
    , (err, coll) =>
      return cb err if err
      @drawsAfterLastCache += 1
      if not @fethingBitmap and @drawsAfterLastCache >= @cacheInterval
        @fethingBitmap = true
        cb null, needCache: true
      else
        cb null

  _getImageDBName: (name) ->
    "image/#{ @name }/#{ @position }/#{ name }"

  saveImage: (name, data, cb=->) ->
    @_saveData @_getImageDBName(name), data, (err) =>
      return cb err if err
      attrs = {}
      attrs[name] = true
      @_setAttributes attrs, cb

  getImage: (name, cb) ->
    @_readData @_getImageDBName(name), cb


  _setAttributes: (attrs, cb=->) ->
    Drawing.collection.update
      name: @name,
      position: @position
    , $set: attrs
    , cb


  _saveData: (name, data, cb=->) ->
    console.log "SAving", name
    gs = new GridStore Drawing.db, name, "w"
    gs.open (err) ->
      return cb err if err
      gs.write data, (err, result) ->
        return cb err if err
        gs.close (err) -> cb err

  _readData: (name, cb=->) ->
    console.log "reading", name
    gs = new GridStore Drawing.db, name, "r"
    gs.open (err) ->
      return cb err if err
      gs.readBuffer gs.length, (err, data) ->
        return cb err if err
        gs.close ->
          cb null, data


  setCache: (drawCount, data, cb=->) ->
    @fethingBitmap = false
    @drawsAfterLastCache = 0
    @_saveData "#{ @_getImageDBName("cache") }-#{ drawCount }", data, =>
      Drawing.collection.update
        name: @name,
        position: @position
      , $push: cache: drawCount
      , (err) ->
        return cb err if err
        cb null


  getCache: (drawCount, cb=->) ->
    @_readData "#{ @_getImageDBName("cache") }-#{ drawCount }", cb


  getLatestCachePosition: (cb=->) =>
    @fetch (err, doc) =>

      return cb err if err

      if doc.cache.length is 0
        return cb message: "no cache"

      cb null, _.last doc.cache




  init: (cb=->) ->
    Drawing.collection.insert @_doc =
      name: @name
      position: @position
      history: []
      cache: []
      created: Date.now()
    , safe: true
    , (err, docs) =>
      return cb err if err
      cb null, docs[0]

  fetch: (cb=->) =>
    Drawing.collection.find(name: @name, position: @position).nextObject (err, doc) =>
      return cb err if err
      if doc
        @_doc = doc
        console.log "We have #{ doc.history.length } draws"
        for draw in doc.history
          for point in draw.shape?.moves
            @updateResolution point
        cb null, doc
      else
        @init cb


