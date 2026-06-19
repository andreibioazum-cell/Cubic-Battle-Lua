local controls = require("controls")
local enemy = require("enemy")
local firebase = require("firebase")
local json = require("json")

local game = {}

local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15

local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = PLAYER_HP_MAX, hit = 0 }
local bullets = {}
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false
local onDeathCallback = nil

local mode = "offline"
local room_id = nil
local player_id = nil
local players = {}
local online_bullets = {}
local kill_messages = {}
local player_name = "Player" .. math.random(1000, 9999)
local last_send = 0
local send_interval = 1 / 10
local listener = nil

-- ============================================================
-- DRAW FUNCTIONS
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
    local scores = {}
    for pid, p in pairs(players) do
        if p.alive ~= false then
            table.insert(scores, { 
                id = pid, 
                kills = p.kills or 0, 
                name = p.name or "P" .. pid 
            })
        end
    end
    table.sort(scores, function(a, b) return a.kills > b.kills end)
    
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
    love.graphics.print("SCOREBOARD", bx + 10, by + 8)
    
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

local function drawRoomInfo()
    if mode == "firebase_host" or mode == "firebase_client" then
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.setFont(font)
        love.graphics.print("Room: " .. (room_id or "?"), 10, 60)
        love.graphics.print("ID: " .. (player_id or "?"), 10, 80)
        love.graphics.print("Players: " .. (#players + 1), 10, 100)
        if mode == "firebase_host" then
            love.graphics.setColor(1, 0.8, 0, 0.8)
            love.graphics.print("YOU ARE HOST", 10, 120)
        end
    end
end

-- ============================================================
-- BULLET
-- ============================================================

local function spawnBullet(x, y, dx, dy)
    table.insert(bullets, {
        x = x,
        y = y,
        vx = dx * BULLET_SPEED,
        vy = dy * BULLET_SPEED,
        life = 3
    })
    
    if mode == "firebase_host" or mode == "firebase_client" then
        if room_id and player_id then
            local bullet_data = {
                x = x,
                y = y,
                vx = dx * BULLET_SPEED,
                vy = dy * BULLET_SPEED,
                player_id = player_id,
                time = love.timer.getTime()
            }
            firebase.addBullet(room_id, bullet_data)
        end
    end
end

-- ============================================================
-- DAMAGE
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
-- FIREBASE FUNCTIONS
-- ============================================================

function game.hostGame()
    room_id = "room_" .. tostring(math.random(1000, 9999))
    player_id = "host_" .. tostring(math.random(1000, 9999))
    
    print("Creating room: " .. room_id)
    
    local host_data = {
        playerId = player_id,
        x = cube.x,
        y = cube.y,
        angle = cube.angle,
        hp = cube.hp,
        name = player_name
    }
    
    firebase.createRoom(room_id, host_data, function(result, code)
        if code == 200 then
            print("Room created!")
            game.setMode("firebase_host")
            game.startListener()
        else
            print("Error: " .. tostring(code))
        end
    end)
    
    return true
end

function game.joinRandomRoom()
    firebase.get("rooms", function(data, code)
        if code == 200 and data then
            local rooms = json.decode(data)
            local available_rooms = {}
            
            if rooms then
                for id, room in pairs(rooms) do
                    if room.status == "waiting" then
                        table.insert(available_rooms, id)
                    end
                end
            end
            
            if #available_rooms > 0 then
                local room_id_input = available_rooms[1]
                print("Found room: " .. room_id_input)
                game.joinRoom(room_id_input)
            else
                print("No rooms, creating new...")
                game.hostGame()
            end
        else
            game.hostGame()
        end
    end)
    
    return true
end

function game.joinRoom(room_id_input)
    room_id = room_id_input
    player_id = "player_" .. tostring(math.random(1000, 9999))
    
    print("Joining room: " .. room_id)
    
    local player_data = {
        playerId = player_id,
        x = cube.x,
        y = cube.y,
        angle = cube.angle,
        hp = cube.hp,
        name = player_name
    }
    
    firebase.joinRoom(room_id, player_data, function(result, code)
        if code == 200 then
            print("Connected!")
            game.setMode("firebase_client")
            game.startListener()
        else
            print("Error: " .. tostring(code))
            game.hostGame()
        end
    end)
    
    return true
end

function game.leaveRoom()
    if room_id and player_id then
        firebase.leaveRoom(room_id, player_id)
        if mode == "firebase_host" then
            firebase.deleteRoom(room_id)
        end
    end
    
    room_id = nil
    player_id = nil
    players = {}
    online_bullets = {}
    kill_messages = {}
    game.setMode("offline")
end

function game.setMode(new_mode)
    mode = new_mode
    print("Mode: " .. mode)
end

function game.startListener()
    if not room_id then return end
    
    listener = firebase.listen(room_id, 0.1, function(data)
        if data then
            local room = json.decode(data)
            if room then
                if room.players then
                    for pid, p in pairs(room.players) do
                        if pid ~= player_id then
                            players[pid] = p
                        end
                    end
                end
                
                if room.bullets then
                    for _, b in ipairs(room.bullets) do
                        if b.player_id ~= player_id then
                            table.insert(online_bullets, b)
                        end
                    end
                end
            end
        end
    end)
end

function game.updatePlayerInFirebase()
    if not room_id or not player_id then return end
    
    local player_data = {
        x = cube.x,
        y = cube.y,
        angle = cube.angle,
        hp = cube.hp,
        alive = not dead,
        kills = 0
    }
    
    firebase.updatePlayer(room_id, player_id, player_data)
end

-- ============================================================
-- MAIN FUNCTIONS
-- ============================================================

function game.setOnDeath(callback)
    onDeathCallback = callback
end

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
        game.leaveRoom()
        GameState.current = "lobby"
    end)
    
    game.setMode("offline")
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    if dead then 
        controls.update(dt)
        return 
    end
    
    controls.update(dt)
    
    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    cube.hit = math.max(0, cube.hit - dt * 3)

    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

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

    if mode == "offline" then
        enemy.update(dt, cube.x, cube.y, bullets, onHitPlayer)
    end
    
    if mode == "firebase_host" or mode == "firebase_client" then
        last_send = last_send + dt
        if last_send >= send_interval then
            last_send = 0
            game.updatePlayerInFirebase()
        end
        
        if listener then
            listener(dt)
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

    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end
    
    for _, b in ipairs(online_bullets) do
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end

    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(14)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
    end

    if mode == "offline" then
        enemy.draw()
    end
    
    if mode == "firebase_host" or mode == "firebase_client" then
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
                
                love.graphics.setColor(1, 1, 1, 0.7)
                love.graphics.setFont(font)
                love.graphics.print(p.name or "P" .. pid, p.x - 20, p.y - 65)
                drawHPBar(p.x - 30, p.y - 50, 60, 6, p.hp or 5, 5, {0.3, 0.8, 0.3})
            end
        end
    end

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
        
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.setFont(font)
        love.graphics.print("YOU", cube.x - 20, cube.y - 65)
    end

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    if mode == "offline" then
        local e_obj = enemy.get()
        if e_obj then
            local ex = love.graphics.getWidth() - barW - margin
            drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("ENEMY " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
        end
    end
    
    drawRoomInfo()
    drawScoreboard()

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
        game.leaveRoom()
        GameState.current = "lobby"
    end
end

return game
