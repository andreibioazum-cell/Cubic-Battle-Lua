local controls = require("controls")
local server = require("server")  -- Добавляем сервер

local game = {}

-- Константы
local PLAYER_SIZE = 55
local BULLET_SPEED = 390

-- Локальные переменные
local player = { x = 0, y = 0, angle = 0, hp = 5, max_hp = 5, id = 0 }
local players = {}  -- Другие игроки
local bullets = {}  -- Все пули
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false

-- Режимы
local mode = "offline"  -- "offline", "client", "host"
local socket = nil
local connected = false
local player_id = 0
local last_send = 0
local send_interval = 1 / 20

local onDeathCallback = nil

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
-- РЕЖИМЫ ИГРЫ
-- ============================================================

function game.setMode(new_mode)
    mode = new_mode
    print("🎮 Режим: " .. mode)
end

function game.hostGame(port)
    -- Запускаем сервер
    if not server.start(port) then
        print("❌ Не удалось запустить сервер")
        return false
    end
    
    -- Подключаемся как клиент
    local success = game.connect("127.0.0.1", port)
    if success then
        game.setMode("host")
        print("👑 Вы хост игры")
        return true
    end
    
    return false
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
    if server.isRunning() then
        server.stop()
    end
    game.setMode("offline")
end

-- ============================================================
-- СОЗДАНИЕ ПУЛИ
-- ============================================================

local function spawnBullet(x, y, dx, dy)
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
    player.hp = player.hp - dmg
    if player.hp <= 0 then
        player.hp = 0
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

function game.load()
    -- Сброс состояния
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.angle = 0
    player.hp = 5
    player.max_hp = 5
    player.id = 0
    dead = false
    players = {}
    bullets = {}
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
    server.init()
    
    controls.setOnBack(function()
        game.disconnect()
        GameState.current = "lobby"
    end)
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    if dead then return end
    
    -- Если мы хост, обновляем сервер
    if mode == "host" and server.isRunning() then
        server.update(dt)
    end
    
    if not connected then return end
    
    -- Обновление контролов
    controls.update(dt)
    
    -- Движение игрока
    local dx, dy = controls.getMove()
    if dx ~= 0 or dy ~= 0 then
        player.x = player.x + dx * 260 * dt
        player.y = player.y + dy * 260 * dt
        player.angle = math.atan2(dy, dx) + math.pi / 2
    end
    
    -- Ограничение по экрану
    local w, h = love.graphics.getDimensions()
    player.x = math.max(PLAYER_SIZE/2, math.min(w - PLAYER_SIZE/2, player.x))
    player.y = math.max(PLAYER_SIZE/2, math.min(h - PLAYER_SIZE/2, player.y))
    
    -- Камера
    local targetX = player.x - love.graphics.getWidth() / 2
    local targetY = player.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k
    
    -- Отправка позиции на сервер
    last_send = last_send + dt
    if last_send >= send_interval then
        last_send = 0
        if connected and socket then
            pcall(function()
                socket:send(string.format(
                    "MOVE:x:%.2f,y:%.2f,angle:%.2f,hp:%d\n",
                    player.x, player.y, player.angle, player.hp
                ))
            end)
        end
    end
    
    -- Получение данных от сервера
    if connected and socket then
        while true do
            local data, err = socket:receive("*l")
            if not data then break end
            
            -- Парсинг команд
            if data:sub(1, 10) == "CONNECTED:" then
                player_id = tonumber(data:sub(11))
                player.id = player_id
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
                    table.insert(bullets, {
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
                        players[pid].alive = tonumber(parts[7]) == 1
                    end
                end
            end
        end
    end
    
    -- Обновление пуль
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
    love.graphics.setColor(1, 1, 1, 1)
    
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)
    
    -- Фон
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
    
    -- Пули
    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end
    
    -- Другие игроки
    for pid, p in pairs(players) do
        if pid ~= player_id and p.alive ~= false then
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
    
    -- Свой игрок
    if playerImg and not dead then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.push()
        love.graphics.translate(player.x + 6, player.y + 8)
        love.graphics.rotate(player.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()
        
        love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(player.angle)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()
    end
    
    -- Прицел
    if controls.isAiming() and not dead then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(14)
        love.graphics.line(player.x, player.y, player.x + ax * 180, player.y + ay * 180)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(player.x, player.y, player.x + ax * 180, player.y + ay * 180)
    end
    
    love.graphics.pop()
    
    -- HUD
    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, player.hp, player.max_hp, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, player.hp), margin, margin + barH + 4)
    
    -- Статус
    if connected then
        local status = "ONLINE"
        if mode == "host" then
            status = "👑 HOST"
            love.graphics.setColor(1, 0.8, 0, 0.7)
        else
            love.graphics.setColor(0, 1, 0, 0.7)
        end
        love.graphics.print(status .. " | ID: " .. player_id, love.graphics.getWidth() - 200, margin)
        love.graphics.print("Игроков: " .. (#players + 1), love.graphics.getWidth() - 200, margin + 20)
    end
    
    controls.draw()
end

-- ============================================================
-- ОБРАБОТЧИКИ ВВОДА
-- ============================================================

function game.touchpressed(id, x, y)
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot and not dead then
        spawnBullet(player.x, player.y, dx, dy)
    end
end

function game.keypressed(key)
    if key == "escape" then
        game.disconnect()
        GameState.current = "lobby"
    end
end

return game
