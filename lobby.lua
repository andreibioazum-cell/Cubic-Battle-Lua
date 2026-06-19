local lobby = {}
local game = require("game")
local fontTitle, fontBtn
local animTimer = 0

local function drawButton(text, x, y, w, h, font)
    -- Тень кнопки (как просил, одинаковая везде)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 4, y + 4, w, h, 14, 14)
    -- Тело кнопки
    love.graphics.setColor(0.45, 0.15, 0.75, 1)
    love.graphics.rectangle("fill", x, y, w, h, 14, 14)
    -- Текст
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf(text, x, y + h/2 - 14, w, "center")
end

local buttons = {}
function lobby.updateButtons()
    local w, h = love.graphics.getDimensions()
    local startY = h * 0.4 -- ПОДНЯЛ ВЫШЕ
    buttons = {
        { text = "LOCAL GAME", y = startY, action = function() game.setOnlineMode(false); GameState.current = "game" end },
        { text = "ONLINE GAME", y = startY + 90, action = function() game.setOnlineMode(false); GameState.current = "game" end }
    }
end

function lobby.load()
    fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 45)
    fontBtn = love.graphics.newFont("Fredoka-Bold.ttf", 26)
    lobby.updateButtons()
end

function lobby.update(dt) animTimer = animTimer + dt end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    -- Фон
    love.graphics.clear(0.05, 0.05, 0.1)
    love.graphics.setColor(1, 1, 1, 0.2)
    for i = 1, 10 do
        local px = (math.sin(animTimer * 0.5 + i) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.3 + i) * 0.5 + 0.5) * h
        love.graphics.circle("fill", px, py, 2)
    end
    -- Заголовок (ВЫШЕ)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 0, h * 0.2, w, "center")

    for _, b in ipairs(buttons) do
        drawButton(b.text, w/2 - 140, b.y, 280, 62, fontBtn)
    end
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    for _, b in ipairs(buttons) do
        if x > w/2-140 and x < w/2+140 and y > b.y and y < b.y + 62 then b.action() end
    end
end

function lobby.resize() lobby.updateButtons() end
return lobby
