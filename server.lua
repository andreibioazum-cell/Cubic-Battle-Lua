-- server.lua
-- Полноценный выделенный сервер внутри Love2D
-- Можно запустить на телефоне, ПК, планшете

local server = {}

-- Конфигурация
local PORT = 12345
local MAX_PLAYERS = 10
local TICK_RATE = 60
local TICK_TIME = 1 / TICK_RATE

-- Состояние сервера
local state = {
    running = false,
    players = {},  -- { [id] = {conn, x, y, angle, hp, max_hp, alive, name} }
    bullets = {},  -- { id, player_id, x, y, vx, vy, life }
    enemies = {},  -- { id, x, y, hp, angle, state }
    next_player_id = 1,
    next_bullet_id = 1,
    next_enemy_id = 1,
    start_time = 0
}

-- Настройки игры
local BULLET_SPEED = 390
local PLAYER_RADIUS = 30
local MAX_HP = 5
local ENEMY_SPAWN_TIME = 5.0
local last_enemy_spawn = 0

-- Библиотека Sock.lua (встроенная)
local sock = nil

-- ============================================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================================

function server.init()
    -- Пытаемся загрузить Sock.lua
    local success, sock_lib = pcall(require, "sock")
    if success then
        sock = sock_lib
        print("✅ Sock.lua загружен")
    else
        -- Используем встроенный ENet если есть
        success, sock = pcall(require, "enet")
        if success then
            print("✅ ENet загружен")
        else
            print("❌ Ни одна библиотека не найдена")
            return false
        end
    end
    return true
end

-- ============================================================
-- ЗАПУСК/ОСТАНОВКА СЕРВЕРА
-- ============================================================

function server.start(port)
    if state.running then return true end
    
    port = port or PORT
    
    -- Создаем сервер
    if sock and sock.newServer then
        state.server = sock.newServer("*", port)
        if not state.server then
            print("❌ Не удалось создать сервер на порту " .. port)
            return false
        end
        state.running = true
        state.start_time = love.timer.getTime()
        last_enemy_spawn = state.start_time
        
        print("🚀 Сервер запущен на порту " .. port)
        print("📱 Подключайтесь по IP: " .. getLocalIP())
        print("=" .. string.rep("-", 50))
        
        return true
    else
        print("❌ Библиотека Sock не найдена")
        return false
    end
end

function server.stop()
    if not state.running then return end
    
    state.running = false
    
    -- Закрываем все соединения
    for id, player in pairs(state.players) do
        if player.conn and player.conn.close then
            player.conn:close()
        end
    end
    
    if state.server and state.server.close then
        state.server:close()
    end
    
    state.players = {}
    state.bullets = {}
    state.enemies = {}
    state.next_player_id = 1
    state.next_bullet_id = 1
    
    print("🛑 Сервер остановлен")
end

function server.isRunning()
    return state.running
end

function server.getPlayerCount()
    local count = 0
    for _, p in pairs(state.players) do
        if p.alive then count = count + 1 end
    end
    return count
end

-- ============================================================
-- ОБРАБОТКА КЛИЕНТОВ
-- ============================================================

function server.update(dt)
    if not state.running then return end
    
    -- Обновляем сервер
    if state.server and state.server.update then
        state.server:update()
    end
    
    -- Принимаем новых клиентов
    if state.server and state.server.accept then
        local conn = state.server:accept()
        if conn then
            onClientConnect(conn)
        end
    end
    
    -- Получаем данные от клиентов
    for id, player in pairs(state.players) do
        if player.conn and player.conn.receive then
            local data, err = player.conn:receive("*l")
            if data then
                processCommand(id, data)
            elseif err ~= "timeout" and err ~= "again" then
                onClientDisconnect(id)
            end
        end
    end
    
    -- Обновляем пули
    updateBullets(dt)
    
    -- Обновляем врагов
    updateEnemies(dt)
    
    -- Проверяем коллизии
    checkCollisions()
    
    -- Отправляем состояние игры
    sendGameState()
end

-- ============================================================
-- ОБРАБОТКА КОМАНД
-- ============================================================

function processCommand(player_id, command)
    local player = state.players[player_id]
    if not player then return end
    
    if command:startswith("MOVE:") then
        -- MOVE:x:100.00,y:200.00,angle:1.57,hp:5
        local parts = {}
        for part in command:gmatch("[^:]+") do
            table.insert(parts, part)
        end
        
        if #parts >= 2 then
            local params = {}
            for param in parts[2]:gmatch("[^,]+") do
                local key, value = param:match("([^:]+):([^:]+)")
                if key and value then
                    params[key] = value
                end
            end
            
            player.x = tonumber(params.x) or player.x
            player.y = tonumber(params.y) or player.y
            player.angle = tonumber(params.angle) or player.angle
            player.hp = tonumber(params.hp) or player.hp
            player.last_update = love.timer.getTime()
        end
        
    elseif command:startswith("SHOOT:") then
        -- SHOOT:dx:0.80,dy:-0.60
        local dx, dy = 0, -1
        local params = {}
        for part in command:gmatch("[^:]+") do
            table.insert(params, part)
        end
        
        if #params >= 2 then
            for param in params[2]:gmatch("[^,]+") do
                local key, value = param:match("([^:]+):([^:]+)")
                if key and value then
                    if key == "dx" then dx = tonumber(value) or 0 end
                    if key == "dy" then dy = tonumber(value) or 0 end
                end
            end
        end
        
        -- Нормализуем направление
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then
            dx = dx / len
            dy = dy / len
        end
        
        -- Создаем пулю
        local bullet_id = state.next_bullet_id
        state.next_bullet_id = state.next_bullet_id + 1
        
        local bullet = {
            id = bullet_id,
            player_id = player_id,
            x = player.x + dx * 30,
            y = player.y + dy * 30,
            vx = dx * BULLET_SPEED,
            vy = dy * BULLET_SPEED,
            life = 3.0
        }
        table.insert(state.bullets, bullet)
        
        -- Рассылаем пулю всем
        broadcast("BULLET:" .. bullet_id .. ":" .. 
            string.format("%.2f:%.2f:%.2f:%.2f", bullet.x, bullet.y, bullet.vx, bullet.vy))
    end
end

-- ============================================================
-- УПРАВЛЕНИЕ КЛИЕНТАМИ
-- ============================================================

function onClientConnect(conn)
    if not state.running then return end
    
    -- Проверяем лимит игроков
    local alive_count = 0
    for _, p in pairs(state.players) do
        if p.alive then alive_count = alive_count + 1 end
    end
    
    if alive_count >= MAX_PLAYERS then
        conn:send("SERVER_FULL\n")
        conn:close()
        return
    end
    
    -- Создаем игрока
    local player_id = state.next_player_id
    state.next_player_id = state.next_player_id + 1
    
    local player = {
        id = player_id,
        conn = conn,
        x = math.random(100, 700),
        y = math.random(100, 500),
        angle = 0,
        hp = MAX_HP,
        max_hp = MAX_HP,
        alive = true,
        last_update = love.timer.getTime(),
        name = "Player" .. player_id
    }
    
    state.players[player_id] = player
    
    print("👤 Игрок " .. player_id .. " подключился (всего: " .. server.getPlayerCount() .. ")")
    
    -- Отправляем ID
    conn:send("CONNECTED:" .. player_id .. "\n")
    
    -- Отправляем всех игроков
    for pid, p in pairs(state.players) do
        if pid ~= player_id then
            conn:send(string.format("PLAYER_JOIN:%d:%.2f:%.2f:%.2f:%d\n",
                pid, p.x, p.y, p.angle, p.hp))
        end
    end
    
    -- Уведомляем всех
    broadcast(string.format("PLAYER_JOIN:%d:%.2f:%.2f:%.2f:%d",
        player_id, player.x, player.y, player.angle, player.hp), player_id)
end

function onClientDisconnect(player_id)
    local player = state.players[player_id]
    if player then
        if player.conn and player.conn.close then
            player.conn:close()
        end
        state.players[player_id] = nil
        broadcast("PLAYER_LEFT:" .. player_id)
        print("👋 Игрок " .. player_id .. " вышел (осталось: " .. server.getPlayerCount() .. ")")
    end
end

-- ============================================================
-- ИГРОВАЯ ЛОГИКА
-- ============================================================

function updateBullets(dt)
    local to_remove = {}
    
    for i, bullet in ipairs(state.bullets) do
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt
        bullet.life = bullet.life - dt
        
        -- Проверка границ (800x600 - размер экрана)
        if bullet.x < -50 or bullet.x > 850 or 
           bullet.y < -50 or bullet.y > 650 or 
           bullet.life <= 0 then
            table.insert(to_remove, i)
        end
    end
    
    -- Удаляем
    for i = #to_remove, 1, -1 do
        table.remove(state.bullets, to_remove[i])
    end
end

function updateEnemies(dt)
    -- Спавн врагов
    local now = love.timer.getTime()
    if now - last_enemy_spawn > ENEMY_SPAWN_TIME then
        last_enemy_spawn = now
        
        -- Создаем врага в случайном месте
        local enemy = {
            id = state.next_enemy_id,
            x = math.random(100, 700),
            y = math.random(100, 500),
            hp = 5,
            max_hp = 5,
            angle = 0,
            state = "wander",
            speed = 140,
            shoot_t = 0,
            shoot_cooldown = 1.2
        }
        state.next_enemy_id = state.next_enemy_id + 1
        table.insert(state.enemies, enemy)
    end
    
    -- Двигаем врагов (упрощенно)
    for _, enemy in ipairs(state.enemies) do
        enemy.angle = enemy.angle + dt * 0.5
        
        -- Находим ближайшего игрока
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
        
        -- Движение к игроку
        if target then
            local dx = target.x - enemy.x
            local dy = target.y - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                enemy.angle = math.atan2(dy, dx) + math.pi/2
                
                if dist > 200 then
                    enemy.x = enemy.x + (dx / dist) * enemy.speed * dt
                    enemy.y = enemy.y + (dy / dist) * enemy.speed * dt
                end
            end
        end
    end
end

function checkCollisions()
    local to_remove = {}
    
    -- Пули против игроков
    for i, bullet in ipairs(state.bullets) do
        for pid, player in pairs(state.players) do
            if pid ~= bullet.player_id and player.alive then
                local dx = bullet.x - player.x
                local dy = bullet.y - player.y
                
                if dx*dx + dy*dy < PLAYER_RADIUS * PLAYER_RADIUS then
                    -- Попадание!
                    player.hp = player.hp - 1
                    table.insert(to_remove, i)
                    
                    if player.hp <= 0 then
                        player.hp = 0
                        player.alive = false
                        broadcast("PLAYER_DIED:" .. pid)
                        print("💀 Игрок " .. pid .. " убит!")
                    else
                        broadcast("HIT:" .. pid .. ":1")
                    end
                    
                    break
                end
            end
        end
    end
    
    -- Удаляем пули
    for i = #to_remove, 1, -1 do
        table.remove(state.bullets, to_remove[i])
    end
end

-- ============================================================
-- ОТПРАВКА СОСТОЯНИЯ
-- ============================================================

function sendGameState()
    if not state.players then return end
    
    -- Отправляем всем игрокам
    for pid, player in pairs(state.players) do
        if player.conn then
            -- Отправляем позиции всех игроков
            for other_pid, other in pairs(state.players) do
                if other_pid ~= pid then
                    player.conn:send(string.format("PLAYER_UPDATE:%d:%.2f:%.2f:%.2f:%d:%s\n",
                        other_pid, other.x, other.y, other.angle, other.hp, 
                        other.alive and "1" or "0"))
                end
            end
        end
    end
end

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function broadcast(message, exclude_id)
    for id, player in pairs(state.players) do
        if id ~= exclude_id and player.conn then
            pcall(function()
                player.conn:send(message .. "\n")
            end)
        end
    end
end

function getLocalIP()
    -- Пытаемся получить локальный IP
    local socket = require("socket")
    if socket then
        local hostname = socket.dns.tohostname(socket.dns.gethostname())
        return hostname or "127.0.0.1"
    end
    return "127.0.0.1"
end

-- ============================================================
-- ОТЛАДКА
-- ============================================================

function server.getStats()
    return {
        running = state.running,
        players = server.getPlayerCount(),
        bullets = #state.bullets,
        enemies = #state.enemies,
        uptime = love.timer.getTime() - state.start_time
    }
end

function server.printStats()
    local stats = server.getStats()
    print(string.format([[
📊 СТАТИСТИКА СЕРВЕРА
├─ Статус: %s
├─ Игроков: %d
├─ Пуль: %d
├─ Врагов: %d
└─ Время: %.1f сек
]], stats.running and "✅ Онлайн" or "⛔ Оффлайн",
    stats.players, stats.bullets, stats.enemies, stats.uptime))
end

return server
