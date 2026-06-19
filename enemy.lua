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
    e = { 
        x = x, 
        y = y, 
        hp = 5, 
        maxHp = 5,
        shootT = 0,
        angle = 0
    }
    -- Вызываем событие спавна врага для модов
    local modSystem = require("mod_system")
    modSystem.trigger("onEnemySpawn", e)
end

function enemy.get()
    return e
end

function enemy.update(dt, px, py, pBullets, onHitPlayer)
    if not e then
        return
    end

    local dx, dy = px - e.x, py - e.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 1 then
        e.angle = math.atan2(dy, dx) + math.pi / 2
    end
    
    if dist > 100 then
        e.x = e.x + (dx / dist) * 150 * dt
        e.y = e.y + (dy / dist) * 150 * dt
    end

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

    for i = #pBullets, 1, -1 do
        local b = pBullets[i]
        if math.abs(b.x - e.x) < 30 and math.abs(b.y - e.y) < 30 then
            e.hp = e.hp - 1
            table.remove(pBullets, i)
            
            -- Вызываем событие попадания для модов
            local modSystem = require("mod_system")
            modSystem.gameHit(e, 1)
            
            if e.hp <= 0 then
                e = nil
                if onDeath then onDeath() end
                return
            end
        end
    end

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
        e.angle,
        55 / img:getWidth(), 55 / img:getHeight(),
        img:getWidth() / 2, img:getHeight() / 2
    )
    
    local barWidth = 40
    local barHeight = 5
    local barX = e.x - barWidth / 2
    local barY = e.y - 40
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    local hpPercent = e.hp / e.maxHp
    if hpPercent > 0.6 then
        love.graphics.setColor(0, 1, 0)
    elseif hpPercent > 0.3 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(
        tostring(e.hp) .. "/" .. tostring(e.maxHp),
        e.x - 15, barY - 15, 30, "center"
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
