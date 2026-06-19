local controls = require("controls")
local enemy = require("enemy")
local server = require("server")

local game = {}

-- Константы
local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15

-- Переменные
local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = PLAYER_HP_MAX, hit = 0 }
local bullets = {}
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false
local onDeathCallback = nil

-- Онлайн
local mode = "offline"
local socket = nil
local connected = false
local player_id = 0
local players = {}
local last_send = 0
local send_interval = 1 / 20
local online_bullets = {}
local kill_messages = {}
local message_timer = 0
local scoreboard = {}
local game_start_time = 0

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
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

local function drawScoreboard()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- Собираем данные
    local scores = {}
    for pid, p in pairs(players) do
        if p.alive ~= false then
            table.insert(scores, {
                id = pid,
                kills = p.kills or 0,
                name = "P" .. pid
            })
        end
    end
    
    -- Сортируем по убийствам
    table.sort(scores, function(a, b) return a.kills > b.kills end)
    
    -- Рисуем таблицу
    local bx = w - 220
    local by = 100
    local bw = 200
    local bh = 30 * math.min(#scores + 1, 10)
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bx - 5, by - 5, bw + 10, bh + 10, 8, 8)
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(font)
    love.graphics.print("🏆 SCOREBOARD", bx + 10, by + 8)
    
    for i, s in ipairs(scores) do
        local y = by + 30 + (i - 1) * 25
        local color = {1, 1, 1}
        if i == 1 then color = {1, 0.8, 0} end
        if i == 2 then color = {0.8, 0.8, 0.8} end
        if i == 3 then color = {0.8, 0.6, 0.3} end
        
        love.graphics.setColor(color[1], color[2], color[3], 0.7)
        love.graphics.print(i .. ". " .. s.name, bx + 10, y)
        love.graphics.print(s.kills, bx + bw - 40, y)
    end
end

local function drawHostInfo()
    if mode == "host" then
        local info = server.getInfo()
        love.graphics.setColor(1, 0.8, 0, 0.8)
        love.graphics.setFont(font)
        love.graphics.print("👑 ХОСТ", 10, 60)
        love.graphics.print("IP: " .. info.ip .. ":" .. info.port, 10, 80)
        love.graphics.print("Игроков: " .. info.players .. "/" .. info.max_players, 10, 100)
    end
end

-- ============================================================
-- ОСНОВНЫЕ ФУНКЦИИ
-- ============================================================

local function spawnBullet(x, y, dx, dy)
    table.insert(bullets, {
        x = x,
        y = y,
        vx = dx * BULLET_SPEED,
        vy = dy * BULLET_SPEED,
        life = 3
    })
    
    if connected and socket then
        pcall(function()
            socket:send(string.format("SHOOT:dx:%.2f,dy:%.2f\n", dx, dy))
        end)
    end
end

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

function game.setOnDeath(callback)
    onDeathCallback = callback
end

-- ============================================================
-- РЕЖИМЫ
-- ============================================================

function game.setMode(new_mode)
    mode = new_mode
    print("🎮 Режим: " .. mode)
end

function game.hostGame(port)
    if not server.start(port) then
        print("❌ Не удалось запустить сервер")
        return false
    end
    
    game_start_time = love.timer.getTime()
    
    local success = game.connect("127.0.0.1", port)
    if success then
        game.setMode("host")
        print("👑 Вы хост игры!")
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
    players = {}
    online_bullets = {}
    kill_messages = {}
    game.setMode("offline")
end

-- ============================================================
-- ЗАГРУЗКА
-- ============================================================

function game.load()
    cube.x = 0
    cube.y = 0
    cube.angle = 0
    cube.hp = PLAYER_HP_MAX
    cube.hit = 0
    dead = false
    bullets = {}
    players = {}
    online_bullets = {}
    kill_messages = {}
    cam.x = -love.graphics.getWidth() / 2
    cam.y = -love.graphics.getHeight() / 2

    bg = bg or love.graphics.newImage("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end

    playerImg = playerImg or love.graphics.newImage("player.png")
    if playerImg then playerImg:setFilter("nearest", "nearest") end

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

-- ============================================================
-- ОБНОВЛЕНИЕ
-- ============================================================

function game.update(dt)
    if dead then 
        controls.update(dt)
        return 
    end
    
    controls.update(dt)
    
    -- Движение
    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    cube.hit = math.max(0, cube.hit - dt * 3)

    -- Камера
    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

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
    
    for i = #online_bullets, 1, -1 do
        local b = online_bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(online_bullets, i)
        end
    end

    -- Обновляем сервер
    if mode == "host" and server.isRunning() then
        server.update(dt)
    end

    -- Оффлайн
    if mode == "offline" then
        enemy.update(dt, cube.x, cube.y, bullets, onHitPlayer)
    end
    
    -- Онлайн
    if mode == "client" or mode == "host" then
        if connected and socket then
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
            
            while true do
                local data, err = socket:receive("*l")
                if not data then break end
                
                if data:sub(1, 10) == "CONNECTED:" then
                    player_id = tonumber(data:sub(11))
                    print("🎮 ID: " .. player_id)
                    
                elseif data:sub(1, 12) == "SERVER_INFO:" then
                    print("📱 " .. data:sub(13))
                    
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
                                hp = tonumber(parts[6]),
                                alive = true,
                                kills = 0
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
                    
                elseif data:sub(1, 5) == "KILL:" then
                    local parts = {}
                    for part in data:gmatch("[^:]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 3 then
                        local killer = tonumber(parts[2])
                        local victim = tonumber(parts[3])
                        if killer == player_id then
                            table.insert(kill_messages, {text = "💀 Вы убили P" .. victim, timer = 3})
                        elseif victim == player_id then
                            table.insert(kill_messages, {text = "💀 Вас убил P" .. killer, timer = 3})
                        else
                            table.insert(kill_messages, {text = "💀 P" .. killer .. " убил P" .. victim, timer = 2})
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
                            players[pid].kills = tonumber(parts[8]) or 0
                        end
                    end
                end
            end
        end
    end
    
    -- Обновляем сообщения
    for i = #kill_messages, 1, -1 do
        kill_messages[i].timer = kill_messages[i].timer - dt
        if kill_messages[i].timer <= 0 then
            table.remove(kill_messages, i)
        end
    end
end

-- ============================================================
-- ОТРИСОВКА
-- ============================================================

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

    -- Пули
    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end
    
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

    -- Оффлайн враг
    if mode == "offline" then
        enemy.draw()
    end
    
    -- Онлайн игроки
    if mode == "client" or mode == "host" then
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
                
                -- Ник и HP
                love.graphics.setColor(1, 1, 1, 0.7)
                love.graphics.setFont(font)
                love.graphics.print("P" .. pid, p.x - 15, p.y - 65)
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
        
        -- Ник
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.setFont(font)
        love.graphics.print("YOU", cube.x - 15, cube.y - 65)
    end

    love.graphics.pop()

    -- HUD
    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    -- Оффлайн враг HP
    if mode == "offline" then
        local e_obj = enemy.get()
        if e_obj then
            local ex = love.graphics.getWidth() - barW - margin
            drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("ENEMY " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
        end
    end
    
    -- Информация хоста
    drawHostInfo()
    
    -- Счет
    drawScoreboard()
    
    -- Сообщения о убийствах
    for i, msg in ipairs(kill_messages) do
        local alpha = math.min(1, msg.timer)
        local y = 150 + (i - 1) * 30
        love.graphics.setColor(1, 1, 1, alpha * 0.8)
        love.graphics.setFont(font)
        love.graphics.print(msg.text, love.graphics.getWidth()/2 - 50, y)
    end

    controls.draw()
end

-- ============================================================
-- ВВОД
-- ============================================================

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
