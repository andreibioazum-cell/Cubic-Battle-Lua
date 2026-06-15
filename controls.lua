local controls = {}

-- ========= ДЖОЙСТИК =========
local joy = {
    id = nil,
    cx = 0, cy = 0,
    sx = 0, sy = 0,
    R = 60,
    sR = 26
}

-- ========= КНОПКА BACK =========
local back = {
    x = 20,
    y = 20,
    w = 110,
    h = 50
}

local fontBtn

-- ==============================
-- LOAD
-- ==============================
function controls.load()
    local w, h = love.graphics.getDimensions()

    joy.cx = 180
    joy.cy = h - 180
    joy.sx = joy.cx
    joy.sy = joy.cy

    fontBtn = love.graphics.newFont(18)
end

-- ==============================
-- RESIZE
-- ==============================
function controls.resize(w, h)
    joy.cx = 180
    joy.cy = h - 180
    if not joy.id then
        joy.sx = joy.cx
        joy.sy = joy.cy
    end
end

-- ==============================
-- НАПРАВЛЕНИЕ
-- ==============================
function controls.getDirection()
    if joy.id then
        local dx = joy.sx - joy.cx
        local dy = joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then
            return dx / len, dy / len
        end
    end
    return 0, 0
end

-- ==============================
-- TOUCH
-- ==============================
function controls.touchpressed(id, x, y)

    -- BACK кнопка
    if x >= back.x and x <= back.x + back.w and
       y >= back.y and y <= back.y + back.h then
        GameState.current = "lobby"
        return
    end

    -- Джойстик
    local dx = x - joy.cx
    local dy = y - joy.cy
    if dx*dx + dy*dy <= joy.R * joy.R then
        joy.id = id
        joy.sx = x
        joy.sy = y
    end
end

function controls.touchmoved(id, x, y)
    if joy.id == id then
        local dx = x - joy.cx
        local dy = y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > joy.R then
            dx = dx / len * joy.R
            dy = dy / len * joy.R
        end
        joy.sx = joy.cx + dx
        joy.sy = joy.cy + dy
    end
end

function controls.touchreleased(id)
    if joy.id == id then
        joy.id = nil
        joy.sx = joy.cx
        joy.sy = joy.cy
    end
end

-- ==============================
-- DRAW
-- ==============================
function controls.draw()

    -- Джойстик база
    love.graphics.setColor(1,1,1,0.15)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.R)

    -- Джойстик стик
    love.graphics.setColor(1,1,1,0.35)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sR)

    -- BACK кнопка
    love.graphics.setColor(0.4, 0.2, 0.5, 0.8)
    love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 10, 10)

    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", back.x, back.y, back.w, back.h, 10, 10)

    love.graphics.setFont(fontBtn)
    love.graphics.print("BACK", back.x + 25, back.y + 13)
end

return controls
