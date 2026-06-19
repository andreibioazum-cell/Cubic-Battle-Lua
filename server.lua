-- server.lua
-- Полноценный TCP сервер внутри Love2D
-- Работает на ПК, Android, iOS

local server = {}

-- Конфигурация
local PORT = 61679
local MAX_PLAYERS = 10
local TICK_RATE = 60
local TICK_TIME = 1 / TICK_RATE

-- Состояние сервера
local state = {
    running = false,
    server_socket = nil,
    clients = {},  -- { [id] = {socket, ip, port, x, y, angle, hp, alive, last_keepalive} }
    players = {},  -- { [id] = {x, y, angle, hp, alive} }
    bullets = {},  -- { id, player_id, x, y, vx, vy, life }
    enemies = {},  -- { id, x, y, hp, angle, state }
    next_player_id = 1,
    next_bullet_id = 1,
    next_enemy_id = 1,
    start_time = 0,
    last_enemy_spawn = 0,
    player_positions = {}  -- для синхронизации
}

-- Настройки игры
local BULLET_SPEED = 390
local PLAYER_RADIUS = 30
local MAX_HP = 5
local ENEMY_SPAWN_TIME = 5.0
local WORLD_WIDTH = 800
local WORLD_HEIGHT = 600

-- ============================================================
-- TCP СЕРВЕР (чистый Lua без библиотек)
-- ============================================================

local function createTCPServer(port)
    -- Используем socket из стандартной библиотеки Lua
    local success, socket = pcall(require, "socket")
    if not success then
        print("❌ LuaSocket не установлен")
        return nil
    end
    
    local server = socket.tcp()
    server:settimeout(0)
    server:bind("*", port)
    server:listen(10)
    
    print("✅ TCP сервер создан на порту " .. port)
    return server
end

-- ============================================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================================

function server.init()
    -- Проверяем наличие сокетов
    local success, socket = pcall(require, "socket")
    if not success then
        print("❌ LuaSocket не найден! Установите luasocket")
        return false
    end
    return true
end

function server.start(port)
    if state.running then return true end
    
    port = port or PORT
    
    -- Создаем серверный сокет
    state.server_socket = createTCPServer(port)
    if not state.server_socket then
        return false
    end
    
    state.running = true
    state.start_time = love.timer.getTime()
    state.last_enemy_spawn = state.start_time
    
    print("=" .. string.rep("-", 50))
    print("🚀 СЕРВЕР ЗАПУЩЕН")
    print("📱 Порт: " .. port)
    print("👥 Макс игроков: " .. MAX_PLAYERS)
    print("=" .. string.rep("-", 50))
    
    -- Запускаем поток для приема клиентов
    -- В Love2D мы используем love.update для этого
    
    return true
end

function server.stop()
    if not state.running then return end
    
    state.running = false
    
    -- Закрываем все клиентские сокеты
    for id, client in pairs(state.clients) do
        if client.socket then
            pcall(function() client.socket:close() end)
        end
    end
    
    -- Закрываем серверный сокет
    if state.server_socket then
        pcall(function() state.server_socket:close() end)
        state.server_socket = nil
    end
    
    -- Очищаем состояние
    state.clients = {}
    state.players = {}
    state.bullets = {}
    state.enemies = {}
    state.next_player_id = 1
    state.next_bullet_id = 1
    state.next_enemy_id = 1
    
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

function server.getPlayers()
    return state.players
end

function server.getBullets()
    return state.bullets
end

-- ============================================================
-- ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ
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
            print("❌ Сервер полон, отклонен клиент")
            break
        end
        
        -- Получаем IP и порт
        local ip, port = client:getpeername()
        
        -- Создаем нового игрока
        local player_id = state.next_player_id
        state.next_player_id = state.next_player_id + 1
        
        -- Случайная позиция
        local x = math.random(100, WORLD_WIDTH - 100)
        local y = math.random(100, WORLD_HEIGHT - 100)
        
        -- Сохраняем клиента
        state.clients[player_id] = {
            socket = client,
            ip = ip,
            port = port,
            last_keepalive = love.timer.getTime()
        }
        
        -- Сохраняем игрока
        state.players[player_id] = {
            x = x,
            y = y,
            angle = 0,
            hp = MAX_HP,
            max_hp = MAX_HP,
            alive = true
        }
        
        -- Устанавливаем таймаут
        client:settimeout(0)
        
        print("👤 Игрок " .. player_id .. " подключился (" .. ip .. ":" .. port .. ")")
        print("📊 Всего игроков: " .. server.getPlayerCount())
        
        -- Отправляем ID новому игроку
        client:send("CONNECTED:" .. player_id .. "\n")
        
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
-- ПОЛУЧЕНИЕ ДАННЫХ ОТ КЛИЕНТОВ
-- ============================================================

function server.receiveFromClients()
    local to_remove = {}
    
    for id, client in pairs(state.clients) do
        if not client.socket then
            table.insert(to_remove, id)
        else
            -- Проверяем keepalive (таймаут 10 секунд)
            if love.timer.getTime() - client.last_keepalive > 10 then
                table.insert(to_remove, id)
            else
                -- Читаем данные
                while true do
                    local data, err = client.socket:receive("*l")
                    if not data then break end
                    
                    -- Обрабатываем команду
                    server.processCommand(id, data)
                    
                    -- Обновляем keepalive
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
        
        if params.x then player.x = tonumber(params.x) or player.x end
        if params.y then player.y = tonumber(params.y) or player.y end
        if params.angle then player.angle = tonumber(params.angle) or player.angle end
        if params.hp then player.hp = tonumber(params.hp) or player.hp end
        
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
    print("👋 Игрок " .. player_id .. " вышел (осталось: " .. server.getPlayerCount() .. ")")
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
    
    -- Удаляем пули
    for i = #to_remove, 1, -1 do
        table.remove(state.bullets, to_remove[i])
    end
    
    -- Проверяем коллизии
    server.checkCollisions()
    
    -- Спавним врагов (для демонстрации)
    local now = love.timer.getTime()
    if now - state.last_enemy_spawn > ENEMY_SPAWN_TIME then
        state.last_enemy_spawn = now
        server.spawnEnemy()
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
                    -- Попадание!
                    player.hp = player.hp - 1
                    table.insert(to_remove, i)
                    
                    if player.hp <= 0 then
                        player.hp = 0
                        player.alive = false
                        server.broadcast("PLAYER_DIED:" .. pid)
                        print("💀 Игрок " .. pid .. " убит!")
                    else
                        server.broadcast("HIT:" .. pid .. ":1")
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

function server.spawnEnemy()
    local enemy = {
        id = state.next_enemy_id,
        x = math.random(100, WORLD_WIDTH - 100),
        y = math.random(100, WORLD_HEIGHT - 100),
        hp = 5,
        max_hp = 5,
        angle = 0,
        speed = 140
    }
    state.next_enemy_id = state.next_enemy_id + 1
    table.insert(state.enemies, enemy)
end

function server.updateEnemies(dt)
    for _, enemy in ipairs(state.enemies) do
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
    -- Отправляем обновления позиций
    for pid, player in pairs(state.players) do
        -- Отправляем другим игрокам позицию этого игрока
        for cid, client in pairs(state.clients) do
            if cid ~= pid and client.socket then
                pcall(function()
                    client.socket:send(string.format(
                        "PLAYER_UPDATE:%d:%.2f:%.2f:%.2f:%d:%d\n",
                        pid, player.x, player.y, player.angle,
                        player.hp, player.alive and 1 or 0
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

-- ============================================================
-- ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function server.getLocalIP()
    local success, socket = pcall(require, "socket")
    if success then
        local hostname = socket.dns.tohostname(socket.dns.gethostname())
        return hostname or "127.0.0.1"
    end
    return "127.0.0.1"
end

function server.getStats()
    return {
        running = state.running,
        players = server.getPlayerCount(),
        bullets = #state.bullets,
        enemies = #state.enemies,
        uptime = love.timer.getTime() - state.start_time
    }
end

return server
