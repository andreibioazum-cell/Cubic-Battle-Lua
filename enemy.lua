local enemy = {}

local enemyData = nil
local bullets = {}
local onDeath = nil
local enemyImg = nil

function enemy.load()
    -- Загружаем ту же текстуру, что и игрок
    local success, img = pcall(function()
        return love.graphics.newImage("player.png")
    end)
    if success and img then
        enemyImg = img
        print("Enemy loaded player.png")
    else
        print("Could not load player.png for enemy, using fallback")
        enemyImg = nil
    end
end

function enemy.reset()
    enemyData = nil
    bullets = {}
end

function enemy.spawnNow(x, y)
    enemyData = {
        x = x,
        y = y,
        hp = 5,
        maxHp = 5,
        shootTimer = 0,
        angle = 0,
        hitTimer = 0
    }
    print("Enemy spawned at", x, y)
end

function enemy.get()
    return enemyData
end

function enemy.update(dt, px, py, playerBullets, onHitPlayer)
    if not enemyData then
        return
    end

    -- Анимация попадания
    if enemyData.hitTimer > 0 then
        enemyData.hitTimer = enemyData.hitTimer - dt
    end

    local dx = px - enemyData.x
    local dy = py - enemyData.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    -- Поворот в сторону игрока
    if dist > 1 then
        enemyData.angle = math.atan2(dy, dx) + math.pi / 2
    end
    
    -- Движение к игроку
    if dist > 100 then
        enemyData.x = enemyData.x + (dx / dist) * 150 * dt
        enemyData.y = enemyData.y + (dy / dist) * 150 * dt
    end

    -- Стрельба
    enemyData.shootTimer = enemyData.shootTimer - dt
    if enemyData.shootTimer <= 0 then
        if dist > 0 then
            table.insert(bullets, {
                x = enemyData.x,
                y = enemyData.y,
                vx = (dx / dist) * 250,
                vy = (dy / dist) * 250,
                life = 3
            })
        end
        enemyData.shootTimer = 1.5
    end

    -- ============================================================
    -- ПОПАДАНИЯ ПО ВРАГУ (ПРОВЕРКА)
    -- ============================================================
    for i = #playerBullets, 1, -1 do
        local b = playerBullets[i]
        if b and b.x and b.y then
            local distToEnemy = math.sqrt((b.x - enemyData.x)^2 + (b.y - enemyData.y)^2)
            if distToEnemy < 35 then
                enemyData.hp = enemyData.hp - 1
                enemyData.hitTimer = 0.1
                table.remove(playerBullets, i)
                print("Enemy hit! HP: " .. enemyData.hp)
                
                if enemyData.hp <= 0 then
                    print("Enemy destroyed!")
                    enemyData = nil
                    if onDeath then onDeath() end
                    return
                end
            end
        end
    end

    -- Пули врага
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt

        local distToPlayer = math.sqrt((b.x - px)^2 + (b.y - py)^2)
        if distToPlayer < 30 then
            onHitPlayer(1)
            table.remove(bullets, i)
        elseif b.life <= 0 then
            table.remove(bullets, i)
        end
    end
end

function enemy.draw()
    if not enemyData then return end
    
    -- Рисуем врага с той же текстурой, что и игрок
    if enemyImg then
        -- Красный цвет для врага
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.draw(enemyImg, enemyData.x, enemyData.y, enemyData.angle, 1, 1, 32, 32)
        
        -- Эффект попадания (белая вспышка)
        if enemyData.hitTimer and enemyData.hitTimer > 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.draw(enemyImg, enemyData.x, enemyData.y, enemyData.angle, 1, 1, 32, 32)
        end
    else
        -- Fallback - красный круг
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", enemyData.x, enemyData.y, 30)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("line", enemyData.x, enemyData.y, 30)
    end
    
    -- HP бар
    local barWidth = 40
    local barHeight = 5
    local barX = enemyData.x - barWidth / 2
    local barY = enemyData.y - 45
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    local hpPercent = enemyData.hp / enemyData.maxHp
    if hpPercent > 0.6 then
        love.graphics.setColor(0, 1, 0)
    elseif hpPercent > 0.3 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * hpPercent, barHeight)
    
    -- Пули врага
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle("fill", b.x, b.y, 6)
        love.graphics.setColor(1, 0.5, 0, 0.3)
        love.graphics.circle("fill", b.x, b.y, 12)
    end
end

function enemy.setDeathCallback(fn)
    onDeath = fn
end

return enemy
