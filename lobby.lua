local lobby = {}

local btn = { w=220, h=75, x=0, y=0 }
local grad, lastW, lastH = nil, 0, 0
local fontTitle, fontSub, fontBtn

local function mkGrad(w, h)
    return love.graphics.newMesh({
        {0,0, 0,0, 0.55,0.20,0.85,1},
        {w,0, 1,0, 0.95,0.35,0.75,1},
        {w,h, 1,1, 0.25,0.05,0.40,1},
        {0,h, 0,1, 0.35,0.10,0.55,1},
    }, "fan", "static")
end

local function place()
    local w, h = love.graphics.getDimensions()
    btn.x = w/2 - btn.w/2
    btn.y = h/2 + 50
end

local function drawOutlineText(text, x, y, w, align, font, scale)
    scale = scale or 1
    love.graphics.setFont(font)

    love.graphics.setColor(0,0,0,1)
    local o = 2 * scale
    for dx=-o,o,o do
        for dy=-o,o,o do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x+dx, y+dy, w, align)
            end
        end
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(text, x, y, w, align)
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

    drawOutlineText("Cubic Battle", 0, h/2 - 140, w, "center", fontTitle)
    drawOutlineText("Touch & Dodge", 0, h/2 - 60, w, "center", fontSub)

    love.graphics.setColor(0,0,0,0.35)
    love.graphics.rectangle("fill", btn.x+5, btn.y+6, btn.w, btn.h, 16, 16)

    love.graphics.setColor(0.55, 0.20, 0.85, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 16, 16)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 16, 16)

    drawOutlineText("Play", btn.x, btn.y + 20, btn.w, "center", fontBtn)
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
