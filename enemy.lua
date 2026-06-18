local enemy = {}

local SIZE = 55
local SPEED = 140
local SIGHT = 650
local ATTACK_RANGE = 300  -- увеличено, чтобы враг стрелял с расстояния
local KEEP_DIST = 120      -- дистанция, на которой враг стоит и стреляет
local MAX_HP = 5
local RESPAWN = 2
local ATTACK_CD = 1.2      -- задержка между выстрелами
local DAMAGE = 1
local BULLET_SPEED = 250   -- скорость пуль врага
local BULLET_SIZE = 10

local e
local timer = 0
local img
local enemyBullets = {}    -- пули врага

local function spawn(px, py)
    local w, h = love.graphics.getDimensions()
    local minR = math.min(w, h) * 0.30
    local maxR = math.min(w, h) * 0.45
    local a = math.random() * math.pi * 2
    local dist = minR + math.random() * (maxR - minR)
    e = {
        x = px + math.cos(a) * dist,
        y = py + math.sin(a) * dist,
        hp = MAX_HP,
        hit = 0,
        angle = 0,
        state = "wander",
        wanderT = 0,
        wanderDX = 0,
        wanderDY = 0,
        atkT = 0,
        shootT = 0,          -- таймер до следующего выстрела
        shootCooldown = 1.2  -- задержка между выстрелами
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

function enemy.get()
    return e, SIZE, MAX_HP
end

-- получаем пули врага для отрисовки в game.lua
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

    -- AI логика с учётом стрельбы
    if dist < SIGHT then
        if dist > ATTACK_RANGE then
            e.state = "chase"
        elseif dist < KEEP_DIST then
            e.state = "retreat"
        else
            e.state = "attack"
        end
    else
        e.state = "wander"
    end

    -- Движение
    if e.state == "chase" then
        e.x = e.x + nx * SPEED * dt
        e.y = e.y + ny * SPEED * dt
    elseif e.state == "retreat" then
        e.x = e.x - nx * SPEED * 0.6 * dt
        e.y = e.y - ny * SPEED * 0.6 * dt
    elseif e.state == "attack" then
        -- Стоим на месте и стреляем
        -- Но если игрок слишком близко - отходим
        if dist < KEEP_DIST * 0.6 then
            e.x = e.x - nx * SPEED * 0.4 * dt
            e.y = e.y - ny * SPEED * 0.4 * dt
        end
        
        -- Стрельба
        e.shootT = e.shootT - dt
        if e.shootT <= 0 then
            e.shootT = e.shootCooldown
            
            -- Добавляем немного разброса (inaccuracy)
            local spread = 0.08  -- ~4.6 градусов
            local angle = math.atan2(dy, dx) + (math.random() - 0.5) * spread * 2
            
            -- Создаём пулю
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

    -- Обновляем пули врага
    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        
        if b.life <= 0 then
            table.remove(enemyBullets, i)
        else
            -- Проверка попадания в игрока
            local ex = b.x - px
            local ey = b.y - py
            if ex*ex + ey*ey <= (SIZE * 0.5)^2 then
                table.remove(enemyBullets, i)
                if onHitPlayer then onHitPlayer(DAMAGE) end
            end
        end
    end

    -- Проверка попадания от пуль игрока
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

    -- Тень
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.push()
    love.graphics.translate(e.x + 6, e.y + 8)
    love.graphics.rotate(e.angle)
    love.graphics.draw(img, -SIZE/2, -SIZE/2)
    love.graphics.pop()

    -- Основной спрайт с эффектом попадания
    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.angle)
    local t = e.hit
    love.graphics.setColor(1, 1 - t*0.5, 1 - t*0.5, 1)
    love.graphics.draw(img, -SIZE/2, -SIZE/2)
    love.graphics.pop()

    -- Индикатор состояния (враг готовится к атаке)
    if e.state == "attack" then
        -- Пульсирующее свечение
        local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
        love.graphics.setColor(1, 0.2, 0.2, 0.2 + pulse * 0.3)
        love.graphics.circle("fill", e.x, e.y, SIZE * (0.8 + pulse * 0.3))
        
        -- Красные глаза/индикатор
        love.graphics.setColor(1, 0.1, 0.1, 0.8 + pulse * 0.2)
        love.graphics.circle("fill", e.x - 12, e.y - 8, 6)
        love.graphics.circle("fill", e.x + 12, e.y - 8, 6)
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setColor(1,1,1,1)
end

return enemy
