local lobby = {}
local game

local fontTitle, fontBtn
local animTimer = 0

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

local buttons = {}
local function makeButton(text, y, action)
    table.insert(buttons, { text = text, y = y, action = action })
end

local function updateButtons()
    buttons = {}
    local h = love.graphics.getHeight()
    
    -- Кнопки ниже центра (StartY увеличена)
    local startY = h * 0.6
    
    makeButton("LOCAL GAME", startY, function()
        local g = tryLoadGame()
        if g then
            g.setOnlineMode(false)
            GameState.current = "game"
        end
    end)
    
    makeButton("ONLINE GAME", startY + 85, function()
        local g = tryLoadGame()
        if g then
            g.setOnlineMode(false)
            GameState.current = "game"
        end
    end)
end

function lobby.load()
    fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 42) -- Меньше
    fontBtn = love.graphics.newFont("Fredoka-Bold.ttf", 26)
    updateButtons()
    animTimer = 0
end

function lobby.update(dt)
    animTimer = animTimer + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Красивый градиентный фон
    local steps = 40
    for i = 0, steps do
        local t = i / steps
        love.graphics.setColor(0.05 + t*0.05, 0.01 + t*0.03, 0.15 + t*0.1)
        love.graphics.rectangle("fill", 0, i * (h/steps), w, h/steps + 1)
    end
    
    -- Анимация звёзд
    love.graphics.setColor(1, 1, 1, 0.2)
    for i = 1, 15 do
        local px = (math.sin(animTimer * 0.2 + i) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.3 + i * 2) * 0.5 + 0.5) * h
        love.graphics.circle("fill", px, py, 2)
    end
    
    -- Заголовок ниже и меньше
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 0, h * 0.38, w, "center")
    
    -- Кнопки
    local bw, bh = 280, 62
    love.graphics.setFont(fontBtn)
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        -- Тень кнопки
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", bx + 4, btn.y + 4, bw, bh, 15, 15)
        -- Тело кнопки
        love.graphics.setColor(0.45, 0.15, 0.75, 1)
        love.graphics.rectangle("fill", bx, btn.y, bw, bh, 15, 15)
        -- Текст
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(btn.text, bx, btn.y + bh/2 - 15, bw, "center")
    end
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local bw, bh = 280, 62
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        if x >= bx and x <= bx + bw and y >= btn.y and y <= btn.y + bh then
            btn.action()
            return
        end
    end
end

function lobby.resize() updateButtons() end

return lobby
