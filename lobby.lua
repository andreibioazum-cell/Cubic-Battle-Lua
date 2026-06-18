local lobby = {}

local btn = { w=220, h=75, x=0, y=0 }
local btnServer = { w=220, h=55, x=0, y=0 }
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
    btn.y = h/2 + 50
    btnServer.x = w/2 - btnServer.w/2
    btnServer.y = btn.y + btn.h + 20
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

    drawSpacedText("Cubic Battle", 0, h/2 - 150, w, "center", fontTitle, fontTitle:getWidth("A")*0.05)
    drawSpacedText("Touch & Dodge", 0, h/2 - 60, w, "center", fontSub, fontSub:getWidth("A")*0.05)
    
    -- Информация о сервере
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.setFont(fontSub)
    love.graphics.printf("Press F1 to start server", 0, h/2 - 30, w, "center")

    -- Кнопка Play
    love.graphics.setColor(0,0,0,0.20)
    love.graphics.rectangle("fill", btn.x+5, btn.y+6, btn.w, btn.h, 16, 16)

    love.graphics.setColor(0.55, 0.20, 0.85, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 16, 16)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3.4)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 16, 16)

    drawSpacedText("Play", btn.x, btn.y + 20, btn.w, "center", fontBtn, fontBtn:getWidth("A")*0.05)
    
    -- Кнопка Start Server
    love.graphics.setColor(0,0,0,0.20)
    love.graphics.rectangle("fill", btnServer.x+5, btnServer.y+6, btnServer.w, btnServer.h, 16, 16)

    love.graphics.setColor(0.2, 0.7, 0.3, 1)
    love.graphics.rectangle("fill", btnServer.x, btnServer.y, btnServer.w, btnServer.h, 16, 16)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3.4)
    love.graphics.rectangle("line", btnServer.x, btnServer.y, btnServer.w, btnServer.h, 16, 16)

    drawSpacedText("Start Server", btnServer.x, btnServer.y + 12, btnServer.w, "center", fontSub, fontSub:getWidth("A")*0.05)
end

function lobby.touchpressed(id, x, y)
    -- Кнопка Play
    if x>=btn.x and x<=btn.x+btn.w and y>=btn.y and y<=btn.y+btn.h then
        GameState.current = "game"
    end
    
    -- Кнопка Start Server
    if x>=btnServer.x and x<=btnServer.x+btnServer.w and 
       y>=btnServer.y and y<=btnServer.y+btnServer.h then
        local main = require("main")
        if main and main.startServer then
            main.startServer()
            print("Server started from lobby!")
        end
    end
end

function lobby.touchmoved() end
function lobby.touchreleased() end

return lobby
