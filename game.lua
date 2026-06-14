local controls = require("controls")
local particles = require("particles")

local game = {}

-- ===== ИГРОК =====
local player = {
    x = 0, y = 0,
    size = 60,
    speed = 220,
    vx = 0, vy = 0,
    accel = 18,
    dirX = 0, dirY = -1,
    wasMoving = false  -- для отслеживания начала ходьбы
}

-- ===== КАМЕРА =====
local cam = { x = 0, y = 0, smoothness = 12 }

-- ===== ФОН =====
local sand = { img = nil, w = 0, h = 0 }

local fontFps

function game.load()
    -- Сброс
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    cam.x, cam.y = 0, 0
    particles.clear()
    
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
    
    -- Движение игрока
    local inputX, inputY = controls.getMoveDir()
    local isMoving = (inputX ~= 0 or inputY ~= 0)
    
    if isMoving then
        player.vx = player.vx + (inputX * player.speed - player.vx) * player.accel * dt
        player.vy = player.vy + (inputY * player.speed - player.vy) * player.accel * dt
        local len = math.sqrt(inputX*inputX + inputY*inputY)
        if len > 0.1 then
            player.dirX, player.dirY = inputX/len, inputY/len
        end
        
        -- 🔥 ЧАСТИЦЫ ПРИ ХОДЬБЕ
        if not player.wasMoving then
            -- Первый шаг — вспышка
            particles.burst(player.x, player.y + player.size/3, 5, particles.WALK)
        elseif math.random() < 0.3 then
            -- Постоянные частицы
            particles.spawn(
                player.x - player.dirX * 15, 
                player.y - player.dirY * 15 + player.size/3,
                particles.WALK
            )
        end
    else
        player.vx, player.vy = 0, 0
    end
    player.wasMoving = isMoving
    
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    
    -- Камера
    cam.x = cam.x + (player.x - w/2 - cam.x) * cam.smoothness * dt
    cam.y = cam.y + (player.y - h/2 - cam.y) * cam.smoothness * dt
    
    -- Прицел и пули
    controls.update(dt, player.dirX, player.dirY)
    
    -- 🔥 ОБНОВЛЯЕМ ЧАСТИЦЫ
    particles.update(dt)
end

function game.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Фон
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
    
    -- Игровой мир
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)
    
    -- 🔥 ЧАСТИЦЫ (под игроком)
    particles.draw()
    
    controls.drawWorld(player.x, player.y)
    
    -- Кубик игрока
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", player.x - player.size/2 + 4, player.y - player.size/2 + 4, 
        player.size, player.size, 10, 10)
    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, 
        player.size, player.size, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", player.x - player.size/2, player.y - player.size/2, 
        player.size, player.size, 10, 10)
    
    love.graphics.pop()
    
    -- UI
    controls.drawUI()
    
    -- FPS
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(fontFps)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

-- Модифицируем controls.lua для частиц при выстреле
local oldTouchReleased = controls.touchreleased
function controls.touchreleased(id, x, y)
    oldTouchReleased(id, x, y)
    -- 🔥 ЧАСТИЦЫ ПРИ ВЫСТРЕЛЕ
    if #controls.bullets > 0 then
        local lastBullet = controls.bullets[#controls.bullets]
        particles.burst(lastBullet.x, lastBullet.y, 12, particles.SHOOT)
    end
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
