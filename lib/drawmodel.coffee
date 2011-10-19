

class exports.Drawing

  Drawing.collection = null
  cacheInterval: 500

  constructor: (@name) ->
    throw "Collection must be set" unless Drawing.collection
    @clients = {}

  addDraw: (draw, cb) ->
    Drawing.collection.update name: @name,
      $push: history: draw
    , (err, coll) -> cb? err


  addClient: (client, cb) ->
    @clients[client.id] = client

    client.join @name

    client.on "draw", (draw) =>
      @addDraw draw

    client.on "disconnect", =>
      delete @clients[client.id]

    client.on "bitmap", (bitmap) =>
      console.log "Client sending bitmap #{ bitmap } #{ client.id }"

    @fetch (err, doc) =>
      return cb? err if err
      console.log "starting with 1", doc.history, client.startWith
      client.startWith doc.history

  addCachePoint: (pos, bitmap) ->


  fetch: (cb) ->

    Drawing.collection.find(name: @name).nextObject (err, doc) =>
      return cb? err if err
      if doc
        @_doc = doc
        cb null, doc
      else
        Drawing.collection.insert
          name: @name
          history: []
          created: Date.now()
        ,
          safe: true
        , (err, docs) =>
          return cb? err if err
          @_doc = doc
          cb null, docs[0]


