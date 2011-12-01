
should = require "should"
assert = require "assert"
async = require "async"
_  = require 'underscore'

{Db, Connection, Server} = require "mongodb"


{Drawing} = require "../lib/drawmodel"
{Client} = require "../lib/client"


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



describe "image saver", ->
  room = null
  beforeEach (done) ->
    console.log "new room"
    room = new Drawing "image room", 1
    room.fetch done

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

  it "can delete drawing", (done) ->
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







