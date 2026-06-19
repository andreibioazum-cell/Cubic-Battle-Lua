-- firebase.lua - Полноценный Firebase для LÖVE2D
-- Проект: excalibur-228-e

local firebase = {}

-- ===== ВАШИ ДАННЫЕ FIREBASE =====
firebase.config = {
    databaseURL = "https://excalibur-228-e-default-rtdb.firebaseio.com/",
    apiKey = "AIzaSyANgZEPkd07xa0IAxwoP5Cg4-a9rtTX3WY",
    authDomain = "excalibur-228-e.firebaseapp.com",
    projectId = "excalibur-228-e"
}

-- ===== СОСТОЯНИЕ =====
local state = {
    connected = false,
    player_id = nil,
    player_name = nil,
    players = {},
    bullets = {},
    enemies = {},
    last_update = 0,
    update_interval = 1/10, -- 10 раз в секунду
    reconnect_timer = 0,
    room_id = "cubic_battle"
}

-- ===== HTTP ФУНКЦИИ =====
local function http_request(method, path, data, callback)
    local url = firebase.config.databaseURL .. path .. ".json"
    
    -- Загружаем socket
    local ok, http = pcall(require, "socket.http")
    if not ok then
        print("❌ Socket not available!")
        if callback then callback(nil) end
        return false
    end
    
    local ltn12 = require("ltn12")
    
    local request = {
        url = url,
        method = method,
        headers = {
            ["Content-Type"] = "application/json"
        }
    }
    
    if data then
        local json_str = firebase.encode_json(data)
        request.source = ltn12.source.string(json_str)
    end
    
    local response = {}
    request.sink = ltn12.sink.table(response)
    
    local res, code, headers = http.request(request)
    
    if callback then
        if code == 200 then
            local json_str = table.concat(response)
            local ok, result = pcall(function()
                return firebase.decode_json(json_str)
            end)
            if ok then
                callback(result)
            else
                callback(nil)
            end
        else
            callback(nil)
        end
    end
    
    return code == 200
end

-- ===== JSON КОДИРОВАНИЕ =====
function firebase.encode_json(tbl)
    local function encode(t)
        if type(t) == "table" then
            local items = {}
            for k, v in pairs(t) do
                local key = type(k) == "string" and string.format('"%s"', k) or tostring(k)
                table.insert(items, key .. ":" .. encode(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        elseif type(t) == "string" then
            return string.format('"%s"', string.gsub(t, '"', '\\"'))
        elseif type(t) == "number" then
            return tostring(t)
        elseif type(t) == "boolean" then
            return tostring(t)
        else
            return "null"
        end
    end
    return encode(tbl)
end

-- ===== JSON ДЕКОДИРОВАНИЕ =====
function firebase.decode_json(str)
    local pos = 1
    local len = #str
    
    local function skip_whitespace()
        while pos <= len and string.find(" \t\n\r", string.sub(str, pos, pos)) do
            pos = pos + 1
        end
    end
    
    local function parse_value()
        skip_whitespace()
        if pos > len then return nil end
        
        local char = string.sub(str, pos, pos)
        
        if char == "{" then
            return parse_object()
        elseif char == "[" then
            return parse_array()
        elseif char == '"' then
            return parse_string()
        elseif char == "t" then
            pos = pos + 4
            return true
        elseif char == "f" then
            pos = pos + 5
            return false
        elseif char == "n" then
            pos = pos + 4
            return nil
        else
            return parse_number()
        end
    end
    
    local function parse_object()
        local obj = {}
        pos = pos + 1
        skip_whitespace()
        
        if string.sub(str, pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        
        while true do
            skip_whitespace()
            local key = parse_string()
            skip_whitespace()
            if string.sub(str, pos, pos) ~= ":" then
                return nil
            end
            pos = pos + 1
            local value = parse_value()
            obj[key] = value
            
            skip_whitespace()
            local char = string.sub(str, pos, pos)
            if char == "}" then
                pos = pos + 1
                break
            elseif char == "," then
                pos = pos + 1
            else
                return nil
            end
        end
        
        return obj
    end
    
    local function parse_array()
        local arr = {}
        pos = pos + 1
        skip_whitespace()
        
        if string.sub(str, pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        
        while true do
            local value = parse_value()
            table.insert(arr, value)
            
            skip_whitespace()
            local char = string.sub(str, pos, pos)
            if char == "]" then
                pos = pos + 1
                break
            elseif char == "," then
                pos = pos + 1
            else
                return nil
            end
        end
        
        return arr
    end
    
    local function parse_string()
        pos = pos + 1
        local start = pos
        while pos <= len do
            local char = string.sub(str, pos, pos)
            if char == '"' then
                local result = string.sub(str, start, pos - 1)
                pos = pos + 1
                return result
            elseif char == "\\" then
                pos = pos + 2
            else
                pos = pos + 1
            end
        end
        return nil
    end
    
    local function parse_number()
        local start = pos
        while pos <= len do
            local char = string.sub(str, pos, pos)
            if not string.find("0123456789.-", char) then
                break
            end
            pos = pos + 1
        end
        local num_str = string.sub(str, start, pos - 1)
        return tonumber(num_str)
    end
    
    skip_whitespace()
    return parse_value()
end

-- ===== ОСНОВНЫЕ ФУНКЦИИ =====

-- Генерация ID
function firebase.generate_id()
    return "p_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- Подключение к Firebase
function firebase.connect(player_name)
    if state.connected then
        print("Already connected!")
        return true
    end
    
    state.player_name = player_name or "Player_" .. math.random(1000, 9999)
    state.player_id = firebase.generate_id()
    
    print("🔄 Connecting to Firebase...")
    print("📱 Player: " .. state.player_name)
    print("🆔 ID: " .. state.player_id)
    
    local player_data = {
        name = state.player_name,
        x = 0,
        y = 0,
        hp = 5,
        max_hp = 5,
        angle = 0,
        online = true,
        room = state.room_id,
        last_seen = os.time()
    }
    
    http_request("PUT", "players/" .. state.player_id, player_data, function(data)
        if data then
            state.connected = true
            print("✅ Connected to Firebase!")
            print("🌐 Database: " .. firebase.config.databaseURL)
        else
            print("❌ Failed to connect!")
            state.connected = false
        end
    end)
    
    return state.connected
end

-- Отключение
function firebase.disconnect()
    if state.connected then
        http_request("PATCH", "players/" .. state.player_id, {
            online = false,
            last_seen = os.time()
        })
        state.connected = false
        print("🔌 Disconnected from Firebase")
    end
end

-- Синхронизация игроков
function firebase.sync_players()
    if not state.connected then return end
    
    http_request("GET", "players", function(data)
        if data then
            state.players = {}
            for id, player in pairs(data) do
                if id ~= state.player_id and player.online and player.room == state.room_id then
                    state.players[id] = player
                end
            end
        end
    end)
end

-- Обновление позиции
function firebase.update_position(x, y, angle, hp)
    if not state.connected then return end
    
    http_request("PATCH", "players/" .. state.player_id, {
        x = x,
        y = y,
        angle = angle,
        hp = hp or 5,
        last_seen = os.time()
    })
end

-- Создание пули
function firebase.shoot(x, y, dx, dy)
    if not state.connected then return end
    
    local bullet_id = "b_" .. os.time() .. "_" .. math.random(1000, 9999)
    http_request("PUT", "bullets/" .. bullet_id, {
        x = x,
        y = y,
        vx = dx * 340,
        vy = dy * 340,
        owner = state.player_id,
        owner_name = state.player_name,
        life = 3,
        created = os.time()
    })
end

-- Удаление пули
function firebase.delete_bullet(bullet_id)
    if not state.connected then return end
    http_request("DELETE", "bullets/" .. bullet_id)
end

-- Синхронизация пуль
function firebase.sync_bullets()
    if not state.connected then return end
    
    http_request("GET", "bullets", function(data)
        if data then
            state.bullets = {}
            for id, bullet in pairs(data) do
                if os.time() - bullet.created < 3 then
                    state.bullets[id] = bullet
                else
                    firebase.delete_bullet(id)
                end
            end
        end
    end)
end

-- Обновление (вызывается каждый кадр)
function firebase.update(dt)
    if not state.connected then return end
    
    state.last_update = state.last_update + dt
    if state.last_update >= state.update_interval then
        state.last_update = 0
        firebase.sync_players()
        firebase.sync_bullets()
    end
end

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====

function firebase.is_connected()
    return state.connected
end

function firebase.get_player_id()
    return state.player_id
end

function firebase.get_player_name()
    return state.player_name
end

function firebase.get_players()
    return state.players
end

function firebase.get_bullets()
    return state.bullets
end

function firebase.get_players_count()
    local count = 0
    for _ in pairs(state.players) do count = count + 1 end
    return count
end

return firebase
