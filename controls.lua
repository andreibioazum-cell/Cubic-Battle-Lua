local controls = {}
local joy = { id = nil, cx = 90, cy = 0, sx = 90, sy = 0, r = 50, sr = 20 }
local atk = { id = nil, x = 0, y = 0, r = 55, hold = false }
local aim = { x = 0, y = -1 }
local font = nil

-- Флаг для предотвращения двойного выстрела
local shotFired = false

function controls.load()
    local success, err = pcall(function()
        font = love.graphics.newFont(20)
    end)
    if not success then
        font = love.graphics.newFont(20)
    end
    controls.resize()
    shotFired = false
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
    return aim.x, aim.y
end

function controls.isAiming() return atk.hold end

function controls.touchpressed(id, x, y)
    -- Joystick
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
        return
    end
    
    -- Attack button
    local ax, ay = x - atk.x, y - atk.y
    if ax*ax + ay*ay < atk.r*atk.r then
        atk.id = id
        atk.hold = true
        shotFired = false
        local len = math.sqrt(ax*ax + ay*ay)
        if len > 5 then
            aim.x = ax / len
            aim.y = ay / len
        else
            aim.x, aim.y = 0, -1
        end
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
    
    if id == atk.id then
        local ax, ay = x - atk.x, y - atk.y
        local len = math.sqrt(ax*ax + ay*ay)
        if len > 5 then
            aim.x = ax / len
            aim.y = ay / len
        end
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
        
        -- СТРЕЛЬБА ТОЛЬКО ЕСЛИ НЕ БЫЛО ВЫСТРЕЛА
        if not shotFired then
            shot = true
            dx, dy = aim.x, aim.y
            if dx == 0 and dy == 0 then
                dy = -1
            end
            shotFired = true
        end
    end
    
    return shot, dx, dy
end

function controls.draw()
    if not font then
        controls.load()
    end
    
    -- Joystick
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)
    
    -- Attack button
    love.graphics.setColor(0.5, 0, 1, 0.6)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    
    -- Aim line
    if atk.hold then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(3)
        local len = 35
        love.graphics.line(
            atk.x, atk.y,
            atk.x + aim.x * len,
            atk.y + aim.y * len
        )
        love.graphics.circle("fill", atk.x + aim.x * len, atk.y + aim.y * len, 4)
    end
    
    -- Button text
    love.graphics.setColor(1, 1, 1)
    if font then
        love.graphics.setFont(font)
        love.graphics.printf("SHOT", atk.x - atk.r, atk.y - 10, atk.r*2, "center")
    end
end

return controls
