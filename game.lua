local joystick = require("joystick")

local game = {}

local cube = {
    x = 0, y = 0,
    size = 60,
    speed = 450,
    color = {1, 0.5, 0.3},
    velX = 0, velY = 0,
    accel = 18,
    -- Последнее направление движения (для прицела если не нажимаешь)
    lastDirX = 0,
    lastDirY = -1
}

local camera = {
    x = 0, y = 0,
    smoothness = 12   -- быстрая камера (было 5)
}

local backButton = { x = 20, y = 20, w = 100, h = 50 }

-- Кнопка атаки (справа внизу)
local attackButton = { x = 0, y = 0, r = 70 }

-- Состояние атаки
local attack = {
    pressed = false,    -- удерживается ли кнопка
    touchId = nil,
    aimX = 0,           -- направление прицела (нормализованное)
    aimY = -1,
    aimLength = 200     -- длина прицельной линии
}

-- Пули
local bullets = {}
local BULLET_SPEED = 800
local BULLET_LIFETIME = 2.5

-- Фон
local sandImage = nil
local sandW, sandH = 0, 0

local function recalcUI()
    local w, h = love.graphics.getDimensions()
    attackButton.x = w - 100
    attackButton.y = h - 100
end

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x = 0
    cube.y = 0
    cube.velX = 0
    cube.velY = 0
    camera.x = 0
    camera.y = 0
    bullets = {}
    joystick.load(90, h - 90)
    recalcUI()

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
    recalcUI()

    -- Движение
    local dx, dy = joystick.getDirection()
    if dx ~= 0 or dy ~= 0 then
        local targetVelX = dx * cube.speed
        local targetVelY = dy * cube.speed
        cube.velX = cube.velX + (targetVelX - cube.velX) * cube.accel * dt
        cube.velY = cube.velY + (targetVelY - cube.velY) * cube.accel * dt
        -- запоминаем направление для прицела
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0.1 then
            cube.lastDirX = dx / len
            cube.lastDirY = dy / len
        end
    else
        -- Резкая остановка
        cube.velX = 0
        cube.velY = 0
    end

    cube.x = cube.x + cube.velX * dt
    cube.y = cube.y + cube.velY * dt

    -- Камера (быстрая)
    local targetCamX = cube.x - w / 2
    local targetCamY = cube.y - h / 2
    camera.x = camera.x + (targetCamX - camera.x) * camera.smoothness * dt
    camera.y = camera.y + (targetCamY - camera.y) * camera.smoothness * dt

    -- Прицел всегда в направлении lastDir
    if attack.pressed then
        attack.aimX = cube.lastDirX
        attack.aimY = cube.lastDirY
    end

    -- Пули
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bullets, i)
        end
    end
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    -- Фон (повторяющийся)
    if sandImage then
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
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end

    -- ИГРОВОЙ МИР (со смещением камеры)
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Прицел (серая линия от игрока)
    if attack.pressed then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        love.graphics.setLineWidth(3)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + attack.aimX * attack.aimLength,
            cube.y + attack.aimY * attack.aimLength
        )
        -- Крестик на конце прицела
        local tx = cube.x + attack.aimX * attack.aimLength
        local ty = cube.y + attack.aimY * attack.aimLength
        love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        love.graphics.circle("line", tx, ty, 12)
        love.graphics.line(tx - 8, ty, tx + 8, ty)
        love.graphics.line(tx, ty - 8, tx, ty + 8)
    end

    -- Пули
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.circle("fill", b.x, b.y, 6)
        love.graphics.setColor(1, 0.6, 0.1, 0.6)
        love.graphics.circle("fill", b.x, b.y, 10)
    end

    -- Кубик
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

    -- UI поверх
    -- BACK
    love.graphics.setColor(0.4, 0.2, 0.5, 0.85)
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("BACK", backButton.x + 25, backButton.y + 13)

    -- Кнопка АТАКИ (справа внизу)
    local atkColor = attack.pressed and {0.9, 0.3, 0.2} or {0.7, 0.2, 0.15}
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", attackButton.x + 3, attackButton.y + 4, attackButton.r)
    love.graphics.setColor(atkColor)
    love.graphics.circle("fill", attackButton.x, attackButton.y, attackButton.r)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", attackButton.x, attackButton.y, attackButton.r)
    -- Иконка пули (просто треугольник)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.print("FIRE", attackButton.x - 26, attackButton.y - 12)

    joystick.draw()

    -- FPS
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

function game.touchpressed(id, x, y)
    -- BACK
    if x >= backButton.x and x <= backButton.x + backButton.w and
       y >= backButton.y and y <= backButton.y + backButton.h then
        GameState.current = "lobby"
        return
    end

    -- Кнопка атаки
    local dx = x - attackButton.x
    local dy = y - attackButton.y
    if math.sqrt(dx*dx + dy*dy) <= attackButton.r then
        attack.pressed = true
        attack.touchId = id
        attack.aimX = cube.lastDirX
        attack.aimY = cube.lastDirY
        return
    end

    joystick.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    joystick.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    -- Если отпустили кнопку атаки → выстрел
    if attack.pressed and id == attack.touchId then
        attack.pressed = false
        attack.touchId = nil
        -- Создаём пулю
        table.insert(bullets, {
            x = cube.x,
            y = cube.y,
            vx = attack.aimX * BULLET_SPEED,
            vy = attack.aimY * BULLET_SPEED,
            life = BULLET_LIFETIME
        })
        return
    end

    joystick.touchreleased(id, x, y)
end

return game
