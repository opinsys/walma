
{EventEmitter} = require "events"
_  = require 'underscore'
async = require "async"

{GridStore} = require "mongodb"

mustBeOpened = (fn ) -> ->
  if not @_doc
    throw new Error "Cannot call before doc is loaded"

  fn.apply this, arguments

class exports.Drawing extends EventEmitter

  Drawing.collection = null
  Drawing.db = null

  cacheThreshold: 100

  # One hour
  inactivityThreshold: 1000 * 60 * 60

  constructor: (@name) ->

    @resolution =
      x: 0
      y: 0

    throw "Collection must be set" unless Drawing.collection

    @clients = []

    @drawsAfterLastCache = 0

  addClient: (c) ->
    @clients.push c

  removeClient: (c) ->
    pos = @clients.indexOf(c)
    if pos isnt -1
      @clients.splice pos, 1

    if @isEmpty()
      @emit "empty"

  isEmpty: ->
    @clients.length is 0

  # Unique string name for single slide. Used for Socket.io rooms
  getCombinedRoomName: ->
    console.log "Depracated call to getCombinedRoomName"
    "#{ @name }"

  updateResolution: (point) ->
    @resolution.x = point.x if point.x > @resolution.x
    @resolution.y = point.y if point.y > @resolution.y

  getQuery: ->
    name: @name

  remove: (cb=->) ->
    @_doc = null
    @clearCache 0, (err) =>
      return cb err if err
      @deleteImage "background", (err) =>
        return cb err if err
        Drawing.collection.findAndModify @getQuery()
        , [['_id','asc']] # sorting
        , {} # update
        , remove: true # options
        , cb

  toString: ->
    "<Drawing #{ @name } #{ @clients.length } clients>"

  addDraw: mustBeOpened (draw, cb=->) ->

    draw.timestamp = Date.now()

    if not draw?.shape?.moves
      console.log "missing moves", draw
    else
      for point in draw.shape.moves
        @updateResolution point


    Drawing.collection.update @getQuery()
    , $push: history: draw
    , (err, coll) =>
      return cb err if err

      @drawsAfterLastCache += 1
      console.log "Draws after last cache", @drawsAfterLastCache, @waitingForCache

      if not @waitingForCache and @drawsAfterLastCache >= @cacheThreshold
        @waitingForCache = true
        cb null, needCache: true
      else
        cb null

  _getImageDBName: (name) ->
    "image/#{ @name }/#{ name }"

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

    @fetch true, (err, doc) =>
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

  persist: (cb=->) ->
    @_setAttributes persistent: true, cb

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
      gs.readBuffer gs.length, (err, data) ->
        return cb err if err
        gs.close (err) ->
          return cb err if err
          cb null, data

  getCacheName: (drawCount) ->
    "#{ @_getImageDBName("cache") }-#{ drawCount }"

  setCache: (drawCount, data, cb=->) ->
    drawCount = parseInt drawCount, 10
    @waitingForCache = false
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
      history: []
      cache: []
      created: Date.now()
      modified: Date.now()
    , safe: true
    , (err, docs) =>
      return cb err if err
      cb null, docs[0]


  # Returns true if inactivity timeout has occured
  hasExpired: mustBeOpened (cb) ->

    Date.now() - @_doc.modified > @inactivityThreshold


  # Force gets always the drawing. If not set the drawing will be deleted if it
  # has been expired.
  fetch: (force, cb=->) =>
    if typeof force is "function"
      cb = force
      force = false

    Drawing.collection.find(@getQuery()).nextObject (err, doc) =>
      return cb err if err
      if doc

        for draw in doc.history
          for point in draw.shape?.moves
            @updateResolution point


        if lastDraw = _.last(doc.history)
          doc.modified = lastDraw.timestamp
        else
          doc.modified = doc.created

        @drawsAfterLastCache = doc.history.length - (_.last(doc.cache) or 0)

        @_doc = doc

        if not force and @hasExpired() and not doc.persistent
          @remove (err) =>
            return cb err if err
            @init cb

          return

        cb null, doc
      else
        @init cb


