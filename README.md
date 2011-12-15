
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

    git clone git://github.com/opinsys/walma.git
    cd walma

Install dependencies

    npm install

Develop run

    bin/develop

Production execute

    npm start



# Copyright


Copyright © 2010 Opinsys Oy

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301, USA.


