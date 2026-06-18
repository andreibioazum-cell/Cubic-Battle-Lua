local controls = require("controls")
local enemy = require("enemy")

local game = {}

local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15

local cube = { x=0, y=0, speed=260, angle=0, hp=PLAYER_HP_MAX, hit=0 }
local bullets = {}
local bg, playerImg, font
local cam = { x=0, y=0 }
local dead = false

-- ===== ОНЛАЙН ЧАСТЬ =====
local online = {
    enabled = false,
    connected = false,
    socket = nil,
    server_ip = "192.168.1.100", -- IP сервера (измените на свой)
    server_port = 4080,
    player_id = 0,
    players = {},
    enemies = {},
    bullets = {},
    name = "Player" .. math.random(1000, 9999),
    last_send = 0,
    send_interval = 1/20 -- 20 раз в секунду
}

-- Попытка загрузить сокеты
local socket_loaded = false
local function load_socket()
    if not socket_loaded then
        local success, result = pcall(require, "socket")
        if success then
            socket_loaded = true
            return result
        end
    end
    return nil
end

-- Подключение к серверу
function online.connect()
    if online.connected then return true end
    
    local socket = load_socket()
    if not socket then
        print("Socket library not available! Playing offline.")
        return false
    end
    
    online.socket = socket.tcp()
    online.socket:settimeout(0)
    
    local success, err = pcall(function()
        online.socket:connect(online.server_ip, online.server_port)
    end)
    
    if success then
        online.connected = true
        online.enabled = true
        print("Connected to server: " .. online.server_ip .. ":" .. online.server_port)
        online.send("NAME:" .. online.name)
        return true
    else
        print("Failed to connect: " .. tostring(err))
        online.socket = nil
        return false
    end
end

-- Отправка данных
function online.send(data)
    if not online.connected or not online.socket then return end
    local success, err = pcall(function()
        online.socket:send(data .. "\n")
    end)
    if not success then
        online.connected = false
        online.socket = nil
        print("Connection lost!")
    end
end

-- Получение данных
function online.receive()
    if not online.connected or not online.socket then return end
    
    local data, err = online.socket:receive("*l")
    if data then
        if string.sub(data, 1, 10) == "CONNECTED:" then
            online.player_id = tonumber(string.sub(data, 11))
            print("Connected! ID: " .. online.player_id)
            online.send("NAME:" .. online.name)
            
        elseif string.sub(data, 1, 6) == "STATE:" then
            local state_str = string.sub(data, 7)
            online.parse_state(state_str)
            
        elseif string.sub(data, 1, 5) == "CHAT:" then
            local msg = string.sub(data, 6)
            print("[CHAT] " .. msg)
            
        elseif string.sub(data, 1, 6) == "ERROR:" then
            print("[ERROR] " .. string.sub(data, 7))
        end
        
    elseif err == "closed" then
        online.connected = false
        online.socket = nil
        print("Disconnected from server")
    end
end

-- Парсинг состояния игры
function online.parse_state(data)
    -- Простой парсер без JSON
    local function extract_value(str, key)
        local pattern = '"' .. key .. '":([^,}]+)'
        local start_pos, end_pos, value = string.find(str, pattern)
        if value then
            value = string.gsub(value, '"', '')
            return value
        end
        return nil
    end
    
    -- Извлекаем игроков
    local players_str = string.match(data, '"players":({[^}]*})')
    if players_str then
        -- Очищаем старых игроков
        online.players = {}
        
        -- Парсим каждого игрока
        for id_str, info in string.gmatch(players_str, '([%d]+):({[^}]*})') do
            local id = tonumber(id_str)
            local x = tonumber(string.match(info, '"x":([^,}]+)'))
            local y = tonumber(string.match(info, '"y":([^,}]+)'))
            local hp = tonumber(string.match(info, '"hp":([^,}]+)'))
            local angle = tonumber(string.match(info, '"angle":([^,}]+)'))
            local name = string.match(info, '"name":"([^"]+)"')
            
            online.players[id] = {
                x = x or 0,
                y = y or 0,
                hp = hp or 5,
                angle = angle or 0,
                name = name or "Unknown"
            }
        end
    end
    
    -- Извлекаем врагов
    local enemies_str = string.match(data, '"enemies":(%[.*%])')
    if enemies_str then
        online.enemies = {}
        for info in string.gmatch(enemies_str, '({[^}]*})') do
            local x = tonumber(string.match(info, '"x":([^,}]+)'))
            local y = tonumber(string.match(info, '"y":([^,}]+)'))
            local hp = tonumber(string.match(info, '"hp":([^,}]+)'))
            local max_hp = tonumber(string.match(info, '"max_hp":([^,}]+)'))
            local angle = tonumber(string.match(info, '"angle":([^,}]+)'))
            
            table.insert(online.enemies, {
                x = x or 0,
                y = y or 0,
                hp = hp or 5,
                max_hp = max_hp or 5,
                angle = angle or 0
            })
        end
    end
    
    -- Извлекаем пули
    local bullets_str = string.match(data, '"bullets":(%[.*%])')
    if bullets_str then
        online.bullets = {}
        for info in string.gmatch(bullets_str, '({[^}]*})') do
            local x = tonumber(string.match(info, '"x":([^,}]+)'))
            local y = tonumber(string.match(info, '"y":([^,}]+)'))
            local vx = tonumber(string.match(info, '"vx":([^,}]+)'))
            local vy = tonumber(string.match(info, '"vy":([^,}]+)'))
            local is_enemy = string.match(info, '"is_enemy":([^,}]+)')
            
            table.insert(online.bullets, {
                x = x or 0,
                y = y or 0,
                vx = vx or 0,
                vy = vy or 0,
                is_enemy = (is_enemy == "true")
            })
        end
    end
end

-- Рисование онлайн игроков
function online.draw_players()
    for id, player in pairs(online.players) do
        if id ~= online.player_id then
            -- Рисуем другого игрока
            love.graphics.setColor(0.3, 0.8, 1, 0.8)
            love.graphics.rectangle("fill", player.x - 20, player.y - 20, 40, 40)
            love.graphics.setColor(1, 1, 1, 1)
            
            -- Имя игрока
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(player.name or "Player", player.x - 20, player.y - 35)
            
            -- HP бар другого игрока
            drawHPBar(player.x - 20, player.y - 45, 40, 4, player.hp or 5, 5, {0.3, 0.8, 0.3})
        end
    end
end

-- Рисование онлайн пуль
function online.draw_bullets()
    for _, b in ipairs(online.bullets) do
        if b.is_enemy then
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.circle("fill", b.x, b.y, 8)
        else
            love.graphics.setColor(0, 0, 1, 1)
            love.graphics.circle("fill", b.x, b.y, 6)
        end
    end
end

-- Рисование онлайн врагов
function online.draw_enemies()
    for _, e in ipairs(online.enemies) do
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", e.x - 25, e.y - 25, 50, 50)
        love.graphics.setColor(1, 1, 1, 1)
        drawHPBar(e.x - 25, e.y - 35, 50, 4, e.hp or 5, e.max_hp or 5, {0.9, 0.2, 0.2})
    end
end

-- ===== ОСНОВНАЯ ИГРА =====

local function spawnBullet(x, y, dx, dy)
    table.insert(bullets, {
        x=x, y=y,
        vx=dx*BULLET_SPEED,
        vy=dy*BULLET_SPEED,
        life=3
    })
    
    -- Отправляем выстрел на сервер
    if online.enabled and online.connected then
        online.send(string.format("SHOOT:dx:%.2f,dy:%.2f", dx, dy))
    end
end

local function drawHPBar(x, y, w, h, hp, max, color)
    if hp < 0 then hp = 0 end
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", x-2, y-2, w+4, h+4, 6, 6)
    love.graphics.setColor(0.15,0.15,0.15,1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", x, y, w * (hp/max), h, 4, 4)
    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

local function onHitPlayer(dmg)
    if dead then return end
    cube.hp = cube.hp - dmg
    cube.hit = 1
    if cube.hp <= 0 then
        cube.hp = 0
        dead = true
        GameState.current = "lobby"
    end
end

function game.load()
    cube.x, cube.y = 0, 0
    cube.angle = 0
    cube.hp = PLAYER_HP_MAX
    cube.hit = 0
    dead = false
    bullets = {}
    cam.x, cam.y = -love.graphics.getWidth()/2, -love.graphics.getHeight()/2

    bg = bg or love.graphics.newImage("grass.png")
    if bg then
        bg:setWrap("repeat","repeat")
    end

    playerImg = playerImg or love.graphics.newImage("player.png")
    if playerImg then
        playerImg:setFilter("nearest","nearest")
    end

    font = font or love.graphics.newFont("Fredoka-Bold.ttf", 18)

    controls.load()
    enemy.load()
    enemy.reset()
    
    -- Попытка подключиться к серверу
    online.connect()
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    if dead then return end

    controls.update(dt)

    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi/2
    end

    cube.hit = math.max(0, cube.hit - dt*3)

    local targetX = cube.x - love.graphics.getWidth()/2
    local targetY = cube.y - love.graphics.getHeight()/2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

    -- Обновляем локальные пули
    for i=#bullets,1,-1 do
        local b = bullets[i]
        b.x = b.x + b.vx*dt
        b.y = b.y + b.vy*dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets,i) end
    end

    -- Если онлайн режим включен - используем врагов с сервера
    if online.enabled and online.connected then
        -- Получаем данные от сервера
        online.receive()
        
        -- Отправляем позицию на сервер
        online.last_send = online.last_send + dt
        if online.last_send >= online.send_interval then
            online.last_send = 0
            online.send(string.format("MOVE:x:%.2f,y:%.2f,angle:%.2f", cube.x, cube.y, cube.angle))
        end
    else
        -- Оффлайн режим - используем локального врага
        enemy.update(dt, cube.x, cube.y, bullets, onHitPlayer)
    end
end

function game.draw()
    love.graphics.setColor(1,1,1,1)

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    -- Фон
    local w,h = love.graphics.getDimensions()
    if bg then
        local tw,th = bg:getWidth(), bg:getHeight()
        local sX = math.floor(cam.x/tw)*tw
        local sY = math.floor(cam.y/th)*th
        for x=sX, sX+w+tw, tw do
            for y=sY, sY+h+th, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end

    -- Локальные пули игрока
    love.graphics.setColor(0, 0, 0, 1)
    for _,b in ipairs(bullets) do
        love.graphics.circle("fill", b.x, b.y, 6)
    end
    
    -- Онлайн пули
    if online.enabled and online.connected then
        online.draw_bullets()
        online.draw_enemies()
        online.draw_players()
    end

    -- Линия прицела
    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0,0,0,0.55)
        love.graphics.setLineWidth(16)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + ax*180,
            cube.y + ay*180
        )
        love.graphics.setLineWidth(3)
        love.graphics.setColor(1,1,1,0.3)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + ax*180,
            cube.y + ay*180
        )
    end

    -- Оффлайн враг
    if not online.enabled or not online.connected then
        enemy.draw()
        local e = enemy.get()
        if e then
            drawHPBar(e.x - 28, e.y - 45, 56, 8, e.hp, 5, {0.9,0.2,0.2})
        end
    end

    -- Игрок
    if playerImg then
        love.graphics.setColor(0,0,0,0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        local t = cube.hit
        love.graphics.setColor(1, 1 - t*0.6, 1 - t*0.6, 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
        love.graphics.pop()
    end

    love.graphics.pop()

    -- HUD
    love.graphics.setColor(1,1,1,1)
    if font then
        love.graphics.setFont(font)
    end

    local barW, barH = 200, 18
    local px = love.graphics.getWidth() - barW - 20
    local py = 20
    drawHPBar(px, py, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3,0.85,0.35})

    love.graphics.setColor(1,1,1,1)
    if font then
        love.graphics.printf("HP " .. math.max(0,cube.hp) .. " / " .. PLAYER_HP_MAX,
            px, py + 22, barW, "right")
    end
    
    -- Статус онлайн
    if online.connected then
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.printf("ONLINE", px, py + 42, barW, "right")
        love.graphics.setColor(1,1,1,1)
    end

    controls.draw()
end

function game.touchpressed(id,x,y)
    controls.touchpressed(id,x,y)
end

function game.touchmoved(id,x,y)
    controls.touchmoved(id,x,y)
end

function game.touchreleased(id,x,y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then
        spawnBullet(cube.x, cube.y, dx, dy)
    end
end

return game
