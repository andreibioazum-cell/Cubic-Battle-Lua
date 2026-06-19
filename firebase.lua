-- firebase.lua
-- Использует встроенный love.net (работает на Android без SSL библиотек!)

local firebase = {}

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    databaseURL = "https://kek22-985c7-default-rtdb.firebaseio.com/",
    apiKey = "AIzaSyBrZmISt8-VGB5krT1moaJ_8RyoASIwlts",
}

-- ============================================================
-- HTTP REQUEST через love.net
-- ============================================================

local function httpRequest(method, url, data, callback)
    -- Проверяем love.net
    if not love.net then
        print("ERROR: love.net not available!")
        if callback then callback(nil, "no_net") end
        return nil
    end
    
    print(method .. " " .. url)
    
    -- Создаём HTTP запрос
    local request = love.net.newHTTPRequest(url, method)
    
    -- Заголовки
    request:setHeader("Content-Type", "application/json")
    
    -- Тело запроса (для POST/PUT/PATCH)
    if data then
        request:setBody(data)
    end
    
    -- Отправляем асинхронно
    local success, err = request:send(function(response)
        local body = response:getBody()
        local code = response:getStatus()
        
        if code == 200 then
            print("SUCCESS: " .. code)
        else
            print("ERROR: " .. code .. " - " .. body)
        end
        
        if callback then
            callback(body, code)
        end
    end)
    
    if not success then
        print("ERROR sending request: " .. tostring(err))
        if callback then callback(nil, err) end
    end
    
    return request
end

-- ============================================================
-- DATABASE FUNCTIONS
-- ============================================================

function firebase.get(path, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    return httpRequest("GET", url, nil, callback)
end

function firebase.put(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    return httpRequest("PUT", url, json_data, callback)
end

function firebase.post(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    return httpRequest("POST", url, json_data, callback)
end

function firebase.delete(path, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    return httpRequest("DELETE", url, nil, callback)
end

function firebase.patch(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    return httpRequest("PATCH", url, json_data, callback)
end

-- ============================================================
-- ROOMS
-- ============================================================

function firebase.createRoom(roomId, hostData, callback)
    local room = {
        host = hostData.playerId,
        created = os.time(),
        players = {
            [hostData.playerId] = {
                x = hostData.x or 0,
                y = hostData.y or 0,
                angle = hostData.angle or 0,
                hp = hostData.hp or 5,
                name = hostData.name or "Host",
                alive = true,
                kills = 0,
                joinTime = os.time()
            }
        },
        bullets = {},
        status = "waiting",
        lastUpdate = os.time()
    }
    
    return firebase.put("rooms/" .. roomId, room, callback)
end

function firebase.joinRoom(roomId, playerData, callback)
    return firebase.get("rooms/" .. roomId, function(data, code)
        if data and code == 200 then
            local room = require("json").decode(data)
            if room then
                room.players[playerData.playerId] = {
                    x = playerData.x or 0,
                    y = playerData.y or 0,
                    angle = playerData.angle or 0,
                    hp = playerData.hp or 5,
                    name = playerData.name or "Player",
                    alive = true,
                    kills = 0,
                    joinTime = os.time()
                }
                room.lastUpdate = os.time()
                
                return firebase.put("rooms/" .. roomId .. "/players", room.players, callback)
            end
        end
        if callback then callback(nil, code) end
        return nil
    end)
end

function firebase.leaveRoom(roomId, playerId, callback)
    return firebase.delete("rooms/" .. roomId .. "/players/" .. playerId, callback)
end

function firebase.deleteRoom(roomId, callback)
    return firebase.delete("rooms/" .. roomId, callback)
end

function firebase.getRoom(roomId, callback)
    return firebase.get("rooms/" .. roomId, callback)
end

function firebase.updatePlayer(roomId, playerId, data, callback)
    local playerData = {
        x = data.x or 0,
        y = data.y or 0,
        angle = data.angle or 0,
        hp = data.hp or 5,
        alive = data.alive or true,
        kills = data.kills or 0,
        lastUpdate = os.time()
    }
    
    return firebase.put("rooms/" .. roomId .. "/players/" .. playerId, playerData, callback)
end

function firebase.addBullet(roomId, bulletData, callback)
    local bullet = {
        x = bulletData.x or 0,
        y = bulletData.y or 0,
        vx = bulletData.vx or 0,
        vy = bulletData.vy or 0,
        playerId = bulletData.playerId or "unknown",
        time = os.time(),
        life = 3.0
    }
    
    return firebase.post("rooms/" .. roomId .. "/bullets", bullet, callback)
end

function firebase.clearBullets(roomId, callback)
    return firebase.delete("rooms/" .. roomId .. "/bullets", callback)
end

-- ============================================================
-- LISTENER (polling)
-- ============================================================

function firebase.listen(path, interval, callback)
    local timer = 0
    local lastData = nil
    
    return function(dt)
        timer = timer + dt
        if timer >= interval then
            timer = 0
            firebase.get(path, function(data, code)
                if data and code == 200 and data ~= lastData then
                    lastData = data
                    callback(data)
                end
            end)
        end
    end
end

return firebase
