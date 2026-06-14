local j = {}
local id, cx, cy, sx, sy = nil, 0, 0, 0, 0
local R, sR = 60, 26

function j.load(x, y) cx, cy, sx, sy = x, y, x, y end

function j.draw()
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.circle("fill", cx, cy, R)
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", cx, cy, R)
    love.graphics.setColor(0,0,0,1)
    love.graphics.circle("fill", sx, sy, sR)
end

function j.touchpressed(tid, x, y)
    local dx, dy = x-cx, y-cy
    if dx*dx + dy*dy < (R*1.6)^2 and not id then
        id = tid
        j.touchmoved(tid, x, y)
    end
end

function j.touchmoved(tid, x, y)
    if tid ~= id then return end
    local dx, dy = x-cx, y-cy
    local d = math.sqrt(dx*dx + dy*dy)
    if d > R then
        local a = math.atan2(dy, dx)
        sx, sy = cx + math.cos(a)*R, cy + math.sin(a)*R
    else
        sx, sy = x, y
    end
end

function j.touchreleased(tid)
    if tid == id then id = nil; sx, sy = cx, cy end
end

function j.dir() return (sx-cx)/R, (sy-cy)/R end

return j
