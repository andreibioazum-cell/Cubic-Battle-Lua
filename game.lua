local joystick = require("joystick")

local game = {}

local cube = {
    x = 400,
    y = 300,
    size = 60,
    speed = 450,         -- было 150, теперь 450 (в 3 раза быстрее)
    color = {1, 0.5, 0.3},
    -- Сглаживание движения (lerp)
    velX = 0,
    velY = 0,
    accel = 12           -- скорость разгона/торможения
}

local backButton = {
    x = 20,
    y = 20,
    w = 100,
    h = 50
}

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x = w / 2
    cube.y = h / 2
    cube.velX = 0
    cube.velY = 0
    joystick.load(90, h - 90)
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()

    -- Получаем целевую скорость от джойстика
    local dx, dy = joystick.getDirection()
    local targetVelX = dx * cube.speed
    local targetVelY = dy * cube.speed

    -- Плавно интерполируем текущую скорость к целевой (анти-рывки)
    cube.velX = cube.velX + (targetVelX - cube.velX) * cube.accel * dt
    cube.velY = cube.velY + (targetVelY - cube.velY) * cube.accel * dt

    -- Двигаем кубик
    cube.x = cube.x + cube.velX * dt
    cube.y = cube.y + cube.velY * dt

    -- Границы
    cube.x = math.max(cube.size/2, math.min(w - cube.size/2, cube.x))
    cube.y = math.max(cube.size/2, math.min(h - cube.size/2, cube.y))
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    love.graphics.clear(0.08, 0.06, 0.15, 1)

    -- Сетка
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.setLineWidth(1)
    for i = 0, w, 50 do
        love.graphics.line(i, 0, i, h)
    end
    for i = 0, h, 50 do
        love.graphics.line(0, i, w, i)
    end

    -- Кубик с тенью
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill",
        cube.x - cube.size/2 + 5,
        cube.y - cube.size/2 + 5,
        cube.size, cube.size, 10, 10)

    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill",
        cube.x - cube.size/2,
        cube.y - cube.size/2,
        cube.size, cube.size, 10, 10)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        cube.x - cube.size/2,
        cube.y - cube.size/2,
        cube.size, cube.size, 10, 10)

    -- BACK
    love.graphics.setColor(0.4, 0.2, 0.5, 0.85)
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("BACK", backButton.x + 25, backButton.y + 13)

    joystick.draw()

    -- FPS
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

function game.touchpressed(id, x, y)
    if x >= backButton.x and x <= backButton.x + backButton.w and
       y >= backButton.y and y <= backButton.y + backButton.h then
        GameState.current = "lobby"
        return
    end
    joystick.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    joystick.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    joystick.touchreleased(id, x, y)
end

return game
