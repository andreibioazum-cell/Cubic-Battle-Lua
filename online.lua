local online = {}

local API_KEY = "AIzaSyDJEqopxP5EqEoxP_ehO3jFXbNztu3DgVs"
local DB_URL = "https://cubicbattleserver-19ae2-default-rtdb.firebaseio.com"

local playerId = ""
local roomId = ""
local connected = false
local enemyData = nil
local enemyBulletsData = nil
local responseQueue = {}
local requestQueue = {}

-- простой JSON (без библиотек)
local json = {}
function json.encode(t)
    if type(t) == "table" then
        local p = {}
        for k,v in pairs(t) do p[#p+1] = '"'..tostring(k)..'":'..json.encode(v) end
        return "{"..table.concat(p,",").."}"
    elseif type(t) == "string" then return '"'..t:gsub('"','\\"')..'"'
    elseif type(t) == "number" then return tostring(t)
    elseif type(t) == "boolean" then return t and "true" or "false" end
    return "null"
end

function json.decode(s)
    if not s or s == "" then return nil end
    s = s:gsub("%s","")
    if s:sub(1,1) == "{" then
        local r = {}
        s = s:sub(2,-2)
        if s == "" then return r end
        local depth, key, start = 0, nil, 1
        local instr = false
        for i = 1, #s do
            local c = s:sub(i,i)
            if c == '"' then instr = not instr end
            if not instr then
                if c == '{' or c == '[' then depth = depth + 1
                elseif c == '}' or c == ']' then depth = depth - 1
                elseif c == ':' and depth == 0 then
                    key = s:sub(start,i-1):gsub('"','')
                    start = i + 1
                elseif c == ',' and depth == 0 then
                    r[key] = json.decode(s:sub(start,i-1))
                    start = i + 1
                end
            end
        end
        if key then r[key] = json.decode(s:sub(start)) end
        return r
    elseif s:sub(1,1) == '"' then return s:sub(2,-2):gsub('\\"','"')
    elseif s == "true" then return true
    elseif s == "false" then return false
    elseif s == "null" then return nil
    else return tonumber(s) end
end

function online.init()
    playerId = "player_" .. love.math.random(10000, 99999)
    connected = true
    roomId = ""
    print("Online: player ID = " .. playerId)
end

function online.update(dt)
    -- обрабатываем ответы
    for i = #responseQueue, 1, -1 do
        local resp = responseQueue[i]
        if resp.type == "rooms" then
            local data = json.decode(resp.body)
            if data then
                for id, room in pairs(data) do
                    if room.state == "waiting" and room.host ~= playerId then
                        roomId = id
                        online._sendJoinRequest(id)
                        break
                    end
                end
            end
            if roomId == "" then
                -- создаём комнату
                roomId = "room_" .. os.time()
                online._sendCreateRoom()
            end
        elseif resp.type == "players" then
            local data = json.decode(resp.body)
            if data then
                for id, state in pairs(data) do
                    if id ~= playerId and state.x then
                        enemyData = state
                        enemyBulletsData = state.bullets or {}
                        break
                    end
                end
            end
        end
        table.remove(responseQueue, i)
    end
end

function online._httpGet(url, respType)
    love.system.openURL(url)
    -- заглушка: сохраняем запрос для обработки
    table.insert(requestQueue, { url = url, type = respType })
end

function online._httpPut(url, body)
    love.system.openURL(url .. "&data=" .. body)
end

function online._sendCreateRoom()
    local url = DB_URL .. "/rooms/" .. roomId .. ".json"
    local data = json.encode({ host = playerId, state = "waiting" })
    online._httpPut(url, data)
end

function online._sendJoinRequest(id)
    local url = DB_URL .. "/rooms/" .. id .. ".json"
    local data = json.encode({ host = id, guest = playerId, state = "playing" })
    online._httpPut(url, data)
end

function online.joinGame()
    roomId = ""
    local url = DB_URL .. "/rooms.json"
    online._httpGet(url, "rooms")
end

function online.sendPlayer(x, y, hp, dirX, dirY)
    if roomId == "" then return end
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. ".json"
    local data = json.encode({ x = x, y = y, hp = hp, dirX = dirX, dirY = dirY })
    online._httpPut(url, data)
end

function online.sendBullets(bullets)
    if roomId == "" or #bullets == 0 then return end
    local clean = {}
    for i, b in ipairs(bullets) do
        clean["b" .. i] = { x = b.x, y = b.y, vx = b.vx, vy = b.vy, life = b.life }
    end
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. "/bullets.json"
    local data = json.encode(clean)
    online._httpPut(url, data)
end

function online.getEnemy()
    if roomId == "" then return nil end
    -- запрашиваем данные врага
    local url = DB_URL .. "/rooms/" .. roomId .. "/players.json"
    online._httpGet(url, "players")
    return enemyData
end

function online.getEnemyBullets()
    return enemyBulletsData or {}
end

function online.leaveRoom()
    if roomId == "" then return end
    local url = DB_URL .. "/rooms/" .. roomId .. "/players/" .. playerId .. ".json"
    love.system.openURL(url .. "?delete=true")
    roomId = ""
    enemyData = nil
    enemyBulletsData = {}
end

function online.onResponse(id, data)
    table.insert(responseQueue, { type = id, body = data })
end

function online.getRoomId()
    return roomId
end

function online.getPlayerId()
    return playerId
end

return online
