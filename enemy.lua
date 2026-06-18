local enemy = {}

local SIZE = 55
local SPEED = 140
local SIGHT = 650
local ATTACK_RANGE = 300
local KEEP_DIST = 120
local MAX_HP = 5
local RESPAWN = 2
local ATTACK_CD = 1.2
local DAMAGE = 1
local BULLET_SPEED = 250
local BULLET_SIZE = 8

local e
local timer = 0
local img
local enemyBullets = {}

local function tryShoot(dt, dx, dy)
    e.shootT = e.shootT - dt
    if e.shootT <= 0 then
        e.shootT = e.shootCooldown
        
        local spread = 0.08
        local angle = math.atan2(dy, dx) + (math.random() - 0.5) * spread * 2
        
        local speed = BULLET_SPEED + math.random() * 30 - 15
        table.insert(enemyBullets, {
            x = e.x + math.cos(angle) * SIZE * 0.6,
            y = e.y + math.sin(angle) * SIZE * 0.6,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 4,
            size = BULLET_SIZE
        })
    end
end

local function spawn(px, py)
    local w, h = love.graphics.getDimensions()
    local minR = math.min(w, h) * 0.30
    local maxR = math.min(w, h) * 0.45
    local a = math.random() * math.pi * 2
    local dist = minR + math.random() * (maxR - minR)
    
    local spawnX = math.max(SIZE, math.min(w - SIZE, px + math.cos(a) * dist))
    local spawnY = math.max(SIZE, math.min(h - SIZE, py + math.sin(a) * dist))
    
    e = {
        x = spawnX,
        y = spawnY,
        hp = MAX_HP,
        hit = 0,
        angle = 0,
        state = "wander",
        wanderT = 0,
        wanderDX = 0,
        wanderDY = 0,
        atkT = 0,
        shootT = 0,
        shootCooldown = ATTACK_CD
    }
    enemyBullets = {}
end

function enemy.load()
    img = love.graphics.newImage("player.png")
    img:setFilter("nearest","nearest")
end

function enemy.reset()
    e = nil
    timer = 0
    enemyBullets = {}
end

function enemy.spawnNow(px, py)
    spawn(px, py)
end

function enemy.get()
    return e
end

function enemy.getBullets()
    return enemyBullets
end

function enemy.update(dt, px, py, bullets, onHitPlayer)
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
    local dist = math.sqrt(dx*dx + dy*dy) + 0.0001
    local nx, ny = dx/dist, dy/dist

    if dist > SIGHT then
        e.state = "wander"
    elseif dist > ATTACK_RANGE then
        e.state = "chase"
    elseif dist < KEEP_DIST * 0.7 then
        e.state = "retreat"
        tryShoot(dt, dx, dy)
    else
        e.state = "attack"
    end

    if e.state == "chase" then
        e.x = e.x + nx * SPEED * dt
        e.y = e.y + ny * SPEED * dt
    elseif e.state == "retreat" then
        e.x = e.x - nx * SPEED * 0.6 * dt
        e.y = e.y - ny * SPEED * 0.6 * dt
    elseif e.state == "attack" then
        if dist < KEEP_DIST then
            e.x = e.x - nx * SPEED * 0.3 * dt
            e.y = e.y - ny * SPEED * 0.3 * dt
        end
        tryShoot(dt, dx, dy)
    elseif e.state == "wander" then
        e.wanderT = e.wanderT - dt
        if e.wanderT <= 0 then
            e.wanderT = 1 + math.random() * 2
            local a = math.random() * math.pi * 2
            e.wanderDX = math.cos(a)
            e.wanderDY = math.sin(a)
        end
        e.x = e.x + e.wanderDX * SPEED * 0.35 * dt
        e.y = e.y + e.wanderDY * SPEED * 0.35 * dt
    end

    e.angle = math.atan2(dy, dx) + math.pi/2
    e.hit = math.max(0, e.hit - dt*3)

    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        
        if b.life <= 0 then
            table.remove(enemyBullets, i)
        else
            local ex = b.x - px
            local ey = b.y - py
            if ex*ex + ey*ey <= (SIZE * 0.5)^2 then
                table.remove(enemyBullets, i)
                if onHitPlayer then onHitPlayer(DAMAGE) end
            end
        end
    end

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        local bx = b.x - e.x
        local by = b.y - e.y
        if bx*bx + by*by <= (SIZE*0.55)^2 then
            e.hp = e.hp - 1
            e.hit = 1
            table.remove(bullets, i)
            if e.hp <= 0 then
                e = nil
                enemyBullets = {}
                return
            end
        end
    end
end

function enemy.draw()
    if not e then return end

    love.graphics.setColor(0,0,0,0.4)
    love.graphics.push()
    love.graphics.translate(e.x + 6, e.y + 8)
    love.graphics.rotate(e.angle)
    love.graphics.draw(img, -SIZE/2, -SIZE/2)
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.angle)
    local t = e.hit
    love.graphics.setColor(1, 1 - t*0.5, 1 - t*0.5, 1)
    love.graphics.draw(img, -SIZE/2, -SIZE/2)
    love.graphics.pop()

    love.graphics.setColor(1,1,1,1)
end

return enemy
