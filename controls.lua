local controls = {}

local joy  = { id = nil, cx = 100, cy = 0, sx = 100, sy = 0, r = 70, sr = 30 }
local atk  = { id = nil, x = 0, y = 0, r = 70, hold = false, press = 0 }
local font

local function place()
    local w, h = love.graphics.getDimensions()
    joy.cy = h - 120
    joy.sx, joy.sy = joy.cx, joy.cy
    atk.x, atk.y = w - 120, h - 120
end

function controls.load()
    font = love.graphics.newFont("Fredoka-Bold.ttf", 22)
    place()
end

function controls.update(dt)
    local target = atk.hold and 1 or 0
    atk.press = atk.press + (target - atk.press) * math.min(dt * 12, 1)
end

function controls.getMove()
    local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 5 then return 0, 0 end
    return dx/len, dy/len
end

function controls.touchpressed(id, x, y)
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy <= joy.r*joy.r * 2 then joy.id = id end

    local ax, ay = x - atk.x, y - atk.y
    if ax*ax + ay*ay <= atk.r*atk.r * 2 then atk.id = id; atk.hold = true end
end

function controls.touchmoved(id, x, y)
    if joy.id == id then
        local dx, dy = x - joy.cx, y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > joy.r then
            dx, dy = (dx/len)*joy.r, (dy/len)*joy.r
        end
        joy.sx, joy.sy = joy.cx + dx, joy.cy + dy
    end
end

function controls.touchreleased(id)
    if joy.id == id then joy.id = nil; joy.sx, joy.sy = joy.cx, joy.cy end
    if atk.id == id then
        atk.id = nil; atk.hold = false
        local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len < 10 then return true, 0, -1 end
        return true, dx/len, dy/len
    end
    return false
end

function controls.draw()
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)

    local s = 1 - atk.press * 0.1
    love.graphics.setColor(0.45, 0.15, 0.75, 0.6)
    love.graphics.circle("fill", atk.x, atk.y, atk.r * s)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(font)
    love.graphics.printf("SHOT", atk.x - 50, atk.y - 12, 100, "center")
end

function controls.resize() place() end

return controls
