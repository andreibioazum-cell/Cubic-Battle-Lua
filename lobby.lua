local lobby = {}

local btn = {w=180, h=65, x=0, y=0}
local t = 0
local grad, lastW, lastH = nil, 0, 0
local fontTitle, fontSub, fontBtn

local function mkGrad(w, h)
    return love.graphics.newMesh({
        {0,0, 0,0, 0.55,0.20,0.85,1},
        {w,0, 1,0, 0.85,0.25,0.65,1},
        {w,h, 1,1, 0.10,0.02,0.25,},
        {0,h, 0,1, 0.18,0.05,0.35,1},
    }, "fan", "static")
end

local function recalc()
    local w, h = love.graphics.getDimensions()
    btn.x = w/2 - btn.w/2
    btn.y = h/2 + 40
end

function lobby.load()
    fontTitle = love.graphics.newFont(48)
    fontSub = love.graphics.newFont(18)
    fontBtn = love.graphics.newFont(24)
    recalc()
end

function lobby.resize() grad = nil; recalc() end

function lobby.update(dt) t = t + dt end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    if not grad or w ~= lastW or h ~= lastH then
        grad = mkGrad(w, h); lastW, lastH = w, h; recalc()
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad, 0, 0)

    -- Заголовок
    love.graphics.setFont(fontTitle)
    local title = "Cubic Battle"
    local tw = fontTitle:getWidth(title)
    local oy = math.sin(t * 1.2) * 3
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.print(title, w/2 - tw/2 + 3, h/4 + oy + 3)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(title, w/2 - tw/2, h/4 + oy)

    -- Подзаголовок
    love.graphics.setFont(fontSub)
    love.graphics.setColor(1,1,1,0.6)
    local sub = "Touch & dodge"
    love.graphics.print(sub, w/2 - fontSub:getWidth(sub)/2, h/4 + 70)

    -- Кнопка
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.rectangle("fill", btn.x+3, btn.y+4, btn.w, btn.h, 14, 14)
    love.graphics.setColor(1,1,1,0.95)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 14, 14)
    love.graphics.setColor(0.3, 0.1, 0.5, 1)
    love.graphics.setFont(fontBtn)
    local bt = "Play"
    love.graphics.print(bt,
        btn.x + btn.w/2 - fontBtn:getWidth(bt)/2,
        btn.y + btn.h/2 - fontBtn:getHeight()/2)
end

function lobby.touchpressed(id, x, y)
    if x >= btn.x and x <= btn.x+btn.w and y >= btn.y and y <= btn.y+btn.h then
        GameState.current = "game"
    end
end

return lobby
