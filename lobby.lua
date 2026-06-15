local lobby = {}

local btn = { w = 180, h = 65, x = 0, y = 0 }
local time = 0
local bgMesh
local lastW, lastH = 0, 0
local titleFont, subFont, btnFont

local function makeBackground(w, h)
    -- простой градиентный фон
    return love.graphics.newMesh({
        { 0, 0, 0, 0,  0.55, 0.20, 0.85, 1 },
        { w, 0, 1, 0,  0.85, 0.25, 0.65, 1 },
        { w, h, 1, 1,  0.10, 0.02, 0.25, 1 },
        { 0, h, 0, 1,  0.18, 0.05, 0.35, 1 },
    }, "fan", "static")
end

local function placeButton()
    local w, h = love.graphics.getDimensions()
    btn.x = w / 2 - btn.w / 2
    btn.y = h / 2 + 40
end

function lobby.load()
    titleFont = titleFont or love.graphics.newFont(48)
    subFont = subFont or love.graphics.newFont(18)
    btnFont = btnFont or love.graphics.newFont(24)
    placeButton()
end

function lobby.resize()
    bgMesh = nil
    placeButton()
end

function lobby.update(dt)
    time = time + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- пересоздаём фон только при изменении размера
    if not bgMesh or w ~= lastW or h ~= lastH then
        bgMesh = makeBackground(w, h)
        lastW, lastH = w, h
        placeButton()
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bgMesh, 0, 0)
    
    -- заголовок
    love.graphics.setFont(titleFont)
    local title = "Cubic Battle"
    local tw = titleFont:getWidth(title)
    local floatY = math.sin(time * 1.2) * 3
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(title, w/2 - tw/2 + 3, h/4 + floatY + 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, w/2 - tw/2, h/4 + floatY)
    
    -- подзаголовок
    love.graphics.setFont(subFont)
    love.graphics.setColor(1, 1, 1, 0.6)
    local sub = "Touch & dodge"
    love.graphics.print(sub, w/2 - subFont:getWidth(sub)/2, h/4 + 70)
    
    -- кнопка
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", btn.x + 3, btn.y + 4, btn.w, btn.h, 14, 14)
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 14, 14)
    
    love.graphics.setColor(0.3, 0.1, 0.5, 1)
    love.graphics.setFont(btnFont)
    local text = "Play"
    love.graphics.print(text,
        btn.x + btn.w/2 - btnFont:getWidth(text)/2,
        btn.y + btn.h/2 - btnFont:getHeight()/2)
end

function lobby.touchpressed(id, x, y)
    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
        GameState.current = "game"
    end
end

return lobby
