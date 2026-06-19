local lobby = {}

local fontTitle, fontBtn
local animTimer = 0
local game = nil
local connecting = false
local connect_error = ""
local hosting = false

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

local function connectToServer(ip, port)
    if connecting then return end
    
    local g = tryLoadGame()
    if not g then return end
    
    connecting = true
    connect_error = ""
    
    local success = g.connect(ip, port)
    
    if success then
        g.setMode("client")
        GameState.current = "game"
    else
        connect_error = "❌ Не удалось подключиться"
    end
    
    connecting = false
end

local function hostServer(port)
    if hosting then return end
    
    local g = tryLoadGame()
    if not g then return end
    
    hosting = true
    connect_error = ""
    
    local success = g.hostGame(port)
    
    if success then
        GameState.current = "game"
    else
        connect_error = "❌ Не удалось создать сервер"
    end
    
    hosting = false
end

local buttons = {}
local function makeButton(text, y, action, color)
    table.insert(buttons, { 
        text = text, 
        y = y, 
        action = action,
        color = color or {0.45, 0.15, 
