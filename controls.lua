local controls = {}
local joy = { id = nil, cx = 100, cy = 0, sx = 100, sy = 0, r = 60, sr = 25 }
local atk = { id = nil, x = 0, y = 0, r = 65, hold = false, press = 0 }
local font

local function drawSpacedText(text, x, y, w, align, font)
    love.graphics.setFont(font)
    love.graphics.printf(text, x, y, w, align)
end

function controls.load()
    font = love.graphics.newFont("Fredoka-Bold.ttf", 22)
    local w, h = love.graphics.getDimensions()
    joy.cy = h - 100
    joy.sx, joy.sy = joy.cx, joy.cy
    atk.x, atk.y = w - 100, h - 100
end

function controls.update(dt)
    local t = atk.hold and 1 or 0
    atk.press = atk.press + (t - atk.press) * math.min(dt*10, 1)
end

function controls.getMove()
    local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 5 then return 0, 0 end
    return dx/len, dy/len
end

function controls.touchpressed(id, x, y)
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r*2 then joy.id = id end
    local adx, ady = x - atk.x, y - atk.y
    if adx*adx + ady*ady < atk.r*atk.r*2 then atk.id = id; atk.hold = true end
end

function controls.touchmoved(id, x, y)
    if id == joy.id then
        local dx, dy = x - joy.cx, y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > joy.r then dx, dy = (dx/len)*joy.r, (dy/len)*joy.r end
        joy.sx, joy.sy = joy.cx + dx, joy.cy + dy
    end
end

function controls.touchreleased(id)
    if id == joy.id then joy.id = nil; joy.sx, joy.sy = joy.cx, joy.cy end
    if id == atk.id then
        atk.id = nil; atk.hold = false
        local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        return true, dx/(len+0.1), dy/(len+0.1)
    end
    return false
end

function controls.draw()
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)

    local s = 1 - atk.press * 0.1
    love.graphics.setColor(0.45, 0.15, 0.75, 0.6)
    love.graphics.circle("fill", atk.x, atk.y, atk.r * s)
    love.graphics.setColor(1, 1, 1)
    drawSpacedText("SHOT", atk.x-50, atk.y-12, 100, "center", font)
end

return controls
