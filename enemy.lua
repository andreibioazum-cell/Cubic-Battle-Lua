local enemy = {}

local SIGHT = 400
local LOSE = 700
local ATK_RANGE = 70
local SPEED = 110
local SIZE = 50
local MAX_HP = 3
local DAMAGE = 10
local ATK_CD = 1.0
local SPAWN_DIST = 600
local RESPAWN_DELAY = 3

local e = nil
local respawnTimer = 0

local function spawn(px, py)
    local angle = math.random() * math.pi * 2
    e = {
        x = px + math.cos(angle) * SPAWN_DIST,
        y = py + math.sin(angle) * SPAWN_DIST,
        hp = MAX_HP,
        state = "idle",
        stateTimer = 0,
        flashTimer = 0
    }
end

function enemy.load()
    e = nil
    respawnTimer = 0
end

function enemy.update(dt, px, py, bullets, onPlayerHit)
    if not e then
        respawnTimer = respawnTimer + dt
        if respawnTimer >= RESPAWN_DELAY then
            respawnTimer = 0
            spawn(px, py)
        end
        return
    end

    if e.flashTimer > 0 then e.flashTimer = e.flashTimer - dt end

    local dx = px - e.x
    local dy = py - e.y
    local dist = math.sqrt(dx*dx + dy*dy)
    e.stateTimer = e.stateTimer + dt

    if e.state == "dying" then
        if e.stateTimer > 0.3 then
            e = nil
            respawnTimer = 0
        end

    elseif e.state == "idle" then
        if dist < SIGHT then
            e.state = "chase"
            e.stateTimer = 0
        end

    elseif e.state == "chase" then
        if dist > LOSE then
            e.state = "idle"
            e.stateTimer = 0
        elseif dist < ATK_RANGE then
            e.state = "attack"
            e.stateTimer = 0
        else
            local nx, ny = dx / dist, dy / dist
            e.x = e.x + nx * SPEED * dt
            e.y = e.y + ny * SPEED * dt
        end

    elseif e.state == "attack" then
        if onPlayerHit then onPlayerHit(DAMAGE) end
        e.state = "cooldown"
        e.stateTimer = 0

    elseif e.state == "cooldown" then
        if e.stateTimer >= ATK_CD then
            if dist < ATK_RANGE then
                e.state = "attack"
            else
                e.state = "chase"
            end
            e.stateTimer = 0
        end
    end

    if e.state ~= "dying" then
        for j = #bullets, 1, -1 do
            local b = bullets[j]
            local bdx = b.x - e.x
            local bdy = b.y - e.y
            if bdx*bdx + bdy*bdy < (SIZE/2 + 8)^2 then
                e.hp = e.hp - 1
                e.flashTimer = 0.1
                table.remove(bullets, j)
                if e.hp <= 0 then
                    e.state = "dying"
                    e.stateTimer = 0
                end
                break
            end
        end
    end
end

function enemy.draw()
    if not e then return end

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", e.x - SIZE/2 + 3, e.y - SIZE/2 + 4, SIZE, SIZE, 8, 8)

    if e.state == "dying" then
        local a = 1 - e.stateTimer / 0.3
        love.graphics.setColor(0.5, 0.5, 0.5, a)
    elseif e.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    elseif e.state == "attack" or e.state == "cooldown" then
        love.graphics.setColor(0.9, 0.2, 0.2)
    elseif e.state == "chase" then
        love.graphics.setColor(0.7, 0.3, 0.3)
    else
        love.graphics.setColor(0.4, 0.3, 0.5)
    end
    love.graphics.rectangle("fill", e.x - SIZE/2, e.y - SIZE/2, SIZE, SIZE, 8, 8)

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", e.x - SIZE/2, e.y - SIZE/2, SIZE, SIZE, 8, 8)

    if e.hp < MAX_HP and e.state ~= "dying" then
        local bw, bh = SIZE, 5
        local bx = e.x - bw/2
        local by = e.y - SIZE/2 - 12
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        love.graphics.setColor(0.2, 0.9, 0.3)
        love.graphics.rectangle("fill", bx, by, bw * (e.hp / MAX_HP), bh)
    end
end

function enemy.alive()
    return e ~= nil and e.state ~= "dying"
end

return enemy
