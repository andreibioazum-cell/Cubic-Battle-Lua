local lobby = {}
local game  -- загрузим лениво

local bg, font24, font18
local online = { connected = false, socket = nil, connecting = false }

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

-- ===== СЕТЕВЫЕ ФУНКЦИИ =====
local function loadSocket()
    local success, socket = pcall(require, "socket")
    if success then return socket end
    return nil
end

local function connectToServer(ip, port)
    if online.connected or online.connecting then return end
    
    local socket_lib = loadSocket()
    if not socket_lib then
        print("LuaSocket not available")
        return false
    end
    
    online.connecting = true
    online.socket = socket_lib.tcp()
    online.socket:settimeout(0)
    
    local success, err = online.socket:connect(ip, port)
    if success then
        online.connected = true
        online.connecting = false
        print("Connected to server: " .. ip .. ":" .. port)
        return true
    else
        print("Connection failed: " .. tostring(err))
        online.socket = nil
        online.connecting = false
        return false
    end
end

-- ===== КНОПКИ МЕНЮ =====
local buttons = {}
local function makeButton(text, x, y, w, h, action)
    table.insert(buttons, { text=text, x=x, y=y, w=w, h=h, action=action })
end

local function checkButtons(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x <= btn.x + btn.w and
           y >= btn.y and y <= btn.y + btn.h then
            if btn.action then btn.action() end
            return true
        end
    end
    return false
end

local function updateButtons()
    buttons = {}
    local w, h = love.graphics.getDimensions()
    local bw, bh = 260, 62
    local cx = w/2 - bw/2
    local cy = h/2 - 140
    
    makeButton("LOCAL GAME", cx, cy + 100, bw, bh, function()
        local g = tryLoadGame()
        if g then
            -- Отключаем онлайн в игре
            g.setOnlineMode(false)
            GameState.current = "game"
        end
    end)
    
    if online.connected then
        makeButton("ONLINE GAME", cx, cy + 180, bw, bh, function()
            local g = tryLoadGame()
            if g then
                g.setOnlineMode(true, online.socket)
                GameState.current = "game"
            end
        end)
        makeButton("DISCONNECT", cx, cy + 260, bw, bh, function()
            if online.socket then
                online.socket:close()
            end
            online.connected = false
            online.socket = nil
            updateButtons()
        end)
    else
        makeButton("CONNECT ONLINE", cx, cy + 180, bw, bh, function()
            connectToServer("192.168.1.100", 4080)
            updateButtons()
        end)
    end
    
    makeButton("QUIT", cx, cy + 340, bw, bh, function()
        love.event.quit()
    end)
end

function lobby.load()
    bg = bg or love.graphics.newImage("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end
    
    font24 = font24 or love.graphics.newFont("Fredoka-Bold.ttf", 24)
    font18 = font18 or love.graphics.newFont("Fredoka-Bold.ttf", 18)
    
    -- Предзагружаем game модуль
    tryLoadGame()
    
    updateButtons()
end

function lobby.update(dt)
    -- Проверяем ответ от сервера
    if online.connected and online.socket then
        local data, err = online.socket:receive("*l")
        if data then
            print("Server: " .. data)
        elseif err == "closed" then
            online.connected = false
            online.socket = nil
            updateButtons()
        end
    end
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Фон
    love.graphics.setColor(0.3, 0.6, 0.3, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    if bg then
        love.graphics.setColor(1, 1, 1, 0.3)
        local tw, th = bg:getWidth(), bg:getHeight()
        for x = 0, w, tw do
            for y = 0, h, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end
    
    -- Заголовок
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(font24)
    love.graphics.printf("CUBIC BATTLE", 0, h/2 - 240, w, "center")
    
    -- Версия игры
    love.graphics.setFont(font18)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("v11.5 | Love2D", 0, h/2 - 200, w, "center")
    
    -- Статус подключения
    if online.connecting then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.printf("Connecting...", 0, h/2 - 170, w, "center")
    elseif online.connected then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.printf("ONLINE - Connected", 0, h/2 - 170, w, "center")
    else
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.printf("OFFLINE", 0, h/2 - 170, w, "center")
    end
    
    -- Кнопки
    for _, btn in ipairs(buttons) do
        -- Тень
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", btn.x+4, btn.y+5, btn.w, btn.h, 14, 14)
        
        -- Кнопка
        love.graphics.setColor(0.55, 0.20, 0.85, 1)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 14, 14)
        
        -- Обводка
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 14, 14)
        
        -- Текст
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(font18)
        love.graphics.printf(btn.text, btn.x, btn.y + btn.h/2 - 12, btn.w, "center")
    end
    
    -- Подсказка внизу
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setFont(font18)
    love.graphics.printf("Tap to play | ESC to quit", 0, h - 60, w, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
end

function lobby.touchpressed(id, x, y)
    checkButtons(x, y)
end

function lobby.mousepressed(x, y)
    checkButtons(x, y)
end

function lobby.resize()
    updateButtons()
end

return lobby
