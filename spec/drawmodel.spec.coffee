
model = require "../lib/drawmodel"
async = require "async"

{Db, Connection, Server} = require "mongodb"

{Drawing} = require "../lib/drawmodel"

prepare = (cb) ->
  this.db = db = new Db('whiteboard-test', new Server("localhost", Connection.DEFAULT_PORT))
  db.open (err, db) ->
    if err
      console.log "Could not open the db", err
      throw err
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
    console.log "loading collection"
    this.db.collection "testdrawings", (err, coll) =>
      throw err if err
      this.collection = coll
      asyncSpecDone()

  it "gets collection", ->
    drawing = new Drawing "test", this.collection
    expect(drawing.collection).toBeTruthy()

  it "gets initialized if not existing", ->
    asyncSpecWait()
    drawing = new Drawing "not existing", this.collection
    drawing.fetch (err, doc) ->
      expect(err).toBeFalsy()
      expect(doc.created).toBeTruthy()
      asyncSpecDone()

  it "does not create twice", ->
    asyncSpecWait()
    drawing = new Drawing "test2", this.collection
    drawing.fetch (err, doc) =>
      throw err if err
      expect(doc.created).toBeTruthy()
      drawing2 = new Drawing "test2", this.collection
      drawing2.fetch (err, doc2) ->
        throw err if err
        expect(doc2.created).toEqual doc.created
        asyncSpecDone()

  it "can append draws", ->
    asyncSpecWait()
    name = "test3"
    drawing = new Drawing name, this.collection
    drawing.fetch (err, doc) =>
      throw err if err
      expect(doc.created).toBeTruthy()
      drawing.addDraw
        op: "move"
        x: 100
        y: 200
      , (err) =>
        throw err if err
        drawing3 = new Drawing name, this.collection
        drawing3.fetch (err, doc) =>
          throw err if err
          expect(doc.history[0]).toEqual
            op: "move"
            x: 100
            y: 200
          asyncSpecDone()






