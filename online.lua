local json = require("json")
local http = require("socket.http")
local ltn12 = require("ltn12")

local online = {}

local API_KEY = "AIzaSyDJEqopxP5EqEoxP_ehO3jFXbNztu3DgVs"
local DB_URL = "https://cubicbattleserver-19ae2-default-rtdb.firebaseio.com"

local playerId = ""
local roomId = ""
local idToken = ""

function online.init()
    -- анонимный вход
    local url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" .. API_KEY
    local body = json.encode({ returnSecureToken = true })
    
    local resp = {}
    local ok, err = http.request({
        url = url,
        method = "POST",
        source = ltn12.source.string(body),
        headers = {
            ["content-type"] = "application/json",
            ["content-length"] = #body
        },
        sink = ltn12.sink.table(resp)
    })
    
    if not ok then
        print("Firebase auth error:", err)
        return false
    end
    
    local data = json.decode(table.concat(resp))
    if data and data.localId then
        playerId = data.localId
        idToken = data.idToken
        return true
    end
    
    return false
end

function online.createRoom()
    roomId = "room_" .. os.time()
    local url = DB_URL .. "/rooms/" .. roomId .. ".json?auth=" .. idToken
    
    local data = json.encode({
        host = playerId,
        state = "waiting"
    })
    
    http.request({
        url = url,
        method = "PUT",
        source = ltn12.source.string(data),
        headers = { ["content-type"] = "application/json" }
    })
    
    return roomId
end

function online.findRoom()
    local url = DB_URL .. "/rooms.json?auth=" .. idToken
    local resp = {}
    
    http.request({
        url = url,
        method = "GET",
        sink = ltn12.sink.table(resp)
    })
    
    local data = json.decode(table.concat(resp))
    if not data then return nil end
    
    for id, room in pairs(data) do
        if room.state == "waiting" and room.host ~= playerId then
            roomId = id
            -- подключаемся как гость
            local joinUrl = DB_URL .. "/rooms/" .. id .. ".json?auth=" .. idToken
            local joinData = json.encode({
                host = room.host,
                guest = playerId,
                state = "playing"
            })
            http.request({
                url = joinUrl,
                method = "PUT",
                source = ltn12.source.string(joinData),
                headers = { ["content-type"] = "application/json" }
            })
            return id
        end
    end
    
    return nil
end

function online.sendPlayer(x, y, hp, dirX, dirY)
    if roomId == "" then return end
    
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. ".json?auth=" .. idToken
    local data = json.encode({
        x = x, y = y,
        hp = hp,
        dirX = dirX, dirY = dirY
    })
    
    http.request({
        url = url,
        method = "PUT",
        source = ltn12.source.string(data),
        headers = { ["content-type"] = "application/json" }
    })
end

function online.sendBullets(bullets)
    if roomId == "" then return end
    
    local clean = {}
    for i, b in ipairs(bullets) do
        clean["b" .. i] = {
            x = b.x, y = b.y,
            vx = b.vx, vy = b.vy,
            life = b.life
        }
    end
    
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. "/bullets.json?auth=" .. idToken
    local data = json.encode(clean)
    
    http.request({
        url = url,
        method = "PUT",
        source = ltn12.source.string(data),
        headers = { ["content-type"] = "application/json" }
    })
end

function online.getEnemy()
    if roomId == "" then return nil end
    
    local url = DB_URL .. "/rooms/" .. roomId .. "/players.json?auth=" .. idToken
    local resp = {}
    
    http.request({
        url = url,
        method = "GET",
        sink = ltn12.sink.table(resp)
    })
    
    local data = json.decode(table.concat(resp))
    if not data then return nil end
    
    for id, state in pairs(data) do
        if id ~= playerId and state.x then
            return state
        end
    end
    
    return nil
end

function online.getEnemyBullets()
    if roomId == "" then return nil end
    
    local url = DB_URL .. "/rooms/" .. roomId .. "/players.json?auth=" .. idToken
    local resp = {}
    
    http.request({
        url = url,
        method = "GET",
        sink = ltn12.sink.table(resp)
    })
    
    local data = json.decode(table.concat(resp))
    if not data then return nil end
    
    for id, state in pairs(data) do
        if id ~= playerId and state.bullets then
            return state.bullets
        end
    end
    
    return nil
end

function online.leaveRoom()
    if roomId == "" then return end
    
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. ".json?auth=" .. idToken
    http.request({
        url = url,
        method = "DELETE"
    })
    
    roomId = ""
end

function online.getRoomId()
    return roomId
end

function online.getPlayerId()
    return playerId
end

return online
