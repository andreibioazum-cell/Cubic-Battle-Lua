local controls = require("controls")

local game = {}

local cube = {
    x = 0,
    y = 0,
    size = 60,
    speed = 300,
    color = {1, 0.5, 0.3}
}

local bg
local font

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x = w / 2
    cube.y = h / 2

    bg = love.graphics.newImage("grass.png")
    bg:setWrap("repeat", "repeat")

    font = love.graphics.newFont(12)
    controls.load()
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    local dx, dy = controls.getDirection()

    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    cube.x = math.max(cube.size/2, math.min(w - cube.size/2, cube.x))
    cube.y = math.max(cube.size/2, math.min(h - cube.size/2, cube.y))
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    love.graphics.setColor(1,1,1,1)
    local sx = w / bg:getWidth()
    local sy = h / bg:getHeight()
    love.graphics.draw(bg, 0, 0, 0, sx, sy)

    love.graphics.setColor(cube.color)
    love.graphics.rectangle(
        "fill",
        cube.x - cube.size/2,
        cube.y - cube.size/2,
        cube.size,
        cube.size,
        10,
        10
    )

    controls.draw()

    love.graphics.setColor(1,1,1,0.6)
    love.graphics.setFont(font)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 90, 10)
end

function game.touchpressed(id, x, y)
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    controls.touchreleased(id)
end

return game
