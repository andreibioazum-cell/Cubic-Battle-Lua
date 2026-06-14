local controls = require("controls")

local game = {}

-- ===== ИГРОК =====
local player = {
    x = 0, y = 0,
    size = 60,
    speed = 220,
    vx = 0, vy = 0,
    accel = 18,
    dirX = 0, dirY = -1
}

-- ===== КАМЕРА =====
local cam = { x = 0, y = 0, smoothness = 12 }

-- ===== ФОН =====
local sand = { img = nil, w = 0, h = 0 }

local fontFps

function game.load()
    -- Сброс игрока и камеры
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    cam.x, cam.y = 0, 0

    -- Загружаем фон
    if not sand.img then
        local ok, img = pcall(love.graphics.newImage, "sand.png", {mipmaps=true})
        if ok then
            sand.img = img
            sand.img:setWrap("repeat", "repeat")
            sand.img:setFilter("linear", "linear", 4)
            sand.w, sand.h = sand.img:getWidth(), sand.img:getHeight()
        end
    end

    controls.load()
    fontFps = fontFps or love.graphics.newFont(14)
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    controls.reposition()

    -- Движение игрока от джойстика
    local inputX, inputY = controls.getMoveDir()
    if inputX ~= 0 or inputY ~= 0 then
        player.vx = player.vx + (inputX * player.speed - player.vx) * player.accel * dt
        player.vy = player.vy + (inputY * player.speed - player.vy) * player.accel * dt
        local len = math.sqrt(inputX*inputX + inputY*inputY)
        if len > 0.1 then
            player.dirX, player.dirY = inputX/len, inputY/len
        end
    else
        player.vx, player.vy = 0, 0
    end
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Камера
    cam.x = cam.x + (player.x - w/2 - cam.x) * cam.smoothness * dt
    cam.y = cam.y + (player.y - h/2 - cam.y) * cam.smoothness * dt

    -- Прицел и пули
    controls.update(dt, player.dirX, player.dirY)
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    -- Фон-тайлы
    if sand.img then
        love.graphics.setColor(1, 1, 1, 1)
        local offX = -(cam.x % sand.w)
        local offY = -(cam.y % sand.h)
        local cols = math.ceil(w / sand.w) + 1
        local rows = math.ceil(h / sand.h) + 1
        for r = 0, rows do
            for col = 0, cols do
                love.graphics.draw(sand.img, offX + col * sand.w, offY + r * sand.h)
            end
        end
    else
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end

    -- Игровой мир (со смещением камеры)
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    controls.drawWorld(player.x, player.y)

    -- Кубик
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", player.x - player.size/2 + 4, player.y - player.size/2 + 4, player.size, player.size, 10, 10)
    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", player.x - player.size/2, player.y - player.size/2, player.size, player.size, 10, 10)

    love.graphics.pop()

    -- UI поверх
    controls.drawUI()

    -- FPS
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(fontFps)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

function game.touchpressed(id, x, y)
    local action = controls.touchpressed(id, x, y, player.dirX, player.dirY)
    if action == "back" then
        GameState.current = "lobby"
    end
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    controls.touchreleased(id, player.x, player.y)
end

return game
