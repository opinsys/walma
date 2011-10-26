
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

  constructor: (@name) ->
    @resolution =
      x: 0
      y: 0

    throw "Collection must be set" unless Drawing.collection
    @clients = {}
    @drawsAfterLastCache = 0

  updateCanvasSize: (point) ->
    @resolution.x = point.x if point.x > @resolution.x
    @resolution.y = point.y if point.y > @resolution.y

  addDraw: mustBeOpened (draw, client, cb=->) ->
    if not client
      throw new Error "addDraw requires client as param"

    if not draw?.shape?.moves
      console.log "missing moves", draw
    else
      for point in draw.shape.moves
        @updateCanvasSize point

    Drawing.collection.update name: @name,
      $push: history: draw
    , (err, coll) =>
      return cb err if err
      cb null
      @drawsAfterLastCache += 1
      if not @fethingBitmap and @drawsAfterLastCache >= @cacheInterval
        console.log "Asking for bitmap from #{ client.id }"
        @fethingBitmap = true

        client.fetchBitmap (err, bitmap) =>
          @fethingBitmap = false
          if err
            console.log "Could not get cache bitmap #{ err.message } #{ client.id }"
          else
            @setCache bitmap.pos, bitmap.data
            @drawsAfterLastCache = 0


  setCache: (position, data, cb=->) ->
    gs = new GridStore Drawing.db, "#{ @name }-#{ position }", "w"
    gs.open (err) =>
      return cb err if err
      gs.write data, (err, result) =>
        return cb err if err
        gs.close =>
          Drawing.collection.update name: @name,
            $push: cache: position
          , (err) ->
            return cb err if err
            cb null


  getCache: (position, cb=->) ->
    gs = new GridStore Drawing.db, "#{ @name }-#{ position }", "r"
    gs.open (err) =>
      return cb err if err
      gs.read gs.length, (err, data) ->
        return cb err if err
        cb null, data


  getLatestCachePosition: (cb=->) =>
    @fetch (err, doc) =>

      return cb err if err

      if doc.cache.length is 0
        return cb message: "no cache"

      cb null, _.last doc.cache


  addClient: (client, cb=->) ->
    @clients[client.id] = client

    client.join @name

    client.on "draw", (draw) =>
      @addDraw draw, client

    client.on "disconnect", =>
      delete @clients[client.id]

    client.on "bitmap", (bitmap) =>
      console.log "Client sending bitmap #{ client.id }"

    @fetch (err, doc) =>
      return cb err if err

      latest = _.last doc.cache
      if latest
        history = doc.history.slice latest
      else
        history = doc.history

      client.startWith
        resolution: @resolution
        draws: history
        latestCachePosition: latest


  init: (cb=->) ->
    Drawing.collection.insert @_doc =
      name: @name
      history: []
      cache: []
      created: Date.now()
    ,
      safe: true
    , (err, docs) =>
      return cb err if err
      cb null, docs[0]

  fetch: (cb=->) =>
    Drawing.collection.find(name: @name).nextObject (err, doc) =>
      return cb err if err
      if doc
        @_doc = doc
        for draw in doc.history
          for point in draw.shape.moves
            @updateCanvasSize point
        cb null, doc
      else
        @init cb


