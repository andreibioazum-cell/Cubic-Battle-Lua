local lobby = {}

local btn = { w=220, h=75, x=0, y=0 }
local grad, lastW, lastH = nil, 0, 0
local fontTitle, fontSub, fontBtn
local stars = {}

local function mkGrad(w, h)
    return love.graphics.newMesh({
        {0,0, 0,0, 0.02,0.02,0.08,1},
        {w,0, 1,0, 0.10,0.05,0.20,1},
        {w,h, 1,1, 0.15,0.08,0.25,1},
        {0,h, 0,1, 0.05,0.03,0.12,1},
    }, "fan", "static")
end

local function generateStars(w, h)
    stars = {}
    math.randomseed(42) -- фиксированный seed для консистентности
    for i = 1, 150 do
        local x = love.math.random(0, w)
        local y = love.math.random(0, h)
        local size = love.math.random(1, 3)
        local brightness = 0.4 + love.math.random() * 0.6
        stars[#stars + 1] = {
            x = x,
            y = y,
            size = size,
            brightness = brightness,
            twinkle = love.math.random() * math.pi * 2
        }
    end
end

local function place()
    local w, h = love.graphics.getDimensions()
    btn.x = w/2 - btn.w/2
    btn.y = h/2 + 50
end

local function drawSpacedText(text, x, y, w, align, font, spacing)
    spacing = spacing or 0
    love.graphics.setFont(font)

    local totalW = 0
    local widths = {}
    for i=1, #text do
        local ch = text:sub(i,i)
        local cw = font:getWidth(ch)
        widths[i] = cw
        totalW = totalW + cw
    end
    totalW = totalW + spacing * (#text - 1)

    local startX = x
    if align == "center" then
        startX = x + (w - totalW)/2
    elseif align == "right" then
        startX = x + (w - totalW)
    end

    local outline = math.floor(2 * 0.85 + 0.5)

    love.graphics.setColor(0,0,0,1)
    local cx = startX
    for i=1, #text do
        local ch = text:sub(i,i)
        for dx=-outline, outline, outline do
            for dy=-outline, outline, outline do
                if dx ~= 0 or dy ~= 0 then
                    love.graphics.print(ch, cx+dx, y+dy)
                end
            end
        end
        cx = cx + widths[i] + spacing
    end

    love.graphics.setColor(1,1,1,1)
    cx = startX
    for i=1, #text do
        local ch = text:sub(i,i)
        love.graphics.print(ch, cx, y)
        cx = cx + widths[i] + spacing
    end
end

function lobby.load()
    fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 64)
    fontSub   = love.graphics.newFont("Fredoka-Bold.ttf", 22)
    fontBtn   = love.graphics.newFont("Fredoka-Bold.ttf", 30)
    local w, h = love.graphics.getDimensions()
    generateStars(w, h)
    place()
end

function lobby.resize()
    grad = nil
    local w, h = love.graphics.getDimensions()
    generateStars(w, h)
    place()
end

function lobby.update(dt) end

function lobby.draw()
    local w, h = love.graphics.getDimensions()

    if not grad or w ~= lastW or h ~= lastH then
        grad = mkGrad(w, h)
        generateStars(w, h)
        lastW, lastH = w, h
    end

    -- Фон с градиентом
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad, 0, 0)

    -- Рисуем звёзды
    for i = 1, #stars do
        local star = stars[i]
        local twinkle = math.sin(love.timer.getTime() * 2 + star.twinkle) * 0.3 + 0.7
        local brightness = star.brightness * twinkle
        love.graphics.setColor(1, 1, 1, brightness)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end

    -- Текст игры
    love.graphics.setColor(1,1,1,1)
    drawSpacedText("Cubic Battle", 0, h/2 - 150, w, "center", fontTitle, fontTitle:getWidth("A")*0.05)
    drawSpacedText("Touch & Dodge", 0, h/2 - 60, w, "center", fontSub, fontSub:getWidth("A")*0.05)

    -- Тень кнопки
    love.graphics.setColor(0,0,0,0.40)
    love.graphics.rectangle("fill", btn.x+6, btn.y+7, btn.w, btn.h, 18, 18)

    -- Основная кнопка (тёмная)
    love.graphics.setColor(0.08, 0.04, 0.12, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 18, 18)

    -- Градиентная полоса на кнопке
    local gradient = love.graphics.newMesh({
        {btn.x, btn.y, 0, 0, 0.30, 0.15, 0.40, 0.5},
        {btn.x + btn.w, btn.y, 1, 0, 0.35, 0.18, 0.45, 0.5},
        {btn.x + btn.w, btn.y + btn.h, 1, 1, 0.25, 0.12, 0.35, 0.3},
        {btn.x, btn.y + btn.h, 0, 1, 0.28, 0.14, 0.38, 0.3},
    }, "fan", "static")
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.draw(gradient, 0, 0)

    -- Граница кнопки (яркая)
    love.graphics.setColor(0.60, 0.30, 0.80, 1)
    love.graphics.setLineWidth(2.5)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 18, 18)

    -- Текст кнопки
    drawSpacedText("Play", btn.x, btn.y + 20, btn.w, "center", fontBtn, fontBtn:getWidth("A")*0.05)
end

function lobby.touchpressed(id, x, y)
    if x>=btn.x and x<=btn.x+btn.w and
       y>=btn.y and y<=btn.y+btn.h then
        GameState.current = "game"
    end
end

function lobby.touchmoved() end
function lobby.touchreleased() end

return lobby
