local c = {}

local joy = {
    id = nil,
    cx = 0, cy = 0,
    sx = 0, sy = 0,
    R = 60, sR = 26
}

local atk = {
    x = 0, y = 0, r = 70,
    pressed = false,
    id = nil,
    ax = 0, ay = -1,
    aimLen = 200
}

local back = { x = 20, y = 20, w = 100, h = 44 }

c.bullets = {}
local BSPD, BLIFE = 800, 2.5

local font

function c.load()
    local w, h = love.graphics.getDimensions()
    joy.cx, joy.cy = 90, h - 90
    joy.sx, joy.sy = joy.cx, joy.cy
    atk.x, atk.y = w - 100, h - 100
    c.bullets = {}
    font = font or love.graphics.newFont(16)
end

function c.reposition()
    local w, h = love.graphics.getDimensions()
    joy.cx, joy.cy = 90, h - 90
    if joy.id == nil then joy.sx, joy.sy = joy.cx, joy.cy end
    atk.x, atk.y = w - 100, h - 100
end

function c.update(dt, playerDirX, playerDirY)
    if atk.pressed then
        atk.ax, atk.ay = playerDirX, playerDirY
    end

    for i = #c.bullets, 1, -1 do
        local b = c.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(c.bullets, i) end
    end
end

function c.drawWorld(playerX, playerY)
    if atk.pressed then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        love.graphics.setLineWidth(3)
        local tx, ty = playerX + atk.ax * atk.aimLen, playerY + atk.ay * atk.aimLen
        love.graphics.line(playerX, playerY, tx, ty)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        love.graphics.circle("line", tx, ty, 12)
        love.graphics.line(tx-8, ty, tx+8, ty)
        love.graphics.line(tx, ty-8, tx, ty+8)
    end

    for _, b in ipairs(c.bullets) do
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.circle("fill", b.x, b.y, 6)
        love.graphics.setColor(1, 0.6, 0.1, 0.5)
        love.graphics.circle("fill", b.x, b.y, 10)
    end
end

function c.drawUI()
    love.graphics.setFont(font)

    love.graphics.setColor(0.4, 0.2, 0.5, 0.85)
    love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", back.x, back.y, back.w, back.h, 10, 10)
    love.graphics.print("Back", back.x + 30, back.y + 12)

    local col = atk.pressed and {0.9, 0.3, 0.2} or {0.7, 0.2, 0.15}
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", atk.x + 3, atk.y + 4, atk.r)
    love.graphics.setColor(col)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", atk.x, atk.y, atk.r)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Fire", atk.x - 18, atk.y - 10)

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.R)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joy.cx, joy.cy, joy.R)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sR)
end

function c.getMoveDir()
    return (joy.sx - joy.cx) / joy.R, (joy.sy - joy.cy) / joy.R
end

function c.touchpressed(id, x, y, playerDirX, playerDirY)
    if x >= back.x and x <= back.x + back.w and y >= back.y and y <= back.y + back.h then
        return "back"
    end
    local dx, dy = x - atk.x, y - atk.y
    if dx*dx + dy*dy <= atk.r * atk.r then
        atk.pressed = true
        atk.id = id
        atk.ax, atk.ay = playerDirX, playerDirY
        return nil
    end
    local jdx, jdy = x - joy.cx, y - joy.cy
    if jdx*jdx + jdy*jdy < (joy.R * 1.6)^2 and not joy.id then
        joy.id = id
        c.touchmoved(id, x, y)
    end
    return nil
end

function c.touchmoved(id, x, y)
    if id ~= joy.id then return end
    local dx, dy = x - joy.cx, y - joy.cy
    local d = math.sqrt(dx*dx + dy*dy)
    if d > joy.R then
        local a = math.atan2(dy, dx)
        joy.sx = joy.cx + math.cos(a) * joy.R
        joy.sy = joy.cy + math.sin(a) * joy.R
    else
        joy.sx, joy.sy = x, y
    end
end

function c.touchreleased(id, playerX, playerY)
    if atk.pressed and id == atk.id then
        atk.pressed = false
        atk.id = nil
        table.insert(c.bullets, {
            x = playerX, y = playerY,
            vx = atk.ax * BSPD, vy = atk.ay * BSPD,
            life = BLIFE
        })
        return
    end
    if id == joy.id then
        joy.id = nil
        joy.sx, joy.sy = joy.cx, joy.cy
    end
end

return c
