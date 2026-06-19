local controls = {}
local joy = { id = nil, cx = 90, cy = 0, sx = 90, sy = 0, r = 50, sr = 20 }
local atk = { id = nil, x = 0, y = 0, r = 55, hold = false }
local font

function controls.load()
    font = love.graphics.newFont("Fredoka-Bold.ttf", 20)
    controls.resize()
end

function controls.resize()
    local w, h = love.graphics.getDimensions()
    joy.cy = h - 90
    joy.sy = joy.cy
    atk.x = w - 90
    atk.y = h - 90
end

function controls.update(dt) end

function controls.getMove()
    if not joy.id then return 0, 0 end
    local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return 0, 0 end
    return dx/len, dy/len
end

function controls.getAim()
    local dx, dy = controls.getMove()
    return dx, dy
end

function controls.isAiming() return atk.hold end

function controls.touchpressed(id, x, y)
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
    end
    local ax, ay = x - atk.x, y - atk.y
    if ax*ax + ay*ay < atk.r*atk.r then
        atk.id = id
        atk.hold = true
    end
end

function controls.touchmoved(id, x, y)
    if id == joy.id then
        local dx, dy = x - joy.cx, y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > joy.r then
            dx, dy = dx/len*joy.r, dy/len*joy.r
        end
        joy.sx, joy.sy = joy.cx + dx, joy.cy + dy
    end
end

function controls.touchreleased(id)
    local shot = false
    local dx, dy = 0, 0
    if id == joy.id then
        joy.id = nil
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    if id == atk.id then
        atk.id = nil
        atk.hold = false
        shot = true
        dx, dy = controls.getAim()
        if dx == 0 and dy == 0 then dy = -1 end -- Стрельба вверх по умолчанию
    end
    return shot, dx, dy
end

function controls.draw()
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)
    
    love.graphics.setColor(0.5, 0, 1, 0.6)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(font)
    love.graphics.printf("Shot", atk.x - atk.r, atk.y - 10, atk.r*2, "center")
end

return controls
