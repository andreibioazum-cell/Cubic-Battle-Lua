-- server.lua
-- Полноценный TCP сервер внутри Love2D

local server = {}

-- Конфигурация
local PORT = 12345
local MAX_PLAYERS = 8
local TICK_RATE = 60
local TICK_TIME = 1 / TICK_RATE

-- Состояние сервера
local state = {
    running = false,
    server_socket = nil,
    clients = {},      -- { [id] = {socket, last_keepalive} }
    players = {},      -- { [id] = {x, y, angle, hp, alive} }
    bullets = {},      -- { id, player_id, x, y, vx, vy, life }
    enemies = {},
    next_player_id = 1,
    next_bullet_id = 1,
    start_time = 0,
    local_ip = "127.0.0.1",
    error = nil,
    last_enemy_spawn = 0
}

-- Настройки игры
local BULLET_SPEED = 390
local PLAYER_RADIUS = 30
local MAX_HP = 5
local ENEMY_SPAWN_TIME = 5.0
local WORLD_WIDTH = 2000
local WORLD_HEIGHT = 2000
local KEEPALIVE_TIMEOUT = 15

-- ============================================================
-- TCP СЕРВЕР
-- ============================================================

local function createTCPServer(port)
    local success, socket = pcall(require, "socket")
    if not success then
        return nil, "LuaSocket не установлен"
    end
    
    local server_socket = socket.tcp()
    server_socket:settimeout(0)
    
    local success, err = pcall(function()
        server_socket:bind("*", port)
        server_socket:listen(10)
    end)
    
    if not success then
        return nil, err
    end
    
    return server_socket, nil
end

function server.getLocalIP()
    local success, socket = pcall(require, "socket")
    if success then
        local hostname = socket.dns.tohostname(socket.dns.gethostname())
        state.local_ip = hostname or "127.0.0.1"
    else
        state.local_ip = "127.0.0.1"
    end
    return state.local_ip
end

-- ============================================================
-- ЗАПУСК/ОСТАНОВКА
-- ============================================================

function server.start(port)
    if state.running then 
        return true 
    end
    
    port = port or PORT
    state.error = nil
    
    print("🚀 Запуск сервера на порту " .. port .. "...")
    
    -- Получаем IP
    server.getLocalIP()
    
    -- Создаем сервер
    local server_socket, err = createTCPServer(port)
    if not server_socket then
        state.error = "❌ " .. err
        print(state.error)
        return false
    end
    
    state.server_socket = server_socket
    state.running = true
    state.start_time = love.timer.getTime()
    state.last_enemy_spawn = state.start_time
    state.next_player_id = 1
    state.next_bullet_id = 1
    state.clients = {}
    state.players = {}
    state.bullets = {}
    state.enemies = {}
    
    print("✅ СЕРВЕР ЗАПУЩЕН!")
    print("📱 IP: " .. state.local_ip)
    print("🔌 Порт: " .. port)
    print("👥 Макс игроков: " .. MAX_PLAYERS)
    print("=" .. string.rep("-", 40))
    
    return true
end

function server.stop()
    if not state.running then return end
    
    state.running = false
    
    -- Закрываем все клиентские сокеты
    for id, client in pairs(state.clients) do
        pcall(function() 
            if client.socket then client.socket:close() end 
        end)
    end
    
    -- Закрываем серверный сокет
    if state.server_socket then
        pcall(function() state.server_socket:close() end)
        state.server_socket = nil
    end
    
    state.clients = {}
    state.players = {}
    state.bullets = {}
    state.enemies = {}
    
    print("🛑 Сервер остановлен")
end

function server.isRunning()
    return state.running
end

function server.getInfo()
    return {
        running = state.running,
        ip = state.local_ip,
        port = PORT,
        players = server.getPlayerCount(),
        max_players = MAX_PLAYERS,
        error = state.error,
        uptime = state.running and (love.timer.getTime() - state.start_time) or 0
    }
end

function server.getPlayerCount()
    local count = 0
    for _, p in pairs(state.players) do
        if p.alive then count = count + 1 end
    end
    return count
end

function server.getPlayers()
    return state.players
end

function server.getBullets()
    return state.bullets
end

-- ============================================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================================

function server.update(dt)
    if not state.running then return end
    
    -- 1. Принимаем новых клиентов
    server.acceptClients()
    
    -- 2. Получаем данные от клиентов
    server.receiveFromClients()
    
    -- 3. Обновляем игровую логику
    server.updateGame(dt)
    
    -- 4. Отправляем состояние клиентам
    server.sendToClients()
end

-- ============================================================
-- ПРИЕМ КЛИЕНТОВ
-- ============================================================

function server.acceptClients()
    if not state.server_socket then return end
    
    while true do
        local client, err = state.server_socket:accept()
        if not client then break end
        
        -- Проверяем лимит
        if server.getPlayerCount() >= MAX_PLAYERS then
            client:send("SERVER_FULL\n")
            client:close()
            print("❌ Сервер полон")
            break
        end
        
        -- Создаем игрока
        local player_id = state.next_player_id
        state.next_player_id = state.next_player_id + 1
        
        local x = math.random(100, WORLD_WIDTH - 100)
        local y = math.random(100, WORLD_HEIGHT - 100)
        
        -- Сохраняем клиента
        state.clients[player_id] = {
            socket = client,
            last_keepalive = love.timer.getTime()
        }
        
        -- Сохраняем игрока
        state.players[player_id] = {
            x = x,
            y = y,
            angle = 0,
            hp = MAX_HP,
            max_hp = MAX_HP,
            alive = true,
            kills = 0
        }
        
        client:settimeout(0)
        
        print("👤 Игрок " .. player_id .. " подключился")
        print("📊 Всего игроков: " .. server.getPlayerCount())
        
        -- Отправляем ID новому игроку
        client:send("CONNECTED:" .. player_id .. "\n")
        client:send("SERVER_INFO:" .. state.local_ip .. ":" .. PORT .. "\n")
        
        -- Отправляем список всех игроков новому игроку
        for pid, player in pairs(state.players) do
            if pid ~= player_id then
                client:send(string.format(
                    "PLAYER_JOIN:%d:%.2f:%.2f:%.2f:%d\n",
                    pid, player.x, player.y, player.angle, player.hp
                ))
            end
        end
        
        -- Уведомляем всех о новом игроке
        server.broadcast(string.format(
            "PLAYER_JOIN:%d:%.2f:%.2f:%.2f:%d",
            player_id, x, y, 0, MAX_HP
        ), player_id)
    end
end

-- ============================================================
-- ПОЛУЧЕНИЕ ДАННЫХ
-- ============================================================

function server.receiveFromClients()
    local to_remove = {}
    
    for id, client in pairs(state.clients) do
        if not client.socket then
            table.insert(to_remove, id)
        else
            -- Проверяем keepalive
            if love.timer.getTime() - client.last_keepalive > KEEPALIVE_TIMEOUT then
                table.insert(to_remove, id)
            else
                -- Читаем данные
                while true do
                    local data, err = client.socket:receive("*l")
                    if not data then break end
                    
                    server.processCommand(id, data)
                    client.last_keepalive = love.timer.getTime()
                end
            end
        end
    end
    
    -- Удаляем отключившихся
    for _, id in ipairs(to_remove) do
        server.removeClient(id)
    end
end

function server.processCommand(player_id, command)
    local player = state.players[player_id]
    if not player then return end
    
    if command:sub(1, 5) == "MOVE:" then
        -- MOVE:x:100.00,y:200.00,angle:1.57,hp:5
        local params = {}
        local data = command:sub(6)
        for part in data:gmatch("[^,]+") do
            local key, value = part:match("([^:]+):([^:]+)")
            if key and value then
                params[key] = value
            end
        end
        
        if params.x then 
            player.x = math.max(0, math.min(WORLD_WIDTH, tonumber(params.x) or player.x)) 
        end
        if params.y then 
            player.y = math.max(0, math.min(WORLD_HEIGHT, tonumber(params.y) or player.y)) 
        end
        if params.angle then 
            player.angle = tonumber(params.angle) or player.angle 
        end
        if params.hp then 
            player.hp = tonumber(params.hp) or player.hp 
        end
        
    elseif command:sub(1, 6) == "SHOOT:" then
        -- SHOOT:dx:0.80,dy:-0.60
        local dx, dy = 0, -1
        local data = command:sub(7)
        for part in data:gmatch("[^,]+") do
            local key, value = part:match("([^:]+):([^:]+)")
            if key and value then
                if key == "dx" then dx = tonumber(value) or 0 end
                if key == "dy" then dy = tonumber(value) or 0 end
            end
        end
        
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then
            dx = dx / len
            dy = dy / len
        end
        
        local bullet_id = state.next_bullet_id
        state.next_bullet_id = state.next_bullet_id + 1
        
        local bullet = {
            id = bullet_id,
            player_id = player_id,
            x = player.x + dx * 40,
            y = player.y + dy * 40,
            vx = dx * BULLET_SPEED,
            vy = dy * BULLET_SPEED,
            life = 3.0
        }
        table.insert(state.bullets, bullet)
        
        server.broadcast(string.format(
            "BULLET:%d:%.2f:%.2f:%.2f:%.2f",
            bullet_id, bullet.x, bullet.y, bullet.vx, bullet.vy
        ))
    end
end

function server.removeClient(player_id)
    local client = state.clients[player_id]
    if client and client.socket then
        pcall(function() client.socket:close() end)
    end
    
    state.clients[player_id] = nil
    state.players[player_id] = nil
    
    server.broadcast("PLAYER_LEFT:" .. player_id)
    print("👋 Игрок " .. player_id .. " вышел")
end

-- ============================================================
-- ИГРОВАЯ ЛОГИКА
-- ============================================================

function server.updateGame(dt)
    -- Обновляем пули
    local to_remove = {}
    for i, bullet in ipairs(state.bullets) do
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt
        bullet.life = bullet.life - dt
        
        if bullet.x < -50 or bullet.x > WORLD_WIDTH + 50 or
           bullet.y < -50 or bullet.y > WORLD_HEIGHT + 50 or
           bullet.life <= 0 then
            table.insert(to_remove, i)
        end
    end
    
    for i = #to_remove, 1, -1 do
        table.remove(state.bullets, to_remove[i])
    end
    
    -- Проверяем коллизии
    server.checkCollisions()
    
    -- Спавним врагов (только если есть игроки)
    if server.getPlayerCount() > 0 then
        local now = love.timer.getTime()
        if now - state.last_enemy_spawn > ENEMY_SPAWN_TIME then
            state.last_enemy_spawn = now
            server.spawnEnemy()
        end
    end
    
    -- Обновляем врагов
    server.updateEnemies(dt)
end

function server.checkCollisions()
    local to_remove = {}
    
    for i, bullet in ipairs(state.bullets) do
        for pid, player in pairs(state.players) do
            if pid ~= bullet.player_id and player.alive then
                local dx = bullet.x - player.x
                local dy = bullet.y - player.y
                
                if dx*dx + dy*dy < PLAYER_RADIUS * PLAYER_RADIUS then
                    player.hp = player.hp - 1
                    table.insert(to_remove, i)
                    
                    if player.hp <= 0 then
                        player.hp = 0
                        player.alive = false
                        
                        local killer = state.players[bullet.player_id]
                        if killer then
                            killer.kills = (killer.kills or 0) + 1
                            server.broadcast("KILL:" .. bullet.player_id .. ":" .. pid)
                            print("💀 " .. bullet.player_id .. " убил " .. pid)
                        end
                        
                        server.broadcast("PLAYER_DIED:" .. pid)
                    else
                        server.broadcast("HIT:" .. pid .. ":1")
                    end
                    
                    break
                end
            end
        end
    end
    
    for i = #to_remove, 1, -1 do
        table.remove(state.bullets, to_remove[i])
    end
end

function server.spawnEnemy()
    local enemy = {
        id = state.next_enemy_id or 1,
        x = math.random(100, WORLD_WIDTH - 100),
        y = math.random(100, WORLD_HEIGHT - 100),
        hp = 5,
        max_hp = 5,
        angle = 0,
        speed = 140
    }
    state.next_enemy_id = (state.next_enemy_id or 1) + 1
    table.insert(state.enemies, enemy)
end

function server.updateEnemies(dt)
    for _, enemy in ipairs(state.enemies) do
        local closest_dist = 99999
        local target = nil
        
        for _, player in pairs(state.players) do
            if player.alive then
                local dx = player.x - enemy.x
                local dy = player.y - enemy.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist < closest_dist then
                    closest_dist = dist
                    target = player
                end
            end
        end
        
        if target then
            local dx = target.x - enemy.x
            local dy = target.y - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                enemy.angle = math.atan2(dy, dx)
                if dist > 200 then
                    enemy.x = enemy.x + (dx / dist) * enemy.speed * dt
                    enemy.y = enemy.y + (dy / dist) * enemy.speed * dt
                end
            end
        end
    end
end

-- ============================================================
-- ОТПРАВКА КЛИЕНТАМ
-- ============================================================

function server.sendToClients()
    for pid, player in pairs(state.players) do
        for cid, client in pairs(state.clients) do
            if cid ~= pid and client.socket then
                pcall(function()
                    client.socket:send(string.format(
                        "PLAYER_UPDATE:%d:%.2f:%.2f:%.2f:%d:%d:%d\n",
                        pid, player.x, player.y, player.angle,
                        player.hp, player.alive and 1 or 0,
                        player.kills or 0
                    ))
                end)
            end
        end
    end
end

function server.broadcast(message, exclude_id)
    for id, client in pairs(state.clients) do
        if id ~= exclude_id and client.socket then
            pcall(function()
                client.socket:send(message .. "\n")
            end)
        end
    end
end

return server
