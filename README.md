
# Collaborative whiteboard

## Protocol

CoffeeScriptyfied JSON

    board: "mathclass"
    history: [
        tool: "pencil",
        user: "esa",
        time: 1317890572951,
        color: "red",
        moves: [
            down: { x: 100, y: 100 }
        ,
            move: { x: 100, y: 100 }
        ,
            move: { x: 200, y: 200 }
        ,
            move: { x: 100, y: 200 }
        ,
            move: { x: 0, y: 200 }
        ,
            up: { x: 0, y: 200 }
        ]
    ,
        tool: "line",
        user: "matti",
        time: 1317890572961,
        color: "green"
        moves:
            down: { x: 300, y: 300 }
        ,
            end: { x: 400, y: 400 }
    ]


# Installing

Install Node.js and npm.

    git clone git@github.com:opinsys/puavo-whiteboard.git
    cd puavo-whiteboard

Install dependencies

    npm install --dev

Develop run

    bin/develop

Production execute

    npm start


## Issues with node-canvas

https://github.com/LearnBoost/node-canvas/issues/109#issuecomment-1804833
