local enemy = require("enemy")
local lobby = {}

local btnPlay = { w=240, h=72, x=0, y=0 }
local btnRespawn = { w=240, h=72, x=0, y=0 }
local btnExit = { w=240, h=72, x=0, y=0 }
local grad, lastW, lastH = nil, 0, 0
local fontTitle, fontSub, fontBtn
local respawnEnabled = true

local function mkGrad(w, h)
    return love.graphics.newMesh({
        {0,0, 0,0, 0.08,0.03,0.15,1},
        {w,0, 1,0, 0.18,0.05,0.30,1},
        {w,h, 1,1, 0.08,0.02,0.18,1},
        {0,h, 0,1, 0.02,0.01,0.08,1},
    }, "fan", "static")
end

local function place()
    local w, h = love.graphics.getDimensions()
    btnPlay.x = w/2 - btnPlay.w/2
    btnPlay.y = h/2 + 20
    btnRespawn.x = w/2 - btnRespawn.w/2
    btnRespawn.y = btnPlay.y + btnPlay.h + 16
    btnExit.x = w/2 - btnExit.w/2
    btnExit.y = btnRespawn.y + btnRespawn.h + 16
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
    enemy.setRespawnEnabled(respawnEnabled)
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

    drawSpacedText("Cubic Battle", 0, h/2 - 170, w, "center", fontTitle, fontTitle:getWidth("A")*0.05)
    drawSpacedText("Touch & Dodge", 0, h/2 - 95, w, "center", fontSub, fontSub:getWidth("A")*0.05)

    local function drawButton(btn, color, label)
        love.graphics.setColor(0,0,0,0.28)
        love.graphics.rectangle("fill", btn.x+6, btn.y+6, btn.w, btn.h, 22, 22)
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 22, 22)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 22, 22)
        drawSpacedText(label, btn.x, btn.y + 20, btn.w, "center", fontBtn, fontBtn:getWidth("A")*0.05)
    end

    drawButton(btnPlay, {0.16, 0.06, 0.22, 1}, "Play")
    drawButton(btnRespawn, {0.12, 0.04, 0.18, 1}, respawnEnabled and "Respawn: ON" or "Respawn: OFF")
    drawButton(btnExit, {0.18, 0.04, 0.20, 1}, "Exit")
end

function lobby.touchpressed(id, x, y)
    if x>=btnPlay.x and x<=btnPlay.x+btnPlay.w and
       y>=btnPlay.y and y<=btnPlay.y+btnPlay.h then
        GameState.current = "game"
        return
    end

    if x>=btnRespawn.x and x<=btnRespawn.x+btnRespawn.w and
       y>=btnRespawn.y and y<=btnRespawn.y+btnRespawn.h then
        respawnEnabled = not respawnEnabled
        enemy.setRespawnEnabled(respawnEnabled)
        return
    end

    if x>=btnExit.x and x<=btnExit.x+btnExit.w and
       y>=btnExit.y and y<=btnExit.y+btnExit.h then
        love.event.quit()
        return
    end
end

function lobby.touchmoved() end
function lobby.touchreleased() end

return lobby
