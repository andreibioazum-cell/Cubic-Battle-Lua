local ctrl = {}

local stick = {
    id = nil,
    bx = 0, by = 0,
    x = 0, y = 0,
    R = 60, r = 26
}

local atk = {
    x = 0, y = 0, R = 60,
    pressed = false,
    id = nil,
    dx = 0, dy = -1,
    len = 200
}

local back = { x = 20, y = 20, w = 100, h = 44 }

ctrl.bullets = {}
local BSPD = 800
local BLIFE = 2.5

local font

function ctrl.load()
    local w, h = love.graphics.getDimensions()
    stick.bx, stick.by = 90, h - 90
    stick.x, stick.y = stick.bx, stick.by
    atk.x, atk.y = w - 100, h - 100
    ctrl.bullets = {}
    font = font or love.graphics.newFont(16)
end

function ctrl.reposition()
    local w, h = love.graphics.getDimensions()
    stick.bx, stick.by = 90, h - 90
    if not stick.id then stick.x, stick.y = stick.bx, stick.by end
    atk.x, atk.y = w - 100, h - 100
end

function ctrl.update(dt, pdx, pdy)
    if atk.pressed then
        atk.dx, atk.dy = pdx, pdy
    end

    for i = #ctrl.bullets, 1, -1 do
        local b = ctrl.bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(ctrl.bullets, i)
        end
    end
end

function ctrl.drawWorld(px, py)
    if atk.pressed then
        love.graphics.setColor(0.6, 0.2, 0.8, 0.8)
        love.graphics.setLineWidth(4)
        local tx = px + atk.dx * atk.len
        local ty = py + atk.dy * atk.len
        love.graphics.line(px, py, tx, ty)
        love.graphics.setColor(0.6, 0.2, 0.8, 1)
        love.graphics.circle("fill", tx, ty, 8)
    end

    for _, b in ipairs(ctrl.bullets) do
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.circle("fill", b.x, b.y, 6)
        love.graphics.setColor(1, 0.6, 0.1, 0.5)
        love.graphics.circle("fill", b.x, b.y, 10)
    end
end

function ctrl.drawUI()
    love.graphics.setFont(font)

    love.graphics.setColor(0.5, 0.15, 0.7, 0.9)
    love.graphics.rectangle("fill", back.x, back.y, back.w, back.h, 10, 10)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", back.x, back.y, back.w, back.h, 10, 10)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print("Back", back.x + 31, back.y + 13)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Back", back.x + 30, back.y + 12)

    local col = atk.pressed and {0.7, 0.2, 0.9} or {0.5, 0.15, 0.7}
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", atk.x + 3, atk.y + 3, atk.R)
    love.graphics.setColor(col)
    love.graphics.circle("fill", atk.x, atk.y, atk.R)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", atk.x, atk.y, atk.R)

    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print("FIRE", atk.x - 21, atk.y - 9)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("FIRE", atk.x - 22, atk.y - 10)
    love.graphics.setFont(font)

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", stick.bx, stick.by, stick.R)
    love.graphics.setColor(0.5, 0.15, 0.7, 0.9)
    love.graphics.circle("fill", stick.bx, stick.by, stick.R)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", stick.bx, stick.by, stick.R)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", stick.x, stick.y, stick.r)
end

function ctrl.getMoveDir()
    return (stick.x - stick.bx) / stick.R,
           (stick.y - stick.by) / stick.R
end

function ctrl.touchpressed(id, x, y, pdx, pdy)
    if x >= back.x and x <= back.x + back.w and y >= back.y and y <= back.y + back.h then
        return "back"
    end

    local dx = x - atk.x
    local dy = y - atk.y
    if dx * dx + dy * dy <= atk.R * atk.R then
        atk.pressed = true
        atk.id = id
        atk.dx, atk.dy = pdx, pdy
        return nil
    end

    local jx = x - stick.bx
    local jy = y - stick.by
    if jx * jx + jy * jy < (stick.R * 1.6) ^ 2 and not stick.id then
        stick.id = id
        ctrl.touchmoved(id, x, y)
    end

    return nil
end

function ctrl.touchmoved(id, x, y)
    if id ~= stick.id then return end

    local dx = x - stick.bx
    local dy = y - stick.by
    local d = math.sqrt(dx * dx + dy * dy)

    if d > stick.R then
        local a = math.atan2(dy, dx)
        stick.x = stick.bx + math.cos(a) * stick.R
        stick.y = stick.by + math.sin(a) * stick.R
    else
        stick.x, stick.y = x, y
    end
end

function ctrl.touchreleased(id, px, py)
    if atk.pressed and id == atk.id then
        atk.pressed = false
        atk.id = nil
        table.insert(ctrl.bullets, {
            x = px, y = py,
            vx = atk.dx * BSPD,
            vy = atk.dy * BSPD,
            life = BLIFE
        })
        return
    end

    if id == stick.id then
        stick.id = nil
        stick.x, stick.y = stick.bx, stick.by
    end
end

return ctrl
