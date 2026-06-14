-- particles.lua — система частиц для всего
local particles = {}

-- ===== НАСТРОЙКИ =====
local MAX_PARTICLES = 5000  -- общий лимит
local pool = {}  -- пул частиц для быстрого создания

-- ===== ТИПЫ ЧАСТИЦ =====
particles.WALK = {   -- следы при ходьбе
    life = 0.4,
    size = 4,
    colors = {{0.9,0.8,0.4}, {0.7,0.5,0.3}},
    spread = 20,
    fade = true
}
particles.SHOOT = {  -- вспышка при выстреле
    life = 0.15,
    size = 8,
    colors = {{1,0.9,0.3}, {1,0.6,0.1}},
    spread = 40,
    fade = true
}
particles.BULLET_TRAIL = {  -- след пули
    life = 0.25,
    size = 3,
    colors = {{1,0.9,0.4}, {1,0.7,0.2}},
    spread = 8,
    fade = true
}
particles.HIT = {  -- попадание
    life = 0.6,
    size = 6,
    colors = {{1,1,0.8}, {1,0.3,0}, {0.8,0.2,0}},
    spread = 60,
    fade = true
}
particles.DEATH = {  -- смерть врага
    life = 0.8,
    size = 10,
    colors = {{1,0.5,0}, {1,0,0}, {0.6,0,0}},
    spread = 100,
    fade = true
}

-- ===== ХРАНИЛИЩЕ ЧАСТИЦ =====
particles.active = {}  -- все живые частицы

-- Создать частицу из пула
function particles.spawn(x, y, type)
    local p
    if #pool > 0 then
        p = pool[#pool]; pool[#pool] = nil
    else
        if #particles.active >= MAX_PARTICLES then return end
        p = {}
    end
    
    local angle = math.random() * math.pi * 2
    local speed = math.random() * type.spread
    local color = type.colors[math.random(#type.colors)]
    
    p.x = x
    p.y = y
    p.vx = math.cos(angle) * speed
    p.vy = math.sin(angle) * speed
    p.life = type.life * (0.5 + math.random() * 0.5)
    p.maxLife = p.life
    p.size = type.size * (0.7 + math.random() * 0.6)
    p.r = color[1]
    p.g = color[2]
    p.b = color[3]
    p.fade = type.fade
    
    particles.active[#particles.active + 1] = p
end

-- Создать несколько частиц сразу
function particles.burst(x, y, count, type)
    for i = 1, count do
        particles.spawn(x, y, type)
    end
end

-- Обновление
function particles.update(dt)
    for i = #particles.active, 1, -1 do
        local p = particles.active[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        
        -- Затухание скорости
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
        
        if p.life <= 0 then
            -- Возвращаем в пул
            if #pool < 1000 then
                pool[#pool + 1] = p
            end
            particles.active[i] = particles.active[#particles.active]
            particles.active[#particles.active] = nil
        end
    end
end

-- Отрисовка
function particles.draw()
    for _, p in ipairs(particles.active) do
        local alpha = p.fade and (p.life / p.maxLife) or 1
        love.graphics.setColor(p.r, p.g, p.b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
end

-- Очистка
function particles.clear()
    particles.active = {}
    pool = {}
end

return particles
