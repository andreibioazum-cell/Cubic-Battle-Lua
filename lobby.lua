local lobby = {}
local game

local fontTitle, fontBtn
local online = { connected = false, socket = nil, connecting = false }
local animTimer = 0

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

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

local buttons = {}
local function makeButton(text, y, action)
    table.insert(buttons, { text = text, y = y, action = action })
end

local function updateButtons()
    buttons = {}
    local h = love.graphics.getHeight()
    local startY = h/2 + 20
    
    makeButton("LOCAL GAME", startY, function()
        local g = tryLoadGame()
        if g then
            g.setOnlineMode(false)
            GameState.current = "game"
        end
    end)
    
    if online.connected then
        makeButton("ONLINE GAME", startY + 65, function()
            local g = tryLoadGame()
            if g then
                g.setOnlineMode(true, online.socket)
                GameState.current = "game"
            end
        end)
        makeButton("DISCONNECT", startY + 130, function()
            if online.socket then
                online.socket:close()
            end
            online.connected = false
            online.socket = nil
            updateButtons()
        end)
    else
        makeButton("CONNECT ONLINE", startY + 65, function()
            connectToServer("192.168.1.100", 4080)
            updateButtons()
        end)
    end
end

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 32)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 18)
    
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
    
    if online.connecting then
        local data, err = online.socket:receive("*l")
        if data then
            online.connected = true
            online.connecting = false
            updateButtons()
        end
    end
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
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
    
    -- БОЛЬШЕ ЗВЁЗД (50 штук)
    love.graphics.setColor(1, 1, 1, 0.35)
    for i = 1, 50 do
        local px = (math.sin(animTimer * 0.3 + i * 7.3) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.5 + i * 4.7) * 0.5 + 0.5) * h
        local size = 1 + math.sin(animTimer * 2 + i) * 1
        love.graphics.circle("fill", px, py, size)
    end
    
    -- Заголовок НИЖЕ
    local titleY = h/2 - 100
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 0, titleY, w, "center")
    
    local bw, bh = 220, 48
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", bx + 3, by + 3, bw, bh, 12, 12)
        
        love.graphics.setColor(0.45, 0.15, 0.75, 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(0.6, 0.3, 0.9, 0.4)
        love.graphics.rectangle("fill", bx + 3, by + 2, bw - 6, bh/2, 12, 12)
        
        love.graphics.setColor(0.8, 0.7, 1, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf(btn.text, bx, by + bh/2 - 11, bw, "center")
    end
    
    if online.connecting then
        love.graphics.setColor(1, 0.9, 0, 0.7)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("Connecting...", 0, h - 60, w, "center")
    elseif online.connected then
        love.graphics.setColor(0, 1, 0.3, 0.5)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("ONLINE", 0, h - 60, w, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local bw, bh = 220, 48
    
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
