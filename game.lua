local controls = require("controls")
local enemy = require("enemy")

local game = {}

-- Константы
local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15

-- Локальные переменные
local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = PLAYER_HP_MAX, hit = 0 }
local bullets = {}
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false
local onDeathCallback = nil

-- Онлайн переменные
local mode = "offline"  -- "offline", "client", "host"
local socket = nil
local connected = false
local player_id = 0
local players = {}  -- Другие игроки
local last_send = 0
local send_interval = 1 / 20
local server = nil
local online_bullets = {}  -- Пули от других игроков

-- ============================================================
-- ФУНКЦИИ ОТРИСОВКИ
-- ============================================================

local function drawHPBar(x, y, w, h, hp, max, color)
    hp = math.max(0, hp)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4, 4, 4)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", x, y, w * (hp / max), h, 4, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

-- ============================================================
-- СОЗДАНИЕ ПУЛИ
-- ============================================================

local function spawnBullet(x, y, dx, dy)
    -- Добавляем пулю локально
    table.insert(bullets, {
        x = x,
        y = y,
        vx = dx * BULLET_SPEED,
        vy = dy * BULLET_SPEED,
        life = 3
    })
    
    -- Отправляем на сервер если в онлайне
    if connected and socket then
        pcall(function()
            socket:send(string.format("SHOOT:dx:%.2f,dy:%.2f\n", dx, dy))
        end)
    end
end

-- ============================================================
-- ОБРАБОТЧИК УРОНА
-- ============================================================

local function onHitPlayer(dmg)
    if dead then return end
    cube.hp = cube.hp - dmg
    cube.hit = 1
    if cube.hp <= 0 then
        cube.hp = 0
        dead = true
        if onDeathCallback then
            onDeathCallback()
        end
    end
end

-- ============================================================
-- ПУБЛИЧНЫЕ ФУНКЦИИ
-- ============================================================

function game.setOnDeath(callback)
    onDeathCallback = callback
end

function game.setMode(new_mode)
    mode = new_mode
    print("🎮 Режим: " .. mode)
end

function game.connect(ip, port)
    local success, socket_lib = pcall(require, "socket")
    if not success then
        print("❌ LuaSocket не установлен")
        return false
    end
    
    socket = socket_lib.tcp()
    socket:settimeout(0.1)
    
    local success, err = socket:connect(ip, port)
    if success then
        connected = true
        print("✅ Подключено к серверу " .. ip .. ":" .. port)
        return true
    else
        print("❌ Ошибка подключения: " .. tostring(err))
        socket = nil
        connected = false
        return false
    end
end

function game.disconnect()
    if connected and socket then
        pcall(function() socket:close() end)
        socket = nil
        connected = false
    end
    players = {}
    online_bullets = {}
    game.setMode("offline")
end

function game.load()
    -- Сброс состояния
    cube.x = 0
    cube.y = 0
    cube.angle = 0
    cube.hp = PLAYER_HP_MAX
    cube.hit = 0
    dead = false
    bullets = {}
    players = {}
    online_bullets = {}
    cam.x = -love.graphics.getWidth() / 2
    cam.y = -love.graphics.getHeight() / 2

    -- Загрузка ресурсов
    bg = bg or love.graphics.newImage("grass.png")
    if bg then
        bg:setWrap("repeat", "repeat")
    end

    playerImg = playerImg or love.graphics.newImage("player.png")
    if playerImg then
        playerImg:setFilter("nearest", "nearest")
    end

    font = font or love.graphics.newFont("Fredoka-Bold.ttf", 16)

    controls.load()
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x, cube.y)

    enemy.setDeathCallback(function()
        GameState.current = "lobby"
    end)

    controls.setOnBack(function()
        game.disconnect()
        GameState.current = "lobby"
    end)
    
    game.setMode("offline")
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    if dead then 
        -- Даже в смерти обновляем контролы для кнопки Back
        controls.update(dt)
        return 
    end
    
    controls.update(dt)
    
    -- ============================================================
    -- ДВИЖЕНИЕ ИГРОКА (всегда работает)
    -- ============================================================
    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    cube.hit = math.max(0, cube.hit - dt * 3)

    -- ============================================================
    -- КАМЕРА (всегда работает)
    -- ============================================================
    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

    -- ============================================================
    -- ОБНОВЛЕНИЕ ПУЛЬ (всегда работает)
    -- ============================================================
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bullets, i)
        end
    end
    
    -- Обновляем онлайн пули
    for i = #online_bullets, 1, -1 do
        local b = online_bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(online_bullets, i)
        end
    end

    -- ============================================================
    -- ОФФЛАЙН РЕЖИМ (враг)
    -- ============================================================
    if mode == "offline" then
        enemy.update(dt, cube.x, cube.y, bullets, onHitPlayer)
    end
    
    -- ============================================================
    -- ОНЛАЙН РЕЖИМ (клиент)
    -- ============================================================
    if mode == "client" or mode == "host" then
        if connected and socket then
            -- Отправка позиции
            last_send = last_send + dt
            if last_send >= send_interval then
                last_send = 0
                pcall(function()
                    socket:send(string.format(
                        "MOVE:x:%.2f,y:%.2f,angle:%.2f,hp:%d\n",
                        cube.x, cube.y, cube.angle, cube.hp
                    ))
                end)
            end
            
            -- Получение данных
            while true do
                local data, err = socket:receive("*l")
                if not data then break end
                
                -- Обработка команд
                if data:sub(1, 10) == "CONNECTED:" then
                    player_id = tonumber(data:sub(11))
                    print("🎮 Получен ID: " .. player_id)
                    
                elseif data:sub(1, 12) == "PLAYER_JOIN:" then
                    local parts = {}
                    for part in data:gmatch("[^:]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 6 then
                        local pid = tonumber(parts[2])
                        if pid ~= player_id then
                            players[pid] = {
                                x = tonumber(parts[3]),
                                y = tonumber(parts[4]),
                                angle = tonumber(parts[5]),
                                hp = tonumber(parts[6])
                            }
                        end
                    end
                    
                elseif data:sub(1, 12) == "PLAYER_LEFT:" then
                    local pid = tonumber(data:sub(13))
                    players[pid] = nil
                    
                elseif data:sub(1, 7) == "BULLET:" then
                    local parts = {}
                    for part in data:gmatch("[^:]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 6 then
                        table.insert(online_bullets, {
                            id = tonumber(parts[2]),
                            x = tonumber(parts[3]),
                            y = tonumber(parts[4]),
                            vx = tonumber(parts[5]),
                            vy = tonumber(parts[6]),
                            life = 3.0
                        })
                    end
                    
                elseif data:sub(1, 4) == "HIT:" then
                    local parts = {}
                    for part in data:gmatch("[^:]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 3 then
                        local target_id = tonumber(parts[2])
                        local damage = tonumber(parts[3])
                        if target_id == player_id then
                            onHitPlayer(damage)
                        end
                    end
                    
                elseif data:sub(1, 14) == "PLAYER_UPDATE:" then
                    local parts = {}
                    for part in data:gmatch("[^:]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 8 then
                        local pid = tonumber(parts[2])
                        if pid ~= player_id then
                            if not players[pid] then players[pid] = {} end
                            players[pid].x = tonumber(parts[3])
                            players[pid].y = tonumber(parts[4])
                            players[pid].angle = tonumber(parts[5])
                            players[pid].hp = tonumber(parts[6])
                        end
                    end
                end
            end
        end
    end
end

function game.draw()
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local w, h = love.graphics.getDimensions()
    if bg then
        local tw, th = bg:getWidth(), bg:getHeight()
        local sX = math.floor(cam.x / tw) * tw
        local sY = math.floor(cam.y / th) * th
        for x = sX, sX + w + tw, tw do
            for y = sY, sY + h + th, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end

    -- Свои пули (черные)
    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end
    
    -- Онлайн пули (красные)
    for _, b in ipairs(online_bullets) do
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end

    -- Прицел
    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(14)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
    end

    -- Оффлайн: рисуем врага
    if mode == "offline" then
        enemy.draw()
    end
    
    -- Онлайн: рисуем других игроков
    if mode == "client" or mode == "host" then
        for pid, p in pairs(players) do
            if pid ~= player_id then
                if playerImg then
                    love.graphics.setColor(0.3, 0.3, 0.8, 0.4)
                    love.graphics.push()
                    love.graphics.translate(p.x + 4, p.y + 6)
                    love.graphics.rotate(p.angle or 0)
                    love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
                    love.graphics.pop()
                    
                    love.graphics.push()
                    love.graphics.translate(p.x, p.y)
                    love.graphics.rotate(p.angle or 0)
                    love.graphics.setColor(0.4, 0.4, 0.9, 1)
                    love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
                    love.graphics.pop()
                end
                
                drawHPBar(p.x - 30, p.y - 50, 60, 6, p.hp or 5, 5, {0.3, 0.8, 0.3})
            end
        end
    end

    -- Свой игрок
    if playerImg then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        local t = cube.hit
        love.graphics.setColor(1, 1 - t * 0.6, 1 - t * 0.6, 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()
    end

    love.graphics.pop()

    -- HUD
    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    -- HP игрока
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    -- HP врага (только оффлайн)
    if mode == "offline" then
        local e_obj = enemy.get()
        if e_obj then
            local ex = love.graphics.getWidth() - barW - margin
            drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("ENEMY " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
        end
    end
    
    -- Статус онлайн
    if mode == "client" then
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.print("ONLINE | ID: " .. player_id, love.graphics.getWidth() - 200, margin)
        love.graphics.print("Игроков: " .. (#players + 1), love.graphics.getWidth() - 200, margin + 20)
    elseif mode == "host" then
        love.graphics.setColor(1, 0.8, 0, 0.7)
        love.graphics.print("👑 HOST | ID: " .. player_id, love.graphics.getWidth() - 200, margin)
        love.graphics.print("Игроков: " .. (#players + 1), love.graphics.getWidth() - 200, margin + 20)
    end

    controls.draw()
end

function game.touchpressed(id, x, y)
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then
        spawnBullet(cube.x, cube.y, dx, dy)
    end
end

function game.keypressed(key)
    if key == "escape" then
        game.disconnect()
        GameState.current = "lobby"
    end
end

return game
