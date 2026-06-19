local enemy = {}

local SIZE = 55
local SPEED = 140
local ATTACK_RANGE = 300
local MAX_HP = 5
local BULLET_SPEED = 260

local e
local enemyBullets = {}

function enemy.load() 
    img = love.graphics.newImage("player.png") -- используем тот же ассет
end

function enemy.reset() e = nil; enemyBullets = {} end

local function spawn(px, py)
    e = { x = px + 500, y = py + 500, hp = MAX_HP, angle = 0, shootT = 0, hit = 0 }
end

function enemy.update(dt, px, py, playerBullets, onHit)
    if not e then spawn(px, py); return end

    local dx, dy = px - e.x, py - e.y
    local dist = math.sqrt(dx*dx + dy*dy) + 0.001
    local nx, ny = dx/dist, dy/dist

    -- Логика AI
    if dist > ATTACK_RANGE then
        e.x = e.x + nx * SPEED * dt
        e.y = e.y + ny * SPEED * dt
    elseif dist < 150 then
        e.x = e.x - nx * SPEED * 0.8 * dt
        e.y = e.y - ny * SPEED * 0.8 * dt
    end
    
    e.angle = math.atan2(dy, dx) + math.pi/2
    e.hit = math.max(0, e.hit - dt * 3)

    -- Стрельба
    e.shootT = e.shootT - dt
    if e.shootT <= 0 and dist < 500 then
        table.insert(enemyBullets, { x = e.x, y = e.y, vx = nx * BULLET_SPEED, vy = ny * BULLET_SPEED, life = 3 })
        e.shootT = 1.3
    end

    -- Пули врага (ЧЁРНЫЕ)
    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(enemyBullets, i) 
        elseif math.sqrt((b.x-px)^2 + (b.y-py)^2) < 25 then
            onHit(1)
            table.remove(enemyBullets, i)
        end
    end

    -- Коллизия с пулями игрока
    for i = #playerBullets, 1, -1 do
        local b = playerBullets[i]
        if math.sqrt((b.x-e.x)^2 + (b.y-e.y)^2) < 30 then
            e.hp = e.hp - 1
            e.hit = 1
            table.remove(playerBullets, i)
            if e.hp <= 0 then e = nil; return end
        end
    end
end

function enemy.draw()
    if not e then return end
    
    -- Вражеские пули (ЧЁРНЫЕ)
    for _, b in ipairs(enemyBullets) do
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.circle("fill", b.x, b.y, 10)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end

    -- Враг
    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.angle)
    love.graphics.setColor(1, 0.2 - e.hit, 0.2 - e.hit)
    love.graphics.draw(img, -SIZE/2, -SIZE/2)
    love.graphics.pop()
end

return enemy
