local controls = {}

local joy = {
    id = nil,
    cx = 0, cy = 0,
    sx = 0, sy = 0,
    R = 70,
    sR = 28
}

local back = { x = 20, y = 20, w = 110, h = 50 }

local font

local function place()
    local w, h = love.graphics.getDimensions()
    joy.cx = 120
    joy.cy = h - 120
    if not joy.id then
        joy.sx = joy.cx
        joy.sy = joy.cy
    end
end

function controls.load()
    font = love.graphics.newFont(18)
    place()
end

function controls.resize()
    place()
end

function controls.getDirection()
    if not joy.id then return 0, 0 end
    local dx = joy.sx - joy.cx
    local dy = joy.sy - joy.cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return 0, 0 end
    return dx / len, dy / len
end

function controls.touchpressed(id, x, y)
    if x >= back.x and x <= back.x + back.w and
       y >= back.y and y <= back.y + back.h then
        GameState.current = "lobby"
        return
    end

    local dx = x - joy.cx
    local dy = y - joy.cy
    if dx * dx + dy * dy <= joy.R * joy.R then
        joy.id = id
        joy.sx = x
        joy.sy = y
    end
end

function controls.touchmoved(id, x, y)
    if joy.id ~= id then return end
    local dx = x - joy.cx
    local dy = y - joy.cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len > joy.R then
        dx = dx / len * joy.R
        dy = dy / len * joy.R
    end
    joy.sx = joy.cx + dx
    joy.sy = joy.cy + dy
end

function controls.touchreleased(id)
    if joy.id ~= id then return end
    joy.id = nil
    joy.sx = joy.cx
    joy.sy = joy.cy
end

function controls.draw()
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.R)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", joy.cx, joy.cy, joy.R)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sR)

    love.graphics.setColor(0.15, 0.15, 0.2, 0.85)
    love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 10, 10)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", back.x, back.y, back.w, back.h, 10, 10)

    love.graphics.setFont(font)
    love.graphics.print("BACK", back.x + 25, back.y + 13)
end

return controls
