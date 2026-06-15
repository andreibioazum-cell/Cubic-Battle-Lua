local controls = {}

local joy = { id=nil, cx=0, cy=0, sx=0, sy=0, R=55, sR=22 }
local atk = { id=nil, x=0, y=0, r=55, holding=false, dx=0, dy=-1 }
local back = { x=0, y=0, w=180, h=65 }

local font

local function place()
    local w, h = love.graphics.getDimensions()

    joy.cx = 90
    joy.cy = h - 90
    if not joy.id then
        joy.sx = joy.cx
        joy.sy = joy.cy
    end

    atk.x = w - 90
    atk.y = h - 90

    back.x = w/2 - back.w/2
    back.y = 40
end

function controls.load()
    font = love.graphics.newFont(24)
    place()
end

function controls.resize()
    place()
end

function controls.getMove()
    if not joy.id then return 0,0 end
    local dx = joy.sx - joy.cx
    local dy = joy.sy - joy.cy
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return 0,0 end
    return dx/len, dy/len
end

function controls.getAim()
    return atk.dx, atk.dy, atk.holding
end

function controls.touchpressed(id,x,y)

    if x>=back.x and x<=back.x+back.w and
       y>=back.y and y<=back.y+back.h then
        GameState.current="lobby"
        return
    end

    local dx = x-joy.cx
    local dy = y-joy.cy
    if dx*dx+dy*dy <= joy.R*joy.R then
        joy.id=id
        joy.sx=x
        joy.sy=y
        return
    end

    local ax = x-atk.x
    local ay = y-atk.y
    if ax*ax+ay*ay <= atk.r*atk.r then
        atk.id=id
        atk.holding=true
    end
end

function controls.touchmoved(id,x,y)

    if joy.id==id then
        local dx = x-joy.cx
        local dy = y-joy.cy
        local len = math.sqrt(dx*dx+dy*dy)
        if len>joy.R then
            dx=dx/len*joy.R
            dy=dy/len*joy.R
        end
        joy.sx=joy.cx+dx
        joy.sy=joy.cy+dy
    end

    if atk.id==id then
        local dx = x-atk.x
        local dy = y-atk.y
        local len = math.sqrt(dx*dx+dy*dy)
        if len>0 then
            atk.dx=dx/len
            atk.dy=dy/len
        end
    end
end

function controls.touchreleased(id)
    if joy.id==id then
        joy.id=nil
        joy.sx=joy.cx
        joy.sy=joy.cy
    end
    if atk.id==id then
        atk.id=nil
        atk.holding=false
        return true, atk.dx, atk.dy
    end
end

function controls.draw()

    love.graphics.setColor(0,0,0,0.35)
    love.graphics.circle("fill",joy.cx,joy.cy,joy.R)

    love.graphics.setColor(0,0,0,1)
    love.graphics.circle("line",joy.cx,joy.cy,joy.R)

    love.graphics.circle("fill",joy.sx,joy.sy,joy.sR)

    love.graphics.setColor(0,0,0,0.35)
    love.graphics.circle("fill",atk.x,atk.y,atk.r)

    love.graphics.setColor(0,0,0,1)
    love.graphics.circle("line",atk.x,atk.y,atk.r)

    if atk.holding then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.setLineWidth(6)
        love.graphics.line(
            atk.x, atk.y,
            atk.x + atk.dx*120,
            atk.y + atk.dy*120
        )
    end

    love.graphics.setColor(0.55,0.2,0.85,1)
    love.graphics.rectangle("fill",back.x,back.y,back.w,back.h,12,12)

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("line",back.x,back.y,back.w,back.h,12,12)

    love.graphics.setFont(font)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("BACK",back.x,back.y+18,back.w,"center")
end

return controls
