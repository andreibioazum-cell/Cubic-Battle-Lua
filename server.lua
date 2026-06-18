-- Cubic Battle Server
-- Запуск: love server.lua

local server = {
    running = true,
    clients = {},
    bullets = {},
    enemies = {},
    player_id_counter = 1,
    update_timer = 0,
    update_interval = 1/20,
    port = 4080,
    max_players = 20
}

-- Константы
local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340
local ENEMY_SPEED = 140
local ENEMY_SIGHT = 650
local ENEMY_ATTACK_RANGE = 300
local SPAWN_X, SPAWN_Y = 0, 0
local ENEMY_BULLET_SPEED = 250
local ENEMY_BULLET_LIFE = 4

-- Логирование
local function log(msg)
    print(os.date("[%H:%M:%S] ") .. msg)
end

-- Генерация врага
local function spawn_enemy(px, py)
    local w, h = 1920, 1080
    local minR = math.min(w, h) * 0.30
    local maxR = math.min(w, h) * 0.45
    local a = math.random() * math.pi * 2
    local dist = minR + math.random() * (maxR - minR)
    return {
        x = px + math.cos(a) * dist,
        y = py + math.sin(a) * dist,
        hp = 5,
        max_hp = 5,
        angle = 0,
        state = "wander",
        shoot_t = 0,
        shoot_cooldown = 1.2,
        wander_t = 0,
        wander_dx = 0,
        wander_dy = 0
    }
end

-- Обновление пуль
local function update_bullets()
    for i = #server.bullets, 1, -1 do
        local b = server.bullets[i]
        b.x = b.x + b.vx * (1/20)
        b.y = b.y + b.vy * (1/20)
        b.life = b.life - 1/20
        
        if b.life <= 0 then
            table.remove(server.bullets, i)
        else
            -- Проверка попадания в игроков (для вражеских пуль)
            if b.is_enemy then
                for id, client in pairs(server.clients) do
                    local dx = b.x - client.x
                    local dy = b.y - client.y
                    if dx*dx + dy*dy <= (PLAYER_SIZE/2)^2 then
                        client.hp = client.hp - 1
                        table.remove(server.bullets, i)
                        if client.hp <= 0 then
                            client.hp = PLAYER_HP_MAX
                            client.x, client.y = SPAWN_X, SPAWN_Y
                            broadcast("CHAT:" .. client.name .. " was killed!")
                        end
                        break
                    end
                end
            else
                -- Проверка попадания во врагов (для пуль игрока)
                for _, enemy in ipairs(server.enemies) do
                    local dx = b.x - enemy.x
                    local dy = b.y - enemy.y
                    if dx*dx + dy*dy <= (PLAYER_SIZE/2)^2 then
                        enemy.hp = enemy.hp - 1
                        table.remove(server.bullets, i)
                        if enemy.hp <= 0 then
                            -- Удаляем врага, он заспавнится заново
                            table.remove(server.enemies, _)
                        end
                        break
                    end
                end
            end
        end
    end
end

-- Обновление врагов
local function update_enemies()
    for i, enemy in ipairs(server.enemies) do
        local nearest_dist = ENEMY_SIGHT
        local nearest = nil
        
        for _, client in pairs(server.clients) do
            local dx = client.x - enemy.x
            local dy = client.y - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < nearest_dist then
                nearest_dist = dist
                nearest = client
            end
        end
        
        if nearest then
            local dx = nearest.x - enemy.x
            local dy = nearest.y - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy) + 0.0001
            
            if dist < ENEMY_ATTACK_RANGE then
                -- Атака
                enemy.shoot_t = enemy.shoot_t - 1/20
                if enemy.shoot_t <= 0 then
                    enemy.shoot_t = enemy.shoot_cooldown
                    
                    -- Разброс
                    local spread = 0.08
                    local angle = math.atan2(dy, dx) + (math.random() - 0.5) * spread * 2
                    
                    table.insert(server.bullets, {
                        x = enemy.x + math.cos(angle) * PLAYER_SIZE * 0.6,
                        y = enemy.y + math.sin(angle) * PLAYER_SIZE * 0.6,
                        vx = math.cos(angle) * ENEMY_BULLET_SPEED,
                        vy = math.sin(angle) * ENEMY_BULLET_SPEED,
                        owner = -1,
                        life = ENEMY_BULLET_LIFE,
                        is_enemy = true,
                        size = 8
                    })
                end
                
                -- Отступление если слишком близко
                if dist < 80 then
                    local speed = ENEMY_SPEED * 0.6 / 20
                    enemy.x = enemy.x - dx/dist * speed
                    enemy.y = enemy.y - dy/dist * speed
                end
            else
                -- Движение к игроку
                local speed = ENEMY_SPEED / 20
                enemy.x = enemy.x + dx/dist * speed
                enemy.y = enemy.y + dy/dist * speed
                enemy.angle = math.atan2(dy, dx) + math.pi/2
            end
        else
            -- Блуждание
            enemy.wander_t = enemy.wander_t - 1/20
            if enemy.wander_t <= 0 then
                enemy.wander_t = 1 + math.random() * 2
                local a = math.random() * math.pi * 2
                enemy.wander_dx = math.cos(a)
                enemy.wander_dy = math.sin(a)
            end
            local speed = ENEMY_SPEED * 0.35 / 20
            enemy.x = enemy.x + enemy.wander_dx * speed
            enemy.y = enemy.y + enemy.wander_dy * speed
        end
    end
end

-- Сериализация состояния
local function serialize_table(tbl, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    local result = "{"
    local first = true
    
    for k, v in pairs(tbl) do
        if not first then result = result .. "," end
        first = false
        
        if type(k) == "string" then
            result = result .. string.format('"%s":', k)
        else
            result = result .. tostring(k) .. ":"
        end
        
        if type(v) == "table" then
            result = result .. serialize_table(v, depth + 1)
        elseif type(v) == "string" then
            result = result .. string.format('"%s"', v)
        elseif type(v) == "number" then
            result = result .. tostring(v)
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        else
            result = result .. "null"
        end
    end
    
    result = result .. "}"
    return result
end

-- Кодирование состояния игры
local function encode_game_state()
    local state = {
        players = {},
        bullets = {},
        enemies = {}
    }
    
    for id, client in pairs(server.clients) do
        state.players[id] = {
            x = client.x,
            y = client.y,
            hp = client.hp,
            angle = client.angle,
            name = client.name
        }
    end
    
    for _, b in ipairs(server.bullets) do
        state.bullets[#state.bullets + 1] = {
            x = b.x,
            y = b.y,
            vx = b.vx,
            vy = b.vy,
            is_enemy = b.is_enemy or false,
            size = b.size or 6
        }
    end
    
    for _, e in ipairs(server.enemies) do
        state.enemies[#state.enemies + 1] = {
            x = e.x,
            y = e.y,
            hp = e.hp,
            max_hp = e.max_hp,
            angle = e.angle
        }
    end
    
    return "STATE:" .. serialize_table(state)
end

-- Широковещательная отправка
local function broadcast(data)
    for _, client in pairs(server.clients) do
        client:send(data .. "\n")
    end
end

-- Парсинг сообщения
local function parse_message(data)
    local result = {}
    local current_key = nil
    local current_value = ""
    local in_string = false
    local escape = false
    
    for i = 1, #data do
        local char = data:sub(i, i)
        
        if escape then
            current_value = current_value .. char
            escape = false
        elseif char == "\\" then
            escape = true
        elseif char == '"' then
            in_string = not in_string
            if not in_string and current_key then
                result[current_key] = current_value
                current_key = nil
                current_value = ""
            end
        elseif not in_string then
            if char == ":" then
                current_key = current_value
                current_value = ""
            elseif char == "," or char == " " then
                if current_key and current_value ~= "" then
                    local num = tonumber(current_value)
                    if num then
                        result[current_key] = num
                    elseif current_value == "true" then
                        result[current_key] = true
                    elseif current_value == "false" then
                        result[current_key] = false
                    elseif current_value ~= "" then
                        result[current_key] = current_value
                    end
                    current_key = nil
                    current_value = ""
                end
            else
                current_value = current_value .. char
            end
        else
            current_value = current_value .. char
        end
    end
    
    return result
end

-- Запуск сервера
function server:start()
    log("=== Cubic Battle Server ===")
    log("Starting on port " .. self.port)
    
    local socket = require("socket")
    local master = socket.tcp()
    master:bind("*", self.port)
    master:listen(self.max_players)
    master:settimeout(0)
    
    log("Server is running!")
    log("Press ESC to stop")
    
    local timer = 0
    
    while self.running do
        -- Принятие подключений
        local client, err = master:accept()
        if client then
            client:settimeout(0)
            local ip, port = client:getpeername()
            
            if #self.clients >= self.max_players then
                client:send("ERROR:Server is full\n")
                client:close()
                log("Rejected connection - server full")
            else
                local id = self.player_id_counter
                self.player_id_counter = self.player_id_counter + 1
                
                self.clients[id] = {
                    socket = client,
                    ip = ip,
                    port = port,
                    x = SPAWN_X + math.random(-100, 100),
                    y = SPAWN_Y + math.random(-100, 100),
                    hp = PLAYER_HP_MAX,
                    angle = 0,
                    name = "Player" .. id,
                    last_update = os.time()
                }
                
                log(string.format("Player %d connected from %s:%d", id, ip, port))
                client:send(string.format("CONNECTED:%d\n", id))
                
                -- Отправляем состояние всем
                broadcast(encode_game_state())
            end
        end
        
        -- Чтение данных
        for id, client in pairs(self.clients) do
            local data, err = client.socket:receive("*l")
            if data then
                if string.sub(data, 1, 5) == "MOVE:" then
                    local params = parse_message(string.sub(data, 6))
                    if params.x and params.y then
                        client.x = params.x
                        client.y = params.y
                        client.angle = params.angle or client.angle
                    end
                elseif string.sub(data, 1, 6) == "SHOOT:" then
                    local params = parse_message(string.sub(data, 7))
                    if params.dx and params.dy then
                        table.insert(server.bullets, {
                            x = client.x + math.cos(client.angle - math.pi/2) * PLAYER_SIZE/2,
                            y = client.y + math.sin(client.angle - math.pi/2) * PLAYER_SIZE/2,
                            vx = params.dx * BULLET_SPEED,
                            vy = params.dy * BULLET_SPEED,
                            owner = id,
                            life = 3,
                            is_enemy = false,
                            size = 6
                        })
                    end
                elseif string.sub(data, 1, 5) == "NAME:" then
                    local name = string.sub(data, 6)
                    name = string.gsub(name, "%s+", "")
                    if #name > 0 and #name <= 20 then
                        client.name = name
                        log(string.format("Player %d renamed to %s", id, name))
                        broadcast("CHAT:" .. name .. " joined the game!")
                        broadcast(encode_game_state())
                    end
                elseif string.sub(data, 1, 5) == "CHAT:" then
                    local msg = string.sub(data, 6)
                    if #msg > 0 then
                        broadcast(string.format("CHAT:%s: %s", client.name, msg))
                        log(string.format("[CHAT] %s: %s", client.name, msg))
                    end
                end
            elseif err == "closed" then
                log(string.format("Player %d disconnected", id))
                client.socket:close()
                self.clients[id] = nil
                broadcast("CHAT:" .. client.name .. " left the game!")
                broadcast(encode_game_state())
            end
        end
        
        -- Обновление игровой логики
        timer = timer + 1/60
        if timer >= self.update_interval then
            timer = 0
            
            -- Спавн врагов
            while #self.enemies < #self.clients * 2 + 2 do
                local px, py = SPAWN_X, SPAWN_Y
                local first = true
                for _, c in pairs(self.clients) do
                    if first then
                        px, py = c.x, c.y
                        first = false
                    end
                end
                table.insert(self.enemies, spawn_enemy(px, py))
            end
            
            -- Обновление
            update_enemies()
            update_bullets()
            
            -- Отправка состояния
            if #self.clients > 0 then
                local state = encode_game_state()
                broadcast(state)
            end
        end
        
        love.timer.sleep(0.01)
    end
    
    -- Закрытие
    master:close()
    for _, client in pairs(self.clients) do
        client.socket:close()
    end
    log("Server stopped")
end

-- LÖVE функции
function love.load()
    log("Cubic Battle Server")
    log("Press ESC to stop")
    
    -- Запуск в отдельном потоке
    love.thread.getChannel("server"):push(server)
    
    local thread = love.thread.newThread([[
        local channel = love.thread.getChannel("server")
        local server = channel:pop()
        if server then
            server:start()
        end
    ]])
    thread:start()
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    
    love.graphics.print("=== Cubic Battle Server ===", 10, 10)
    love.graphics.print("Port: " .. server.port, 10, 40)
    love.graphics.print("Players: " .. #server.clients, 10, 70)
    love.graphics.print("Enemies: " .. #server.enemies, 10, 100)
    love.graphics.print("Bullets: " .. #server.bullets, 10, 130)
    love.graphics.print("Press ESC to stop", 10, 170)
    
    -- Список игроков
    love.graphics.print("Players:", 10, 210)
    local y = 240
    for id, client in pairs(server.clients) do
        love.graphics.print(string.format("  %d: %s (HP: %d)", id, client.name, client.hp), 10, y)
        y = y + 25
    end
end

function love.keypressed(key)
    if key == "escape" then
        server.running = false
        love.event.quit()
    end
end

function love.update(dt)
    -- Обновление UI
end

return server
