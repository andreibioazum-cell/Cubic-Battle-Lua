-- server.lua
-- Упрощенный сервер с использованием встроенного сокета LÖVE

local server = {}

local PORT = 743712
local MAX_PLAYERS = 8

local state = {
    running = false,
    clients = {},
    players = {},
    bullets = {},
    next_player_id = 1,
    next_bullet_id = 1,
    start_time = 0,
    local_ip = "127.0.0.1"
}

-- Настройки игры
local BULLET_SPEED = 390
local PLAYER_RADIUS = 30
local MAX_HP = 5
local WORLD_WIDTH = 2000
local WORLD_HEIGHT = 2000

-- ============================================================
-- ФУНКЦИИ СЕРВЕРА
-- ============================================================

function server.getLocalIP()
    -- Получаем IP через системный вызов
    local success, socket = pcall(require, "socket")
    if success then
        local hostname = socket.dns.tohostname(socket.dns.gethostname())
        state.local_ip = hostname or "127.0.0.1"
    else
        state.local_ip = "127.0.0.1"
    end
    return state.local_ip
end

function server.start(port)
    if state.running then return true end
    
    port = port or PORT
    
    -- Пытаемся использовать встроенный сокет LÖVE
    local success, tcp = pcall(require, "love.tcp")
    if not success then
        -- Пытаемся использовать LuaSocket
        success, tcp = pcall(require, "socket")
        if not success then
            print("❌ Нет сетевой библиотеки!")
            return false
        end
    end
    
    -- Создаем сервер
    local server_socket = tcp.tcp()
    server_socket:settimeout(0)
    
    local success, err = pcall(function()
        server_socket:bind("*", port)
        server_socket:listen(10)
    end)
    
    if not success then
        print("❌ Ошибка создания сервера: " .. tostring(err))
        return false
    end
    
    state.server_socket = server_socket
    state.running = true
    state.start_time = love.timer.getTime()
    state.clients = {}
    state.players = {}
    state.bullets = {}
    state.next_player_id = 1
    state.next_bullet_id = 1
    
    server.getLocalIP()
    
    print("✅ СЕРВЕР ЗАПУЩЕН!")
    print("📱 IP: " .. state.local_ip)
    print("🔌 Порт: " .. port)
    
    return true
end

function server.stop()
    if not state.running then return end
    
    state.running = false
    
    for id, client in pairs(state.clients) do
        pcall(function() 
            if client.socket then client.socket:close() end 
        end)
    end
    
    if state.server_socket then
        pcall(function() state.server_socket:close() end)
        state.server_socket = nil
    end
    
    state.clients = {}
    state.players = {}
    state.bullets = {}
    
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
        max_players = MAX_PLAYERS
    }
end

function server.getPlayerCount()
    local count = 0
    for _, p in pairs(state.players) do
        if p.alive then count = count + 1 end
    end
    return count
end

function server.update(dt)
    if not state.running then return end
    
    -- Принимаем новых клиентов
    if state.server_socket then
        while true do
            local client, err = state.server_socket:accept()
            if not client then break end
            
            local player_id = state.next_player_id
            state.next_player_id = state.next_player_id + 1
            
            state.clients[player_id] = {
                socket = client,
                last_keepalive = love.timer.getTime()
            }
            
            state.players[player_id] = {
                x = math.random(100, 700),
                y = math.random(100, 500),
                angle = 0,
                hp = MAX_HP,
                alive = true
            }
            
            client:settimeout(0)
            client:send("CONNECTED:" .. player_id .. "\n")
            client:send("SERVER_INFO:" .. state.local_ip .. ":" .. PORT .. "\n")
            
            print("👤 Игрок " .. player_id .. " подключился")
        end
    end
    
    -- Получаем данные от клиентов
    for id, client in pairs(state.clients) do
        if client.socket then
            while true do
                local data, err = client.socket:receive("*l")
                if not data then break end
                
                if data:sub(1, 5) == "MOVE:" then
                    local player = state.players[id]
                    if player then
                        for part in data:gmatch("[^,]+") do
                            local key, value = part:match("([^:]+):([^:]+)")
                            if key and value then
                                if key == "x" then player.x = tonumber(value) or player.x end
                                if key == "y" then player.y = tonumber(value) or player.y end
                                if key == "angle" then player.angle = tonumber(value) or player.angle end
                                if key == "hp" then player.hp = tonumber(value) or player.hp end
                            end
                        end
                    end
                elseif data:sub(1, 6) == "SHOOT:" then
                    local dx, dy = 0, -1
                    for part in data:gmatch("[^,]+") do
                        local key, value = part:match("([^:]+):([^:]+)")
                        if key and value then
                            if key == "dx" then dx = tonumber(value) or 0 end
                            if key == "dy" then dy = tonumber(value) or 0 end
                        end
                    end
                    
                    local bullet = {
                        id = state.next_bullet_id,
                        player_id = id,
                        x = state.players[id].x + dx * 30,
                        y = state.players[id].y + dy * 30,
                        vx = dx * BULLET_SPEED,
                        vy = dy * BULLET_SPEED,
                        life = 3.0
                    }
                    state.next_bullet_id = state.next_bullet_id + 1
                    table.insert(state.bullets, bullet)
                    
                    for cid, c in pairs(state.clients) do
                        if cid ~= id and c.socket then
                            pcall(function()
                                c.socket:send(string.format(
                                    "BULLET:%d:%.2f:%.2f:%.2f:%.2f\n",
                                    bullet.id, bullet.x, bullet.y, bullet.vx, bullet.vy
                                ))
                            end)
                        end
                    end
                end
            end
        end
    end
    
    -- Обновляем пули
    for i = #state.bullets, 1, -1 do
        local b = state.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(state.bullets, i)
        end
    end
    
    -- Отправляем обновления
    for pid, player in pairs(state.players) do
        for cid, client in pairs(state.clients) do
            if cid ~= pid and client.socket then
                pcall(function()
                    client.socket:send(string.format(
                        "PLAYER_UPDATE:%d:%.2f:%.2f:%.2f:%d:%d\n",
                        pid, player.x, player.y, player.angle, player.hp, player.alive and 1 or 0
                    ))
                end)
            end
        end
    end
end

return server
