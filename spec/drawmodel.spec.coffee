
{EventEmitter} = require "events"
async = require "async"
_  = require 'underscore'

{Db, Connection, Server} = require "mongodb"
{Drawing} = require "../lib/drawmodel"

{Client} = require "../lib/client"
model = require "../lib/drawmodel"


class FakeSocket extends EventEmitter
  join: ->

prepare = (cb) ->
  this.db = db = new Db('whiteboard-test', new Server("localhost", Connection.DEFAULT_PORT))
  db.open (err, db) ->
    if err
      console.log "Could not open the db"
      cb null
    else
      db.dropDatabase (err, result) -> cb()

beforeEach ->
  asyncSpecWait()
  prepare.call this, ->
    asyncSpecDone()

afterEach ->
  this.db.close()


# Just playing with mongodb driver.
describe "created mongodb connection", ->

  it "has it", ->
    expect(this.db).toBeTruthy()

  it "can insert", ->
    asyncSpecWait()
    db = this.db
    async.series [
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          throw err if err
          coll.insert
            name: "foobar"
          , cb
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          coll.update name: "foobar",
            $push:
              foo:
                x: 100
                y: 200
                op: "move"
          , cb
      (cb) ->
        db.collection "testingcollection", (err, coll) ->
          coll.find(name: "foobar").nextObject (err, doc) ->
            throw err if err
            expect(doc.foo[0].x).toBe 100
            cb()
    ], ->
      asyncSpecDone()



describe "Drawing in MongoDB", ->

  beforeEach ->
    asyncSpecWait()
    this.db.collection "testdrawings", (err, coll) =>
      throw err if err
      Drawing.collection = coll
      asyncSpecDone()

  it "can be created", ->
    drawing = new Drawing "test"

  it "gets initialized if not existing", ->
    asyncSpecWait()
    drawing = new Drawing "not existing"
    drawing.fetch (err, doc) ->
      expect(err).toBeFalsy()
      expect(doc.created).toBeTruthy()
      expect(doc.history).toEqual []
      asyncSpecDone()

  it "does not create twice", ->
    asyncSpecWait()
    drawing = new Drawing "test2"
    drawing.fetch (err, doc) =>
      throw err if err
      expect(doc.created).toBeTruthy()
      drawing2 = new Drawing "test2"
      drawing2.fetch (err, doc2) ->
        throw err if err
        expect(doc2.created).toEqual doc.created
        asyncSpecDone()

  it "can append draws", ->
    asyncSpecWait()
    name = "test3"
    drawing = new Drawing name
    drawing.fetch (err, doc) =>
      throw err if err
      created = doc.created
      expect(doc.created).toBeTruthy()
      drawing.addDraw
        op: "move"
        x: 100
        y: 200
      , (err) =>
        throw err if err
        drawing3 = new Drawing name
        drawing3.fetch (err, doc) =>
          throw err if err
          expect(doc.history[0]).toEqual
            op: "move"
            x: 100
            y: 200
          expect(doc.created).toBe created, "the document should not change"
          asyncSpecDone()



  it "initializes client with history", ->
    fakeSocket = new FakeSocket
    console.log "MY TEST!!"

    client = new Client fakeSocket,
      id: "testclient"
      userAgent: "sdafds"
    drawing = new Drawing "inittest"

    asyncSpecWait()

    fakeSocket.on "start", (history) ->
      console.log "GOT START", history, _.isArray history
      expect(_.isArray history).toBe true
      expect(history.length).toBe 0
      asyncSpecDone()

    drawing.addClient client
    expect(_.size drawing.clients).toBe 1

  it "send draws to the database via clients", ->
    fakeSocket = new FakeSocket
    console.log "MY TEST!!"

    client = new Client fakeSocket,
      id: "testclient2"
      userAgent: "sdafds"
    drawing = new Drawing "emittest"
    drawing.addClient client

    spyOn(drawing, "addDraw")

    fakeSocket.emit "draw",
      user: "epeli"
      moves: []



    expect(drawing.addDraw).toHaveBeenCalled()

