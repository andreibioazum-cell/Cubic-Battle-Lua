local controls = {}

local joy  = { id=nil, cx=0, cy=0, sx=0, sy=0, r=45, sr=18 }
local atk  = { id=nil, x=0, y=0, r=48, hold=false }
local back = { x=20, y=20, w=130, h=50 }

local font
local aimDx, aimDy = 0, -1

local function place()
    local w,h = love.graphics.getDimensions()
    joy.cx = 80
    joy.cy = h - 80
    if not joy.id then
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    atk.x = w - 80
    atk.y = h - 80
end

function controls.load()
    font = love.graphics.newFont(20)
    place()
end

function controls.resize()
    place()
end

function controls.getMove()
    if not joy.id then return 0, 0 end
    local dx = joy.sx - joy.cx
    local dy = joy.sy - joy.cy
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return 0, 0 end
    aimDx, aimDy = dx/len, dy/len
    return aimDx, aimDy
end

function controls.isAiming()
    return atk.hold
end

function controls.getAim()
    return aimDx, aimDy
end

function controls.touchpressed(id,x,y)

    if x>=back.x and x<=back.x+back.w and
       y>=back.y and y<=back.y+back.h then
        GameState.current = "lobby"
        return
    end

    local dx = x-joy.cx
    local dy = y-joy.cy
    if dx*dx+dy*dy <= joy.r*joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
        return
    end

    local ax = x-atk.x
    local ay = y-atk.y
    if ax*ax+ay*ay <= atk.r*atk.r then
        atk.id = id
        atk.hold = true
    end
end

function controls.touchmoved(id,x,y)
    if joy.id == id then
        local dx = x-joy.cx
        local dy = y-joy.cy
        local len = math.sqrt(dx*dx+dy*dy)
        if len > joy.r then
            dx = dx/len * joy.r
            dy = dy/len * joy.r
        end
        joy.sx = joy.cx + dx
        joy.sy = joy.cy + dy
    end
end

function controls.touchreleased(id)
    if joy.id == id then
        joy.id = nil
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    if atk.id == id then
        atk.id = nil
        atk.hold = false
        return true, aimDx, aimDy
    end
end

function controls.draw()
    love.graphics.setLineWidth(2)

    love.graphics.setColor(0,0,0,0.35)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(0,0,0,1)
    love.graphics.circle("line", joy.cx, joy.cy, joy.r)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)

    love.graphics.setColor(0.8, 0.1, 0.1, 0.9)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    love.graphics.setColor(0,0,0,1)
    love.graphics.circle("line", atk.x, atk.y, atk.r)

    love.graphics.setFont(font)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Shot", atk.x-atk.r, atk.y-10, atk.r*2, "center")

    love.graphics.setColor(0.9,0.9,0.95,1)
    love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 12, 12)
    love.graphics.setColor(0.3,0.2,0.6,1)
    love.graphics.printf("Back", back.x, back.y+12, back.w, "center")

    love.graphics.setColor(1,1,1,1)
end

return controls
