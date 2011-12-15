
should = require "should"
assert = require "assert"
async = require "async"
_  = require 'underscore'

{Db, Connection, Server} = require "mongodb"


{Drawing} = require "../lib/drawmodel"
{Client} = require "../lib/client"

createExampleDraw = ->
  {"shape":{"color":"#ff0000","tool":"Pencil","size":100,"moves":[{"x":425,"y":741,"op":"down"},{"x":425,"y":741,"op":"move"}]},"user":"Epeli"}

# class FakeSocket extends EventEmitter
#   broadcast:
#     to: -> emit: ->
#   join: ->

db = new Db 'whiteboard-test',
    new Server "localhost", Connection.DEFAULT_PORT,
      # auto_reconnect: true


beforeEach (done) ->
  console.log "opening...."
  db.open (err) ->
    throw err if err
    db.collection "testdrawings", (err, coll) =>
      throw err if err
      console.log "setting coll"
      Drawing.collection = coll
      Drawing.db = db
      done()

afterEach (done) ->
  console.log "dropping...."
  db.dropDatabase (err) ->
    if err
      console.log "Error while dropping"
    else
      console.log "dropped"

    db.close ->
      console.log "closed"
      done()


describe "Just playing with mongodb driver in mocha", ->


  it "can insert", (done) ->
    async.series [
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          throw err if err
          coll.insert
            name: "foobar"
          , (err) ->
            cb()
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          coll.update name: "foobar",
            $push:
              foo:
                x: 101
                y: 200
                op: "move"
          , (err) ->
            cb()
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          coll.find(name: "foobar").nextObject (err, doc) ->
            throw err if err
            cb(doc)
    ], (doc) ->


      doc.foo?[0].x.should.equal 101
      done()



describe "Drawing", ->

  room = null
  beforeEach (done) ->
    console.log "new room"
    room = new Drawing "image room"
    room.fetch done

  it "updates the time stamp", (done) ->
    firstModified = null
    async.series [
      (cb) -> room.addDraw createExampleDraw(), cb
    ,
      (cb) -> room.fetch (err, doc) ->
        return cb err if err
        firstModified = doc.modified
        isFinite(firstModified).should.be.true
        cb()
      ,
      (cb) -> setTimeout cb, 1000
    ,
      (cb) -> room.addDraw createExampleDraw(), cb
    ,
      (cb) -> room.fetch (err, doc) ->
        return cb err if err
        (doc.modified - firstModified).should.be.above 0
        cb()

    ], done


  it "can save and read the image", (done) ->
      room.saveImage "testdata", new Buffer([ 1, 2, 3 ]), (err) ->
        throw err if err
        room.getImage "testdata", (err, data) ->
          throw err if err
          data[0].should.equal 1
          data[1].should.equal 2
          data[2].should.equal 3
          room.fetch (err, doc) ->
            throw err if err
            doc['testdata'].should.equal true
          done()


  it "can cache drawing", (done) ->

    async.waterfall [
      (cb) -> room.setCache 3, new Buffer([1,2,3]), cb
    ,
      (cb) -> room.setCache 10, new Buffer([4,5,6]), cb
    ,
      (cb) -> room.getLatestCachePosition (err, cachePosition) ->
        return cb err if err
        cachePosition.should.equal 10, "latest cache pos is 10"
        cb null, cachePosition
    ,
      (cachePosition, cb) -> room.getCache cachePosition, (err, data) ->
        return cb err if err
        data[0].should.equal 4, "data in latest cache is 4"
        cb()
    ], done





  it "can delete saved image", (done) ->
    room.saveImage "testdata", new Buffer([ 1, 2, 3 ]), (err) ->
      room.deleteImage "testdata", (err) ->
        throw err if err

        room.getImage "testdata", (err) ->
          should.exist err, "should get error when reading deleted image"
          err.message.should.equal 'File does not exist'

          room.fetch (err, doc) ->
            throw err if err
            should.not.exist doc['testdata'],
              "reference to saved image should have been removed. Is: #{ doc['testdata'] }"
            done()



  it "can remove itself", (done) ->
    async.series [
      (cb) -> room.addDraw createExampleDraw(), cb
    ,
      (cb) -> room.remove cb # The method we are testing
    ,
      (cb) -> room.fetch (err, doc) ->
        return cb err if err
        doc.history.should.have.lengthOf 0, "history should be empty after deletion"
        cb()
    ], done


  it "can remove itself and all images relating to it", (done) ->
    async.series [
      (cb) -> room.setCache 3, new Buffer([1,2,3]), cb
    ,
      (cb) -> room.saveImage "background", new Buffer([4,5,6]), cb
    ,
      (cb) -> room.addDraw createExampleDraw(), cb
    ,
      (cb) -> room.remove cb # The method we are testing
    ,
      (cb) -> room.fetch (err, doc) ->
        return cb err if err
        doc.history.should.have.lengthOf 0, "history should be empty after deletion"
        doc.cache.should.have.lengthOf 0, "cache points should have been cleared"
        cb()
    ,
      (cb) -> room.getCache 3, (err, data) ->
        should.exist err, "cache images should have been deleted"
        cb()
    ,
      (cb) -> room.getImage "background", (err, data) ->
        should.exist err, "background image should have been deleted"
        cb()

    ], done



  it "can find expired rooms", (done) ->
    orig = Drawing::inactivityThreshold
    Drawing::inactivityThreshold = 100
    room.addDraw createExampleDraw(), (err) ->
      throw err if err
      # Expire room
      activeRoom = new Drawing "active room"
      activeRoom.fetch (err) ->
        throw err if err
        console.log "waiting"
        setTimeout ->
          activeRoom.addDraw createExampleDraw(), (err) ->
            throw err if err
            console.log "waited"
            Drawing.findExpiredRooms (err, rooms) ->
              for r in rooms
                console.log r.toString()
              rooms.should.have.lengthOf 1
              Drawing::inactivityThreshold = orig
              done()
        , 1000



  it "gets expired", (done) ->
    room.inactivityThreshold = 100
    setTimeout ->
      room.hasExpired().should.be.ok
      done()
    , 200


  it "is not yet expired", (done) ->
    setTimeout ->
      room.hasExpired().should.not.be.ok
      done()
    , 200

  it "gets deleted by default when it is inactive", (done) ->
    room.inactivityThreshold = 100
    room.addDraw createExampleDraw(), (err) ->
      throw err if err
      setTimeout ->
        room.fetch (err, doc) ->
          throw err if err
          doc.history.should.have.lengthOf 0, "Inactivity should have destroyed the drawing"
          done()
      , 200


  it "does not get deleted automatically if it is persisted", (done) ->
    room.inactivityThreshold = 100
    async.series [
      (cb) -> room.addDraw createExampleDraw(), cb
    ,
      (cb) -> room.fetch cb
    ,
      (cb) -> room.persist cb
    ,
      (cb) -> setTimeout cb, 200
    ,
      (cb) ->
        room.fetch (err, doc) ->
          return cb err if err
          doc.history.should.have.lengthOf 1
          cb()
    ], done





describe "clearCache method in drawing", ->

  room = null
  beforeEach (done) ->
    room = new Drawing "cache room"
    room.fetch (err) ->
      throw err if err
      room.setCache 3, new Buffer([1,2,3]), (err) ->
        throw err if err
        room.setCache 10, new Buffer([4,5,6]), (err) ->
          throw err if err
          done()

  it "removes the actual cache images", (done) ->
    room.clearCache 0, (err) ->
      throw err if err
      room.getCache 10, (err, data) ->
        should.not.exist data
        should.exist err
        done()

  it "clears the cache array", (done) ->
    room.clearCache 0, (err) ->
      throw err if err
      room.fetch (err, doc) ->
        throw err if err
        doc.cache.should.have.lengthOf 0
        done()


  it "with preserve=1 leaves one cache image", (done) ->
    room.clearCache 1, (err) ->
      throw err if err
      room.getCache 10, (err, data) ->
        should.not.exist err
        data[0].should.equal 4
        data[1].should.equal 5
        data[2].should.equal 6
        done()

  it "with preserve=1 leaves one cache image", (done) ->
    room.clearCache 1, (err) ->
      throw err if err
      room.fetch (err, doc) ->
        throw err if err
        doc.cache.should.have.lengthOf 1
        doc.cache[0].should.equal 10
        done()



describe "cache request in drawing", ->

  room = null
  beforeEach (done) ->
    room = new Drawing "cache request"
    room.cacheThreshold = 10
    room.fetch (err) ->
      throw err if err
      async.forEachSeries [1..9], (i, cb) ->
        room.addDraw createExampleDraw(), cb
      , done

  it "ask for cache when interval occurs", (done) ->
    room.addDraw createExampleDraw(), (err, result) ->
      throw err if err
      result.needCache.should.be.true
      done()

  it "does not lose cache counting when refetched", (done) ->
    room2 = new Drawing "cache request"
    room2.cacheThreshold = 10
    room2.fetch (err, doc) ->
      throw err if err
      room.drawsAfterLastCache.should.equal 9
      console.log "Adding draw in test"
      room2.addDraw createExampleDraw(), (err, result) ->
        throw err if err
        room2.drawsAfterLastCache.should.equal 10
        result.needCache.should.be.true
        done()



