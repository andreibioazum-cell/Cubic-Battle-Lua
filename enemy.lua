local enemy = {}

-- Список всех врагов
enemy.list = {}

-- Параметры
local SPAWN_INTERVAL = 4    -- секунд между спавнами
local SPAWN_DIST = 600       -- враг спавнится на этом расстоянии от игрока
local SIGHT_RANGE = 400      -- видит игрока
local LOSE_RANGE = 700       -- теряет интерес
local ATTACK_RANGE = 70      -- атакует на этом расстоянии
local SPEED = 110            -- скорость врага
local SIZE = 50
local MAX_HP = 3
local ATK_DAMAGE = 10        -- сколько урона за удар
local ATK_COOLDOWN = 1.0     -- секунда между атаками

local spawnTimer = 0

-- Создаёт нового врага рядом с игроком
local function spawn(playerX, playerY)
    local angle = math.random() * math.pi * 2
    table.insert(enemy.list, {
        x = playerX + math.cos(angle) * SPAWN_DIST,
        y = playerY + math.sin(angle) * SPAWN_DIST,
        hp = MAX_HP,
        state = "idle",     -- idle / chase / attack / cooldown / dying
        stateTimer = 0,
        size = SIZE,
        flashTimer = 0      -- мигание при попадании
    })
end

function enemy.load()
    enemy.list = {}
    spawnTimer = 0
end

function enemy.update(dt, playerX, playerY, bullets, onPlayerHit)
    -- Спавн новых
    spawnTimer = spawnTimer + dt
    if spawnTimer >= SPAWN_INTERVAL then
        spawnTimer = 0
        spawn(playerX, playerY)
    end

    -- Обновляем каждого врага
    for i = #enemy.list, 1, -1 do
        local e = enemy.list[i]

        -- Мигание
        if e.flashTimer > 0 then
            e.flashTimer = e.flashTimer - dt
        end

        -- Расстояние до игрока
        local dx = playerX - e.x
        local dy = playerY - e.y
        local dist = math.sqrt(dx*dx + dy*dy)

        e.stateTimer = e.stateTimer + dt

        -- СТЕЙТ-МАШИНА
        if e.state == "dying" then
            -- Просто исчезает через 0.3 сек
            if e.stateTimer > 0.3 then
                table.remove(enemy.list, i)
            end

        elseif e.state == "idle" then
            -- Видит игрока?
            if dist < SIGHT_RANGE then
                e.state = "chase"
                e.stateTimer = 0
            end

        elseif e.state == "chase" then
            -- Игрок убежал?
            if dist > LOSE_RANGE then
                e.state = "idle"
                e.stateTimer = 0
            -- Подошёл достаточно близко?
            elseif dist < ATTACK_RANGE then
                e.state = "attack"
                e.stateTimer = 0
            else
                -- Бежим на игрока
                local nx, ny = dx / dist, dy / dist
                e.x = e.x + nx * SPEED * dt
                e.y = e.y + ny * SPEED * dt
            end

        elseif e.state == "attack" then
            -- Наносим урон один раз и переходим в кулдаун
            if onPlayerHit then
                onPlayerHit(ATK_DAMAGE)
            end
            e.state = "cooldown"
            e.stateTimer = 0

        elseif e.state == "cooldown" then
            if e.stateTimer >= ATK_COOLDOWN then
                -- Если игрок ещё близко — атакуем снова, иначе гонимся
                if dist < ATTACK_RANGE then
                    e.state = "attack"
                else
                    e.state = "chase"
                end
                e.stateTimer = 0
            end
        end

        -- Проверяем попадания пуль
        if e.state ~= "dying" then
            for j = #bullets, 1, -1 do
                local b = bullets[j]
                local bdx = b.x - e.x
                local bdy = b.y - e.y
                if bdx*bdx + bdy*bdy < (e.size/2 + 8)^2 then
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
end

function enemy.draw()
    for _, e in ipairs(enemy.list) do
        -- Тень
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", e.x - e.size/2 + 3, e.y - e.size/2 + 4, e.size, e.size, 8, 8)

        -- Тело (цвет зависит от стейта)
        if e.state == "dying" then
            local a = 1 - e.stateTimer / 0.3
            love.graphics.setColor(0.5, 0.5, 0.5, a)
        elseif e.flashTimer > 0 then
            love.graphics.setColor(1, 1, 1, 1)  -- белая вспышка при попадании
        elseif e.state == "attack" or e.state == "cooldown" then
            love.graphics.setColor(0.9, 0.2, 0.2)  -- красный когда атакует
        elseif e.state == "chase" then
            love.graphics.setColor(0.7, 0.3, 0.3)  -- тёмно-красный
        else
            love.graphics.setColor(0.4, 0.3, 0.5)  -- серо-фиолетовый в idle
        end
        love.graphics.rectangle("fill", e.x - e.size/2, e.y - e.size/2, e.size, e.size, 8, 8)

        -- Обводка
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", e.x - e.size/2, e.y - e.size/2, e.size, e.size, 8, 8)

        -- HP bar над врагом (если ранен)
        if e.hp < MAX_HP and e.state ~= "dying" then
            local bw = e.size
            local bh = 5
            local bx = e.x - bw/2
            local by = e.y - e.size/2 - 12
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", bx, by, bw, bh)
            love.graphics.setColor(0.2, 0.9, 0.3)
            love.graphics.rectangle("fill", bx, by, bw * (e.hp / MAX_HP), bh)
        end
    end
end

function enemy.count()
    return #enemy.list
end

return enemy
