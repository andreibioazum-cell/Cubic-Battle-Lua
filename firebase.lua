-- firebase.lua
-- Firebase Realtime Database client for LOVE2D

local firebase = {}

-- ============================================================
-- CONFIG
-- ============================================================

local CONFIG = {
    databaseURL = "https://kek22-985c7-default-rtdb.firebaseio.com/",
    apiKey = "AIzaSyBrZmISt8-VGB5krT1moaJ_8RyoASIwlts",
}

-- ============================================================
-- HTTP REQUEST
-- ============================================================

local function httpRequest(method, url, data, callback)
    local success, http = pcall(require, "socket.http")
    if not success then
        print("ERROR: socket.http not found")
        if callback then callback(nil, "no_http") end
        return nil
    end
    
    local ltn12 = require("ltn12")
    
    print(method .. " " .. url)
    
    -- Try HTTPS first
    local ssl_success, https = pcall(require, "ssl.https")
    local http_lib = ssl_success and https or http
    
    local response_body = {}
    local res, code, headers = http_lib.request{
        url = url,
        method = method,
        headers = {
            ["Content-Type"] = "application/json"
        },
        source = data and ltn12.source.string(data) or nil,
        sink = ltn12.sink.table(response_body)
    }
    
    local result = table.concat(response_body)
    
    if code == 200 then
        print("SUCCESS: " .. code)
    else
        print("ERROR: " .. tostring(code))
        print("RESPONSE: " .. result)
    end
    
    if callback then
        callback(result, code)
    end
    
    return result, code
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
