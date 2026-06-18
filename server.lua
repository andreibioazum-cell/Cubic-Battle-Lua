-- server.lua - Сервер Cubic Battle
-- Запуск: lua server.lua (требуется luasocket)

local socket = require("socket")

local server = {
    host = "*",
    port = 4080,
    clients = {},
    players = {},
    bullets = {},
    enemies = {},
    next_id = 1,
    map_w = 1920,
    map_h = 1080,
    update_rate = 1/20
}

local function log(msg)
    print(os.date("[%H:%M:%S] ") .. msg)
end

local function spawn_enemy()
    local angle = math.random() * math.pi * 2
    local dist = 400 + math.random() * 300
    local enemy = {
        x = server.map_w/2 + math.cos(angle) * dist,
        y = server.map_h/2 + math.sin(angle) * dist,
        hp = 5,
        max_hp = 5,
        angle = 0,
        shoot_timer = 0
    }
    table.insert(server.enemies, enemy)
    log("Enemy spawned at " .. math.floor(enemy.x) .. "," .. math.floor(enemy.y))
    return enemy
end

local function broadcast(msg)
    for _, client in ipairs(server.clients) do
        pcall(function()
            client.socket:send(msg .. "\n")
        end)
    end
end

local function handle_message(client, msg)
    if msg:sub(1, 5) == "NAME:" then
        client.name = msg:sub(6)
        log("Client " .. client.id .. " is " .. client.name)
        client.socket:send("CONNECTED:" .. client.id .. "\n")
        
    elseif msg:sub(1, 5) == "MOVE:" then
        local x = tonumber(msg:match("x:([%d%.%-]+)"))
        local y = tonumber(msg:match("y:([%d%.%-]+)"))
        local angle = tonumber(msg:match("angle:([%d%.%-]+)"))
        local hp = tonumber(msg:match("hp:([%d]+)"))
        
        if x and y then
            server.players[client.id] = {
                x = x, y = y,
                angle = angle or 0,
                hp = hp or 5,
                name = client.name or "Player"
            }
        end
        
    elseif msg:sub(1, 6) == "SHOOT:" then
        local dx = tonumber(msg:match("dx:([%d%.%-]+)"))
        local dy = tonumber(msg:match("dy:([%d%.%-]+)"))
        
        if dx and dy and server.players[client.id] then
            local player = server.players[client.id]
            table.insert(server.bullets, {
                x = player.x,
                y = player.y,
                vx = dx * 340,
                vy = dy * 340,
                life = 3,
                owner = client.id,
                is_enemy = false
            })
        end
    end
end

local function update_game(dt)
    -- Обновление врагов
    for _, enemy in ipairs(server.enemies) do
        enemy.shoot_timer = enemy.shoot_timer - dt
        if enemy.shoot_timer <= 0 then
            enemy.shoot_timer = 1.2
            local angle = math.random() * math.pi * 2
            table.insert(server.bullets, {
                x = enemy.x,
                y = enemy.y,
                vx = math.cos(angle) * 250,
                vy = math.sin(angle) * 250,
                life = 4,
                owner = 0,
                is_enemy = true
            })
        end
    end
    
    -- Обновление пуль
    for i = #server.bullets, 1, -1 do
        local b = server.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        
        if b.life <= 0 then
            table.remove(server.bullets, i)
        end
    end
    
    -- Спаун врагов если их меньше 3
    while #server.enemies < 3 do
        spawn_enemy()
    end
end

local function build_state()
    local state = '{'
    
    state = state .. '"players":{'
    for id, player in pairs(server.players) do
        state = state .. '"' .. id .. '":{'
        state = state .. '"x":' .. string.format("%.2f", player.x) .. ','
        state = state .. '"y":' .. string.format("%.2f", player.y) .. ','
        state = state .. '"hp":' .. player.hp .. ','
        state = state .. '"angle":' .. string.format("%.2f", player.angle) .. ','
        state = state .. '"name":"' .. (player.name or "Player") .. '"'
        state = state .. '},'
    end
    if #state > 12 then state = state:sub(1, -2) end
    state = state .. '},'
    
    state = state .. '"enemies":['
    for _, enemy in ipairs(server.enemies) do
        state = state .. '{'
        state = state .. '"x":' .. string.format("%.2f", enemy.x) .. ','
        state = state .. '"y":' .. string.format("%.2f", enemy.y) .. ','
        state = state .. '"hp":' .. enemy.hp .. ','
        state = state .. '"max_hp":' .. enemy.max_hp .. ','
        state = state .. '"angle":' .. string.format("%.2f", enemy.angle)
        state = state .. '},'
    end
    if state:sub(-1) == ',' then state = state:sub(1, -2) end
    state = state .. '],'
    
    state = state .. '"bullets":['
    for _, bullet in ipairs(server.bullets) do
        state = state .. '{'
        state = state .. '"x":' .. string.format("%.2f", bullet.x) .. ','
        state = state .. '"y":' .. string.format("%.2f", bullet.y) .. ','
        state = state .. '"vx":' .. string.format("%.2f", bullet.vx) .. ','
        state = state .. '"vy":' .. string.format("%.2f", bullet.vy) .. ','
        state = state .. '"is_enemy":' .. tostring(bullet.is_enemy or false)
        state = state .. '},'
    end
    if state:sub(-1) == ',' then state = state:sub(1, -2) end
    state = state .. ']'
    
    state = state .. '}'
    return state
end

function server.start()
    log("Starting Cubic Battle Server on port " .. server.port)
    
    local tcp_server = socket.tcp()
    tcp_server:settimeout(0)
    tcp_server:bind(server.host, server.port)
    tcp_server:listen(32)
    
    -- Спауним первых врагов
    for i = 1, 3 do
        spawn_enemy()
    end
    
    local update_timer = 0
    log("Server ready! Waiting for connections...")
    
    while true do
        -- Принимаем новых клиентов
        local client = tcp_server:accept()
        if client then
            client:settimeout(0)
            local new_client = {
                socket = client,
                id = server.next_id,
                name = "Player" .. server.next_id
            }
            server.next_id = server.next_id + 1
            table.insert(server.clients, new_client)
            server.players[new_client.id] = {
                x = server.map_w/2 + math.random(-100, 100),
                y = server.map_h/2 + math.random(-100, 100),
                hp = 5,
                angle = 0,
                name = new_client.name
            }
            log("Client " .. new_client.id .. " connected. Total: " .. #server.clients)
        end
        
        -- Читаем сообщения от клиентов
        for i = #server.clients, 1, -1 do
            local client = server.clients[i]
            local data, err = client.socket:receive("*l")
            
            while data do
                handle_message(client, data)
                data, err = client.socket:receive("*l")
            end
            
            if err == "closed" then
                log("Client " .. client.id .. " disconnected")
                server.players[client.id] = nil
                table.remove(server.clients, i)
            end
        end
        
        -- Игровой цикл
        socket.sleep(0.016)
        update_timer = update_timer + 0.016
        update_game(0.016)
        
        -- Отправляем состояние
        if update_timer >= server.update_rate then
            update_timer = 0
            local state = build_state()
            broadcast("STATE:" .. state)
        end
    end
end

-- Запуск
local success, err = pcall(server.start)
if not success then
    print("Server error: " .. tostring(err))
    print("Make sure luasocket is installed: luarocks install luasocket")
end
