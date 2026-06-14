local joystick = require("joystick")

local game = {}

local cube = {
    x = 400,
    y = 300,
    size = 60,
    speed = 450,
    color = {1, 0.5, 0.3},
    velX = 0,
    velY = 0,
    accel = 18           -- увеличил для более резкого разгона
}

-- Камера
local camera = {
    x = 0,
    y = 0,
    smoothness = 5       -- чем больше — тем быстрее камера догоняет игрока
}

local backButton = {
    x = 20,
    y = 20,
    w = 100,
    h = 50
}

-- Фон
local sandImage = nil
local sandQuad = nil
local sandW, sandH = 0, 0

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x = 0
    cube.y = 0
    cube.velX = 0
    cube.velY = 0
    camera.x = 0
    camera.y = 0
    joystick.load(90, h - 90)

    -- Загружаем фоновую текстуру
    if not sandImage then
        local ok, img = pcall(love.graphics.newImage, "sand.png")
        if ok then
            sandImage = img
            sandImage:setWrap("repeat", "repeat")
            sandImage:setFilter("nearest", "nearest")
            sandW = sandImage:getWidth()
            sandH = sandImage:getHeight()
        end
    end
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()

    local dx, dy = joystick.getDirection()
    local targetVelX = dx * cube.speed
    local targetVelY = dy * cube.speed

    -- РЕЗКАЯ остановка, плавный разгон
    if dx == 0 and dy == 0 then
        cube.velX = 0
        cube.velY = 0
    else
        cube.velX = cube.velX + (targetVelX - cube.velX) * cube.accel * dt
        cube.velY = cube.velY + (targetVelY - cube.velY) * cube.accel * dt
    end

    cube.x = cube.x + cube.velX * dt
    cube.y = cube.y + cube.velY * dt

    -- Плавная камера (lerp к позиции игрока)
    local targetCamX = cube.x - w / 2
    local targetCamY = cube.y - h / 2
    camera.x = camera.x + (targetCamX - camera.x) * camera.smoothness * dt
    camera.y = camera.y + (targetCamY - camera.y) * camera.smoothness * dt
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    -- Фон через mesh с повтором (если есть картинка)
    if sandImage then
        -- Делаем UV-координаты так чтобы текстура повторялась через всю камеру
        local uOff = camera.x / sandW
        local vOff = camera.y / sandH
        local uMax = uOff + w / sandW
        local vMax = vOff + h / sandH

        local mesh = love.graphics.newMesh({
            {0, 0, uOff, vOff, 1, 1, 1, 1},
            {w, 0, uMax, vOff, 1, 1, 1, 1},
            {w, h, uMax, vMax, 1, 1, 1, 1},
            {0, h, uOff, vMax, 1, 1, 1, 1},
        }, "fan", "static")
        mesh:setTexture(sandImage)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(mesh, 0, 0)
    else
        -- Запасной фон если sand.png нет
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end

    -- Применяем смещение камеры для игровых объектов
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

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

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        cube.x - cube.size/2,
        cube.y - cube.size/2,
        cube.size, cube.size, 10, 10)

    love.graphics.pop()

    -- UI поверх (BACK, джойстик, FPS) — НЕ зависит от камеры
    love.graphics.setColor(0.4, 0.2, 0.5, 0.85)
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("BACK", backButton.x + 25, backButton.y + 13)

    joystick.draw()

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
