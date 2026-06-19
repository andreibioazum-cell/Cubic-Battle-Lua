local lobby = {}

local btn = { w=220, h=75, x=0, y=0 }
local btnOnline = { w=220, h=55, x=0, y=0 }
local btnOffline = { w=220, h=55, x=0, y=0 }
local grad, lastW, lastH = nil, 0, 0
local fontTitle, fontSub, fontBtn

local function mkGrad(w, h)
    return love.graphics.newMesh({
        {0,0, 0,0, 0.45,0.15,0.80,1},
        {w,0, 1,0, 0.55,0.20,0.85,1},
        {w,h, 1,1, 0.85,0.30,0.65,1},
        {0,h, 0,1, 0.80,0.25,0.70,1},
    }, "fan", "static")
end

local function place()
    local w, h = love.graphics.getDimensions()
    btn.x = w/2 - btn.w/2
    btn.y = h/2 + 20
    btnOnline.x = w/2 - btnOnline.w/2
    btnOnline.y = btn.y + btn.h + 15
    btnOffline.x = w/2 - btnOffline.w/2
    btnOffline.y = btnOnline.y + btnOnline.h + 15
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
    place()
    
    -- Сброс состояния игры при загрузке лобби
    local game = require("game")
    if game and game.reset_online then
        game.reset_online()
    end
end

function lobby.resize()
    grad = nil
    place()
end

function lobby.update(dt) end

function lobby.draw()
    local w, h = love.graphics.getDimensions()

    if not grad or w ~= lastW or h ~= lastH then
        grad = mkGrad(w, h)
        lastW, lastH = w, h
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad, 0, 0)

    drawSpacedText("Cubic Battle", 0, h/2 - 180, w, "center", fontTitle, fontTitle:getWidth("A")*0.05)
    drawSpacedText("Touch & Dodge", 0, h/2 - 90, w, "center", fontSub, fontSub:getWidth("A")*0.05)

    -- Кнопка Play Online
    love.graphics.setColor(0,0,0,0.20)
    love.graphics.rectangle("fill", btnOnline.x+5, btnOnline.y+6, btnOnline.w, btnOnline.h, 16, 16)

    love.graphics.setColor(0.2, 0.7, 0.3, 1)
    love.graphics.rectangle("fill", btnOnline.x, btnOnline.y, btnOnline.w, btnOnline.h, 16, 16)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3.4)
    love.graphics.rectangle("line", btnOnline.x, btnOnline.y, btnOnline.w, btnOnline.h, 16, 16)

    drawSpacedText("Play Online", btnOnline.x, btnOnline.y + 14, btnOnline.w, "center", fontBtn, fontBtn:getWidth("A")*0.05)

    -- Кнопка Play Offline
    love.graphics.setColor(0,0,0,0.20)
    love.graphics.rectangle("fill", btnOffline.x+5, btnOffline.y+6, btnOffline.w, btnOffline.h, 16, 16)

    love.graphics.setColor(0.55, 0.20, 0.85, 1)
    love.graphics.rectangle("fill", btnOffline.x, btnOffline.y, btnOffline.w, btnOffline.h, 16, 16)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3.4)
    love.graphics.rectangle("line", btnOffline.x, btnOffline.y, btnOffline.w, btnOffline.h, 16, 16)

    drawSpacedText("Play Offline", btnOffline.x, btnOffline.y + 14, btnOffline.w, "center", fontBtn, fontBtn:getWidth("A")*0.05)

    -- Информация о статусе
    local game = require("game")
    if game and game.get_online_status then
        local status, connected = game.get_online_status()
        if connected then
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.setFont(fontSub)
            love.graphics.printf("● Online", 0, btnOffline.y + btnOffline.h + 20, w, "center")
        else
            love.graphics.setColor(1, 0.3, 0.3, 1)
            love.graphics.setFont(fontSub)
            love.graphics.printf("● Offline", 0, btnOffline.y + btnOffline.h + 20, w, "center")
        end
        love.graphics.setColor(1,1,1,1)
    end
end

function lobby.touchpressed(id, x, y)
    local game = require("game")
    
    -- Кнопка Play Online
    if x>=btnOnline.x and x<=btnOnline.x+btnOnline.w and 
       y>=btnOnline.y and y<=btnOnline.y+btnOnline.h then
        if game and game.set_online_mode then
            game.set_online_mode(true)
        end
        GameState.current = "game"
    end
    
    -- Кнопка Play Offline
    if x>=btnOffline.x and x<=btnOffline.x+btnOffline.w and 
       y>=btnOffline.y and y<=btnOffline.y+btnOffline.h then
        if game and game.set_online_mode then
            game.set_online_mode(false)
        end
        GameState.current = "game"
    end
end

function lobby.touchmoved() end
function lobby.touchreleased() end

return lobby
