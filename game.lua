local controls = require("controls")
local enemy = require("enemy")
local game = {}

local WORLD_SIZE = 3000
local player = { x = 1500, y = 1500, speed = 250, hp = 5, maxHp = 5, angle = 0 }
local camera = { x = 0, y = 0 }
local bullets = {}
local coins = 0
local selectedSkin = "default"
local dead = false
local fontUI = nil

local shieldActive = false
local shieldTimer = 0
local shieldDuration = 2.5

local playerImg = nil

local function saveGame()
    love.filesystem.write("save.txt", coins .. "\n" .. selectedSkin .. "\n" .. selectedSkin)
end

function game.load()
    controls.load()
    fontUI = love.graphics.newFont(14)
    
    -- Загрузка текстуры игрока
    local success, img = pcall(function()
        return love.graphics.newImage("player.png")
    end)
    if success and img then
        playerImg = img
        print("Loaded player.png")
    else
        print("Could not load player.png, using fallback")
        playerImg = nil
    end
    
    -- Загружаем врага
    enemy.load()
    
    player.x, player.y = 1500, 1500
    player.hp = player.maxHp
    dead = false
    bullets = {}
    shieldActive = false
    shieldTimer = 0
    
    enemy.reset()
    enemy.spawnNow(player.x + 300, player.y + 300)
    enemy.setDeathCallback(function()
        coins = coins + 50
        saveGame()
        _G.GameState.current = "lobby"
        print("Enemy killed! +50 coins")
    end)
    
    print("Game loaded! Skin: " .. selectedSkin)
end

function game.update(dt)
    if dead then return end
    controls.update(dt)
    
    if shieldActive then
        shieldTimer = shieldTimer - dt
        if shieldTimer <= 0 then
            shieldActive = false
        end
    end
    
    -- Движение
    local dx, dy = controls.getMove()
    player.x = math.max(0, math.min(WORLD_SIZE, player.x + dx * player.speed * dt))
    player.y = math.max(0, math.min(WORLD_SIZE, player.y + dy * player.speed * dt))
    if dx ~= 0 or dy ~= 0 then
        player.angle = math.atan2(dy, dx) + math.pi / 2
    end
    
    -- Камера
    local sw, sh = love.graphics.getDimensions()
    camera.x = camera.x + (player.x - sw/2 - camera.x) * 5 * dt
    camera.y = camera.y + (player.y - sh/2 - camera.y) * 5 * dt
    
    -- Обновление пуль
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.x < 0 or b.x > WORLD_SIZE or b.y < 0 or b.y > WORLD_SIZE then
            table.remove(bullets, i)
        end
    end
    
    -- Обновление врага (передаем пули)
    enemy.update(dt, player.x, player.y, bullets, function(dmg)
        if shieldActive then return end
        player.hp = player.hp - dmg
        if player.hp <= 0 then
            dead = true
            _G.GameState.current = "lobby"
        end
    end)
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    
    -- Фон
    love.graphics.setColor(0.2, 0.5, 0.2)
    love.graphics.rectangle("fill", 0, 0, WORLD_SIZE, WORLD_SIZE)
    
    -- Сетка
    love.graphics.setColor(0.3, 0.6, 0.3, 0.3)
    for x = 0, WORLD_SIZE, 100 do
        love.graphics.line(x, 0, x, WORLD_SIZE)
    end
    for y = 0, WORLD_SIZE, 100 do
        love.graphics.line(0, y, WORLD_SIZE, y)
    end
    
    -- Рисуем врага
    enemy.draw()
    
    -- Рисуем игрока
    if playerImg then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(playerImg, player.x, player.y, player.angle, 1, 1, 32, 32)
    else
        if selectedSkin == "diamond" then
            love.graphics.setColor(0, 0.8, 1)
            love.graphics.polygon("fill",
                player.x, player.y - 30,
                player.x + 30, player.y,
                player.x, player.y + 30,
                player.x - 30, player.y
            )
        else
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.rectangle("fill", player.x - 25, player.y - 25, 50, 50)
        end
    end
    
    -- Щит
    if shieldActive then
        love.graphics.setColor(0.6, 0.2, 1, 0.3 + 0.2 * math.sin(love.timer.getTime() * 6))
        love.graphics.circle("fill", player.x, player.y, 45)
        love.graphics.setColor(0.8, 0.4, 1, 0.2)
        love.graphics.circle("fill", player.x, player.y, 55)
    end
    
    -- Пули игрока
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, 5)
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.circle("fill", b.x, b.y, 10)
    end
    
    love.graphics.pop()
    
    -- UI
    local sw, sh = love.graphics.getDimensions()
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, sw, 40)
    
    -- HP
    local hpPercent = player.hp / player.maxHp
    if hpPercent > 0.6 then
        love.graphics.setColor(0, 1, 0)
    elseif hpPercent > 0.3 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", 10, 10, hpPercent * 150, 20)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", 10, 10, 150, 20)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontUI)
    love.graphics.printf(player.hp .. "/" .. player.maxHp, 10, 12, 150, "center")
    
    -- Монеты
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.printf("COINS: " .. coins, sw - 150, 12, 140, "right")
    
    -- Подсказка
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.printf("WASD - Move | SPACE - Attack | E - Shield", 0, sh - 25, sw, "center")
    
    controls.draw()
end

-- ============================================================
-- АТАКА (СПАВН ПУЛИ)
-- ============================================================
function game.shoot()
    local aimX, aimY = controls.getAim()
    local len = math.sqrt(aimX*aimX + aimY*aimY)
    if len > 0 then
        aimX, aimY = aimX/len, aimY/len
    else
        aimX, aimY = 0, -1
    end
    table.insert(bullets, {
        x = player.x,
        y = player.y,
        vx = aimX * 400,
        vy = aimY * 400
    })
    print("Shot fired!")
end

-- ============================================================
-- ОБРАБОТКА ВВОДА
-- ============================================================

function game.keypressed(key)
    if key == "escape" then
        _G.GameState.current = "lobby"
        return
    end
    
    local result = controls.keypressed(key)
    
    if result == "attack" then
        game.shoot()
    end
    
    if result == "ability" then
        if selectedSkin == "diamond" and not shieldActive and controls.canUseAbility() then
            shieldActive = true
            shieldTimer = shieldDuration
            controls.useAbility()
            print("Shield activated!")
        end
    end
end

function game.keyreleased(key)
    local result = controls.keyreleased(key)
    
    if result == "attack" then
        local _, dx, dy = result
        if dx and dy then
            game.shoot()
        end
    end
end

function game.mousepressed(x, y, button)
    local result = controls.mousepressed(x, y, button)
    
    if result == "attack" then
        game.shoot()
    end
    
    if result == "ability" then
        if selectedSkin == "diamond" and not shieldActive and controls.canUseAbility() then
            shieldActive = true
            shieldTimer = shieldDuration
            controls.useAbility()
            print("Shield activated!")
        end
    end
end

function game.mousereleased(x, y, button)
    local shot, dx, dy, abilityUsed = controls.mousereleased(x, y, button)
    
    if shot then
        game.shoot()
    end
    
    if abilityUsed then
        if selectedSkin == "diamond" and not shieldActive and controls.canUseAbility() then
            shieldActive = true
            shieldTimer = shieldDuration
            controls.useAbility()
            print("Shield activated!")
        end
    end
end

function game.setCoins(c)
    coins = c or 0
end

function game.setSkin(s)
    selectedSkin = s or "default"
end

function game.resize()
    controls.resize()
end

return game
