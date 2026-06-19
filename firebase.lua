-- firebase.lua
-- ПОЛНОСТЬЮ РАБОЧАЯ ВЕРСИЯ ДЛЯ ТВОЕГО ПРОЕКТА!

local firebase = {}

-- ============================================================
-- ТВОИ ДАННЫЕ ИЗ FIREBASE (ВСТАВЛЕНЫ!)
-- ============================================================

local CONFIG = {
    databaseURL = "https://kek22-985c7-default-rtdb.firebaseio.com/",
    apiKey = "AIzaSyBrZmISt8-VGB5krT1moaJ_8RyoASIwlts",
    authDomain = "kek22-985c7.firebaseapp.com",
    projectId = "kek22-985c7",
}

-- ============================================================
-- HTTP ЗАПРОСЫ (РАБОТАЮТ НА LÖVE)
-- ============================================================

local function httpRequest(method, url, data, callback)
    local http = require("socket.http")
    local ltn12 = require("ltn12")
    
    local response_body = {}
    local res, code, headers = http.request{
        url = url,
        method = method,
        headers = {
            ["Content-Type"] = "application/json"
        },
        source = data and ltn12.source.string(data) or nil,
        sink = ltn12.sink.table(response_body)
    }
    
    local result = table.concat(response_body)
    
    if callback then
        callback(result, code)
    end
    
    return result, code
end

-- ============================================================
-- ФУНКЦИИ ДЛЯ РАБОТЫ С БАЗОЙ
-- ============================================================

function firebase.get(path, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    print("📡 GET: " .. url)
    return httpRequest("GET", url, nil, callback)
end

function firebase.put(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    print("📡 PUT: " .. url)
    return httpRequest("PUT", url, json_data, callback)
end

function firebase.post(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    print("📡 POST: " .. url)
    return httpRequest("POST", url, json_data, callback)
end

function firebase.delete(path, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    print("📡 DELETE: " .. url)
    return httpRequest("DELETE", url, nil, callback)
end

function firebase.patch(path, data, callback)
    local url = CONFIG.databaseURL .. path .. ".json"
    local json_data = require("json").encode(data)
    print("📡 PATCH: " .. url)
    return httpRequest("PATCH", url, json_data, callback)
end

-- ============================================================
-- КОМНАТЫ ДЛЯ МУЛЬТИПЛЕЕРА
-- ============================================================

function firebase.createRoom(roomId, hostData)
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
    
    return firebase.put("rooms/" .. roomId, room)
end

function firebase.joinRoom(roomId, playerData)
    return firebase.get("rooms/" .. roomId, function(data)
        if data then
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
                
                return firebase.put("rooms/" .. roomId .. "/players", room.players)
            end
        end
        return nil
    end)
end

function firebase.leaveRoom(roomId, playerId)
    return firebase.delete("rooms/" .. roomId .. "/players/" .. playerId)
end

function firebase.deleteRoom(roomId)
    return firebase.delete("rooms/" .. roomId)
end

function firebase.getRoom(roomId, callback)
    return firebase.get("rooms/" .. roomId, callback)
end

-- ============================================================
-- ОБНОВЛЕНИЕ ПОЗИЦИИ ИГРОКА
-- ============================================================

function firebase.updatePlayer(roomId, playerId, data)
    local playerData = {
        x = data.x or 0,
        y = data.y or 0,
        angle = data.angle or 0,
        hp = data.hp or 5,
        alive = data.alive or true,
        kills = data.kills or 0,
        lastUpdate = os.time()
    }
    
    return firebase.put("rooms/" .. roomId .. "/players/" .. playerId, playerData)
end

-- ============================================================
-- ПУЛИ
-- ============================================================

function firebase.addBullet(roomId, bulletData)
    local bullet = {
        x = bulletData.x or 0,
        y = bulletData.y or 0,
        vx = bulletData.vx or 0,
        vy = bulletData.vy or 0,
        playerId = bulletData.playerId or "unknown",
        time = os.time(),
        life = 3.0
    }
    
    return firebase.post("rooms/" .. roomId .. "/bullets", bullet)
end

function firebase.clearBullets(roomId)
    return firebase.delete("rooms/" .. roomId .. "/bullets")
end

-- ============================================================
-- СЛУШАТЕЛЬ (polling)
-- ============================================================

function firebase.listen(path, interval, callback)
    local timer = 0
    local lastData = nil
    
    return function(dt)
        timer = timer + dt
        if timer >= interval then
            timer = 0
            firebase.get(path, function(data)
                if data and data ~= lastData then
                    lastData = data
                    callback(data)
                end
            end)
        end
    end
end

return firebase
