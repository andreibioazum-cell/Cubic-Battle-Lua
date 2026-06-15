local controls = require("controls")

local game = {}

local cube = {
    x = 400,
    y = 300,
    size = 60,
    speed = 300,
    color = {1, 0.5, 0.3}
}

local fontFPS

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x = w / 2
    cube.y = h / 2

    controls.load()

    fontFPS = love.graphics.newFont(12)
end

function game.resize(w, h)
    controls.resize(w, h)
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

    love.graphics.clear(0.1, 0.1, 0.15, 1)

    -- Куб
    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill",
        cube.x - cube.size/2,
        cube.y - cube.size/2,
        cube.size, cube.size, 10, 10)

    controls.draw()

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.setFont(fontFPS)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 90, 10)
end

function game.touchpressed(id, x, y)
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    controls.touchreleased(id, x, y)
end

return game
