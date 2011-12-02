
_  = require 'underscore'
async = require "async"

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

  getQuery: ->
    name: @name,
    position: @position

  remove: (cb=->) ->
    @clearCache 0, (err) =>
      return cb err if err
      @deleteImage "background", (err) =>
        return cb err if err
        Drawing.collection.findAndModify @getQuery()
        , [['_id','asc']] # sorting
        , {} # update
        , remove: true # options
        , cb


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



  deleteImage: (name, cb=->) ->
    GridStore.unlink Drawing.db, @_getImageDBName(name), {}, (err) =>
      return cb err if err
      attrs = {}
      attrs[name] = 1
      Drawing.collection.update @getQuery()
      , $unset: attrs
      , cb


  # Use preserver=0 to clear all caches. preserve=1 to leave latest in cache,
  # preserve=2 to leave two latests cache points
  clearCache: (preserve, cb=->) ->
    if typeof preserve is "function"
      cb = preserve
      preserve = 0

    @fetch (err, doc) =>
      return cb err if err

      doc.cache.sort (a, b) -> b - a
      drawCounts = _.rest doc.cache, preserve

      # MongoDB does only in place write, so we can as well just delete in
      # series
      async.forEachSeries drawCounts, (drawCount, asyncCb) =>
        GridStore.unlink Drawing.db, @getCacheName(drawCount), {}, (err) =>
          Drawing.collection.update @getQuery()
          , $pull:
              cache: drawCount
          , asyncCb
      , cb


  _setAttributes: mustBeOpened (attrs, cb=->) ->
    Drawing.collection.update @getQuery()
    , $set: attrs
    , cb


  _saveData: (name, data, cb=->) ->
    gs = new GridStore Drawing.db, name, "w"
    gs.open (err) ->
      return cb err if err
      gs.write data, (err, result) ->
        return cb err if err
        gs.close (err) -> cb err

  _readData: (name, cb=->) ->
    gs = new GridStore Drawing.db, name, "r"
    gs.open (err) ->
      return cb err if err
      console.log "opened", name, "end"
      gs.readBuffer gs.length, (err, data) ->
        return cb err if err
        console.log "read", name
        gs.close (err) ->
          return cb err if err
          console.log "closed", name
          cb null, data

  getCacheName: (drawCount) ->
    "#{ @_getImageDBName("cache") }-#{ drawCount }"

  setCache: (drawCount, data, cb=->) ->
    @fethingBitmap = false
    @drawsAfterLastCache = 0
    @_saveData @getCacheName(drawCount), data, =>
      Drawing.collection.update @getQuery()
      , $push: cache: drawCount
      , (err) ->
        return cb err if err
        cb null


  getCache: (drawCount, cb=->) ->
    @_readData @getCacheName(drawCount), cb


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
    Drawing.collection.find(@getQuery()).nextObject (err, doc) =>
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


