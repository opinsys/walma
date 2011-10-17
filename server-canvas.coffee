fs = require "fs"

tools = require "./shared/drawtools"
Canvas = require "canvas"

dbFile = __dirname + "/db.json"

db = JSON.parse fs.readFileSync dbFile

console.log Object.keys db

main = new Canvas(800, 800)
sketch = new Canvas(800, 800)
now = -> new Date().getTime()


start = now()

for draw in db.bug when draw
  tool = new tools[draw.shape.tool]
    sketch: sketch
    main: main

  tool.replay draw.shape


main.toBuffer (err, buf) ->
  fs.writeFile __dirname + "/public/server.png", buf, (err) ->
    throw err if err
    console.log "ok"
    console.log "took", (now() - start) / 1000
