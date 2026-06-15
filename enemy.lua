local enemy = {}

local SIZE = 50
local SPEED = 130
local SIGHT = 500
local ATTACK_RANGE = 60
local MAX_HP = 3
local RESPAWN = 2
local SPAWN_DIST = 700

local e
local timer = 0

local function spawn(px, py)
    local a = math.random() * math.pi * 2
    e = {
        x = px + math.cos(a) * SPAWN_DIST,
        y = py + math.sin(a) * SPAWN_DIST,
        hp = MAX_HP,
        hit = 0,
        angle = 0
    }
end

function enemy.reset()
    e = nil
    timer = 0
end

function enemy.update(dt, px, py, bullets)
    if not e then
        timer = timer + dt
        if timer >= RESPAWN then
            timer = 0
            spawn(px, py)
        end
        return
    end

    local dx = px - e.x
    local dy = py - e.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < SIGHT and dist > ATTACK_RANGE then
        e.x = e.x + dx/dist * SPEED * dt
        e.y = e.y + dy/dist * SPEED * dt
    end

    if dist > 0 then
        e.angle = math.atan2(dy, dx)
    end

    e.hit = math.max(0, e.hit - dt*3)

    for i=#bullets,1,-1 do
        local b = bullets[i]
        local bx = b.x - e.x
        local by = b.y - e.y
        if bx*bx + by*by <= (SIZE*0.6)^2 then
            e.hp = e.hp - 1
            e.hit = 1
            table.remove(bullets, i)
            if e.hp <= 0 then
                e = nil
                return
            end
        end
    end
end

function enemy.draw()
    if not e then return end

    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.angle)

    local r = 0.15 + e.hit*0.85
    local g = 0.15
    local b = 0.15

    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", -SIZE/2, -SIZE/2, SIZE, SIZE, 8, 8)

    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", -SIZE/2, -SIZE/2, SIZE, SIZE, 8, 8)

    love.graphics.pop()
end

return enemy
