local lobby = {}

local fontTitle, fontBtn, fontSmall
local animTimer = 0
local game = nil
local connect_error = ""

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

local function hostGame()
    local g = tryLoadGame()
    if not g then return end
    
    connect_error = "Creating room..."
    
    local success = g.hostGame()
    
    if success then
        connect_error = ""
        GameState.current = "game"
    else
        connect_error = "ERROR: Failed to create room"
    end
end

local function joinRandomRoom()
    local g = tryLoadGame()
    if not g then return end
    
    connect_error = "Searching for room..."
    
    local success = g.joinRandomRoom()
    
    if success then
        connect_error = ""
        GameState.current = "game"
    else
        connect_error = "ERROR: No rooms found"
    end
end

local buttons = {}
local function makeButton(text, y, action, color)
    table.insert(buttons, { 
        text = text, 
        y = y, 
        action = action,
        color = color or {0.45, 0.15, 0.75}
    })
end

local function updateButtons()
    buttons = {}
    local h = love.graphics.getHeight()
    local startY = h/2 - 50
    
    makeButton("OFFLINE GAME", startY, function()
        local g = tryLoadGame()
        if g then
            g.leaveRoom()
            g.setMode("offline")
            g.load()
            GameState.current = "game"
        end
    end, {0.2, 0.6, 0.8})
    
    makeButton("CREATE ROOM", startY + 65, function()
        hostGame()
    end, {0.8, 0.3, 0.1})
    
    makeButton("FIND GAME", startY + 130, function()
        joinRandomRoom()
    end, {0.2, 0.7, 0.4})
    
    makeButton("QUIT", startY + 195, function()
        love.event.quit()
    end, {0.6, 0.2, 0.2})
end

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 48)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 20)
    fontSmall = fontSmall or love.graphics.newFont("Fredoka-Bold.ttf", 18)
    
    tryLoadGame()
    updateButtons()
    animTimer = 0
    connect_error = ""
end

function lobby.update(dt)
    animTimer = animTimer + dt
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
    
    love.graphics.setColor(1, 1, 1, 0.35)
    for i = 1, 50 do
        local px = (math.sin(animTimer * 0.3 + i * 7.3) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.5 + i * 4.7) * 0.5 + 0.5) * h
        local size = 1 + math.sin(animTimer * 2 + i) * 1
        love.graphics.circle("fill", px, py, size)
    end
    
    local titleY = h/2 - 180
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 0, titleY, w, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.9, 0.5)
    love.graphics.setFont(fontSmall)
    love.graphics.printf("Multiplayer Arena", 0, titleY + 55, w, "center")
    
    local bw, bh = 280, 55
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", bx + 3, by + 3, bw, bh, 12, 12)
        
        local color = btn.color or {0.45, 0.15, 0.75}
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(
            math.min(1, color[1] + 0.2),
            math.min(1, color[2] + 0.2),
            math.min(1, color[3] + 0.2),
            0.3
        )
        love.graphics.rectangle("fill", bx + 3, by + 2, bw - 6, bh/2, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf(btn.text, bx, by + bh/2 - 11, bw, "center")
    end
    
    if connect_error ~= "" then
        love.graphics.setColor(1, 0.3, 0.3, 0.8)
        love.graphics.setFont(fontSmall)
        love.graphics.printf(connect_error, 0, h - 40, w, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local bw, bh = 280, 55
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            if btn.action then 
                btn.action() 
            end
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
