local enemy = {}
local e = nil
local bullets = {}
local onDeath = nil
local img

function enemy.load()
    img = love.graphics.newImage("player.png")
end

function enemy.reset()
    e = nil
    bullets = {}
end

function enemy.spawnNow(x, y)
    e = { x = x, y = y, hp = 5, shootT = 0 }
end

function enemy.get()
    return e
end

function enemy.update(dt, px, py, pBullets, onHitPlayer)
    if not e then
        return  -- Враг мёртв и не возрождается
    end

    -- Движение к игроку
    local dx, dy = px - e.x, py - e.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 100 then
        e.x = e.x + (dx / dist) * 150 * dt
        e.y = e.y + (dy / dist) * 150 * dt
    end

    -- Стрельба
    e.shootT = e.shootT - dt
    if e.shootT <= 0 then
        if dist > 0 then
            table.insert(bullets, {
                x = e.x, y = e.y,
                vx = (dx / dist) * 250,
                vy = (dy / dist) * 250,
                life = 3
            })
        else
            table.insert(bullets, {
                x = e.x, y = e.y,
                vx = 0, vy = -250,
                life = 3
            })
        end
        e.shootT = 1.5
    end

    -- Попадания пуль игрока во врага
    for i = #pBullets, 1, -1 do
        local b = pBullets[i]
        if math.abs(b.x - e.x) < 30 and math.abs(b.y - e.y) < 30 then
            e.hp = e.hp - 1
            table.remove(pBullets, i)
            if e.hp <= 0 then
                e = nil
                if onDeath then onDeath() end
                return
            end
        end
    end

    -- Пули врага
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt

        if math.abs(b.x - px) < 30 and math.abs(b.y - py) < 30 then
            onHitPlayer(1)
            table.remove(bullets, i)
        elseif b.life <= 0 then
            table.remove(bullets, i)
        end
    end
end

function enemy.draw()
    if not e then return end
    love.graphics.setColor(1, 0, 0)
    love.graphics.draw(
        img, e.x, e.y,
        0,
        55 / img:getWidth(), 55 / img:getHeight(),
        img:getWidth() / 2, img:getHeight() / 2
    )
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", b.x, b.y, 6)
    end
end

function enemy.setDeathCallback(fn)
    onDeath = fn
end

return enemy
