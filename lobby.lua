local lobby = {}
local game

local bg, fontTitle, fontBtn, fontSmall
local online = { connected = false, socket = nil, connecting = false }
local animTimer = 0

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

-- ===== СЕТЬ =====
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

-- ===== КНОПКИ =====
local buttons = {}
local function makeButton(text, y, action)
    table.insert(buttons, { text=text, y=y, action=action })
end

local function updateButtons()
    buttons = {}
    local h = love.graphics.getHeight()
    
    -- Считаем от центра экрана
    local startY = h/2 + 30
    
    makeButton("LOCAL GAME", startY, function()
        local g = tryLoadGame()
        if g then
            g.setOnlineMode(false)
            GameState.current = "game"
        end
    end)
    
    if online.connected then
        makeButton("ONLINE GAME", startY + 75, function()
            local g = tryLoadGame()
            if g then
                g.setOnlineMode(true, online.socket)
                GameState.current = "game"
            end
        end)
        makeButton("DISCONNECT", startY + 150, function()
            if online.socket then
                online.socket:close()
            end
            online.connected = false
            online.socket = nil
            updateButtons()
        end)
    else
        makeButton("CONNECT ONLINE", startY + 75, function()
            connectToServer("192.168.1.100", 4080)
            updateButtons()
        end)
    end
    
    makeButton("QUIT", startY + 225, function()
        love.event.quit()
    end)
end

function lobby.load()
    bg = bg or love.graphics.newImage("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end
    
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 52)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 26)
    fontSmall = fontSmall or love.graphics.newFont("Fredoka-Bold.ttf", 18)
    
    tryLoadGame()
    updateButtons()
    animTimer = 0
end

function lobby.update(dt)
    animTimer = animTimer + dt
    
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
    
    -- ===== ГРАДИЕНТНЫЙ ФОН =====
    -- Верх - тёмно-фиолетовый, низ - тёмно-синий
    local gradientSteps = 60
    local stepH = h / gradientSteps
    for i = 0, gradientSteps - 1 do
        local t = i / (gradientSteps - 1)
        local r = 0.08 + t * 0.07
        local g = 0.02 + t * 0.05
        local b = 0.18 + t * 0.30
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", 0, i * stepH, w, stepH + 1)
    end
    
    -- Трава с низкой прозрачностью для текстуры
    if bg then
        love.graphics.setColor(1, 1, 1, 0.08)
        local tw, th = bg:getWidth(), bg:getHeight()
        for x = 0, w, tw do
            for y = 0, h, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end
    
    -- Частицы на фоне (звёздочки)
    love.graphics.setColor(1, 1, 1, 0.4)
    for i = 1, 30 do
        local px = (math.sin(animTimer * 0.3 + i * 7.3) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.5 + i * 4.7) * 0.5 + 0.5) * h
        local size = 1 + math.sin(animTimer * 2 + i) * 0.5
        love.graphics.circle("fill", px, py, size)
    end
    
    -- ===== ЗАГОЛОВОК =====
    local titleY = h/2 - 180
    
    -- Свечение заголовка
    love.graphics.setColor(0.55, 0.20, 0.85, 0.3)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", -3, titleY - 3, w, "center")
    love.graphics.printf("CUBIC BATTLE", 3, titleY + 3, w, "center")
    love.graphics.printf("CUBIC BATTLE", -3, titleY + 3, w, "center")
    love.graphics.printf("CUBIC BATTLE", 3, titleY - 3, w, "center")
    
    -- Основной заголовок
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("CUBIC BATTLE", 0, titleY, w, "center")
    
    -- Подзаголовок
    love.graphics.setColor(0.7, 0.7, 1.0, 0.8)
    love.graphics.setFont(fontSmall)
    love.graphics.printf("HARDCORE CUBE SHOOTER", 0, titleY + 55, w, "center")
    
    -- Статус подключения
    if online.connecting then
        love.graphics.setColor(1, 0.9, 0, 0.9)
        love.graphics.printf("CONNECTING...", 0, titleY + 80, w, "center")
    elseif online.connected then
        love.graphics.setColor(0, 1, 0.3, 0.9)
        love.graphics.printf("ONLINE - READY", 0, titleY + 80, w, "center")
    else
        love.graphics.setColor(1, 0.3, 0.3, 0.7)
        love.graphics.printf("OFFLINE MODE", 0, titleY + 80, w, "center")
    end
    
    -- ===== КНОПКИ =====
    local bw, bh = 280, 60
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        
        -- Тень кнопки
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", bx + 5, by + 5, bw, bh, 16, 16)
        
        -- Тело кнопки (градиент)
        love.graphics.setColor(0.45, 0.12, 0.75, 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 16, 16)
        
        -- Блик сверху
        love.graphics.setColor(0.6, 0.3, 0.9, 0.5)
        love.graphics.rectangle("fill", bx + 4, by + 2, bw - 8, bh/2, 16, 16)
        
        -- Обводка
        love.graphics.setColor(0.8, 0.6, 1, 0.8)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", bx, by, bw, bh, 16, 16)
        
        -- Текст кнопки
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf(btn.text, bx, by + bh/2 - 14, bw, "center")
    end
    
    -- ===== ФУТЕР =====
    love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
    love.graphics.setFont(fontSmall)
    love.graphics.printf("v11.5 | TAP TO START", 0, h - 50, w, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local bw, bh = 280, 60
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            if btn.action then btn.action() end
            return
        end
    end
end

function lobby.mousepressed(x, y)
    lobby.touchpressed(1, x, y)
end

function lobby.resize()
    updateButtons()
end

return lobby
