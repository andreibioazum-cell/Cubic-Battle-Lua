local controls = require("controls")
local enemy = require("enemy")

local game = {}

-- ═══════════════════════════════════════════════════════════
-- КОНСТАНТЫ
-- ═══════════════════════════════════════════════════════════

local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15
local WORLD_WIDTH = 3000
local WORLD_HEIGHT = 3000

-- ═══════════════════════════════════════════════════════════
-- ПЕРЕМЕННЫЕ
-- ═══════════════════════════════════════════════════════════

local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = PLAYER_HP_MAX, hit = 0 }
local bullets = {}
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false
local onDeathCallback = nil

-- ═══════════════════════════════════════════════════════════
-- МАГАЗИН И ДЕНЬГИ
-- ═══════════════════════════════════════════════════════════

local coins = 0
local selected_skin = "default"  -- "default", "diamond"
local shop_open = false

-- Скины
local skins = {
    default = {
        name = "Default Cube",
        color = {1, 1, 1},
        ability = nil,
        ability_name = "None",
        price = 0,
        owned = true
    },
    diamond = {
        name = "Diamond Cube",
        color = {0.2, 0.8, 1},
        ability = "shield",
        ability_name = "Shield",
        ability_desc = "Blocks 1 hit every 10 sec",
        price = 100,
        owned = false
    }
}

-- Способности
local abilities = {
    shield = {
        cooldown = 10,
        timer = 0,
        active = false,
        duration = 0
    }
}

-- ═══════════════════════════════════════════════════════════
-- ОБЪЕКТЫ МИРА
-- ═══════════════════════════════════════════════════════════

local world_objects = {}

local function generateWorld()
    world_objects = {}
    
    for i = 1, 80 do
        table.insert(world_objects, {
            type = "tree",
            x = math.random(100, WORLD_WIDTH - 100),
            y = math.random(100, WORLD_HEIGHT - 100),
            size = math.random(30, 60)
        })
    end
    
    for i = 1, 40 do
        table.insert(world_objects, {
            type = "rock",
            x = math.random(100, WORLD_WIDTH - 100),
            y = math.random(100, WORLD_HEIGHT - 100),
            size = math.random(15, 35)
        })
    end
    
    for i = 1, 60 do
        table.insert(world_objects, {
            type = "bush",
            x = math.random(100, WORLD_WIDTH - 100),
            y = math.random(100, WORLD_HEIGHT - 100),
            size = math.random(10, 25)
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИИ ОТРИСОВКИ
-- ═══════════════════════════════════════════════════════════

local function drawHPBar(x, y, w, h, hp, max, color)
    hp = math.max(0, hp)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4, 4, 4)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", x, y, w * (hp / max), h, 4, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

local function drawWorldObjects()
    for _, obj in ipairs(world_objects) do
        if obj.type == "tree" then
            love.graphics.setColor(0.4, 0.25, 0.1, 1)
            love.graphics.rectangle("fill", obj.x - 4, obj.y - obj.size/2, 8, obj.size * 0.6)
            love.graphics.setColor(0.1, 0.5, 0.1, 1)
            love.graphics.circle("fill", obj.x, obj.y - obj.size * 0.3, obj.size * 0.5)
            love.graphics.setColor(0.05, 0.4, 0.05, 1)
            love.graphics.circle("fill", obj.x - obj.size * 0.2, obj.y - obj.size * 0.5, obj.size * 0.4)
            love.graphics.circle("fill", obj.x + obj.size * 0.2, obj.y - obj.size * 0.5, obj.size * 0.4)
        elseif obj.type == "rock" then
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
            love.graphics.circle("fill", obj.x, obj.y, obj.size)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.circle("fill", obj.x - obj.size * 0.2, obj.y - obj.size * 0.2, obj.size * 0.4)
        elseif obj.type == "bush" then
            love.graphics.setColor(0.2, 0.6, 0.1, 1)
            love.graphics.circle("fill", obj.x, obj.y, obj.size)
            love.graphics.setColor(0.15, 0.5, 0.08, 1)
            love.graphics.circle("fill", obj.x - obj.size * 0.3, obj.y + obj.size * 0.1, obj.size * 0.6)
            love.graphics.circle("fill", obj.x + obj.size * 0.3, obj.y + obj.size * 0.1, obj.size * 0.6)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ОТРИСОВКА МАГАЗИНА
-- ═══════════════════════════════════════════════════════════

local function drawShop()
    local w, h = love.graphics.getDimensions()
    local shop_w = 400
    local shop_h = 350
    local shop_x = w/2 - shop_w/2
    local shop_y = h/2 - shop_h/2
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", shop_x, shop_y, shop_w, shop_h, 16, 16)
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12, 12)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12, 12)
    
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(font)
    love.graphics.print("🛒 SHOP", shop_x + 20, shop_y + 15)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("💰 Coins: " .. coins, shop_x + 20, shop_y + 45)
    
    -- Алмазный куб
    local item_x = shop_x + 20
    local item_y = shop_y + 80
    local item_w = shop_w - 40
    local item_h = 65
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", item_x, item_y, item_w, item_h, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", item_x, item_y, item_w, item_h, 8, 8)
    
    love.graphics.setColor(0.2, 0.8, 1, 0.9)
    love.graphics.print("💎 Diamond Cube", item_x + 10, item_y + 8)
    love.graphics.setColor(0.7, 0.7, 0.9, 0.7)
    love.graphics.setFont(font)
    love.graphics.print("Ability: Shield (blocks 1 hit / 10 sec)", item_x + 10, item_y + 30)
    love.graphics.setColor(1, 1, 0, 0.8)
    
    if skins.diamond.owned then
        love.graphics.print("✅ OWNED", item_x + item_w - 80, item_y + 8)
    else
        love.graphics.print("💰 " .. skins.diamond.price .. " coins", item_x + item_w - 100, item_y + 8)
        love.graphics.setColor(0.2, 0.8, 0.3, 0.9)
        love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 30, 60, 25, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BUY", item_x + item_w - 65, item_y + 35)
    end
    
    -- Кнопка закрытия
    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", shop_x + shop_w - 80, shop_y + shop_h - 45, 60, 30, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("CLOSE", shop_x + shop_w - 65, shop_y + shop_h - 38)
end

-- ═══════════════════════════════════════════════════════════
-- ПУЛИ
-- ═══════════════════════════════════════════════════════════

local function spawnBullet(x, y, dx, dy)
    table.insert(bullets, {
        x = x,
        y = y,
        vx = dx * BULLET_SPEED,
        vy = dy * BULLET_SPEED,
        life = 3
    })
end

-- ═══════════════════════════════════════════════════════════
-- УРОН
-- ═══════════════════════════════════════════════════════════

local function onHitPlayer(dmg)
    if dead then return end
    
    -- Проверяем способность "Щит"
    if selected_skin == "diamond" and abilities.shield.timer > 0 then
        abilities.shield.active = true
        abilities.shield.timer = abilities.shield.timer - 1  -- тратим заряд
        print("🛡️ Shield blocked damage!")
        return
    end
    
    cube.hp = cube.hp - dmg
    cube.hit = 1
    if cube.hp <= 0 then
        cube.hp = 0
        dead = true
        if onDeathCallback then
            onDeathCallback()
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ПОБЕДА НАД ВРАГОМ
-- ═══════════════════════════════════════════════════════════

local function onEnemyDefeated()
    coins = coins + 10  -- 💰 10 монет за победу
    print("💰 +10 coins! Total: " .. coins)
    GameState.current = "lobby"
end

-- ═══════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════

function game.setOnDeath(callback)
    onDeathCallback = callback
end

function game.load()
    cube.x = WORLD_WIDTH / 2
    cube.y = WORLD_HEIGHT / 2
    cube.angle = 0
    cube.hp = PLAYER_HP_MAX
    cube.hit = 0
    dead = false
    bullets = {}
    cam.x = cube.x - love.graphics.getWidth() / 2
    cam.y = cube.y - love.graphics.getHeight() / 2
    shop_open = false

    bg = bg or love.graphics.newImage("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end

    playerImg = playerImg or love.graphics.newImage("player.png")
    if playerImg then playerImg:setFilter("nearest", "nearest") end

    font = font or love.graphics.newFont("Fredoka-Bold.ttf", 16)

    controls.load()
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x, cube.y)
    
    generateWorld()

    enemy.setDeathCallback(onEnemyDefeated)

    controls.setOnBack(function()
        GameState.current = "lobby"
    end)
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    if dead then 
        controls.update(dt)
        return 
    end
    
    controls.update(dt)
    
    -- Обновляем способности
    if selected_skin == "diamond" then
        abilities.shield.timer = math.min(abilities.shield.cooldown, abilities.shield.timer + dt)
        if abilities.shield.active then
            abilities.shield.duration = abilities.shield.duration + dt
            if abilities.shield.duration > 0.5 then
                abilities.shield.active = false
                abilities.shield.duration = 0
            end
        end
    end
    
    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt
    
    cube.x = math.max(0, math.min(WORLD_WIDTH, cube.x))
    cube.y = math.max(0, math.min(WORLD_HEIGHT, cube.y))

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    cube.hit = math.max(0, cube.hit - dt * 3)

    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bullets, i)
        end
    end

    enemy.update(dt, cube.x, cube.y, bullets, onHitPlayer)
end

function game.draw()
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local w, h = love.graphics.getDimensions()
    if bg then
        local tw, th = bg:getWidth(), bg:getHeight()
        local sX = math.floor(cam.x / tw) * tw
        local sY = math.floor(cam.y / th) * th
        for x = sX, sX + w + tw, tw do
            for y = sY, sY + h + th, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end

    drawWorldObjects()

    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end

    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(14)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
    end

    enemy.draw()

    -- 🔥 ОТРИСОВКА ИГРОКА С ВЫБРАННЫМ СКИНОМ
    if playerImg then
        -- Тень
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()

        -- Основной спрайт с цветом скина
        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        
        local skin_color = skins[selected_skin].color
        love.graphics.setColor(skin_color[1], skin_color[2], skin_color[3], 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        
        -- Если способность активна — свечение
        if abilities.shield.active then
            love.graphics.setColor(0.2, 0.8, 1, 0.3)
            love.graphics.circle("fill", 0, 0, PLAYER_SIZE * 0.8)
            love.graphics.setColor(0.2, 0.8, 1, 0.5)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", 0, 0, PLAYER_SIZE * 0.8)
        end
        
        love.graphics.pop()
        
        -- Отображение способности
        if selected_skin == "diamond" then
            love.graphics.setColor(0.2, 0.8, 1, 0.8)
            love.graphics.setFont(font)
            local shield_text = "🛡️ " .. math.floor(abilities.shield.timer) .. "s"
            love.graphics.print(shield_text, cube.x - 20, cube.y - 70)
        end
    end

    love.graphics.pop()

    -- ═══════════════════════════════════════════════════════════
    -- HUD
    -- ═══════════════════════════════════════════════════════════

    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    -- 💰 МОНЕТЫ
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.print("💰 " .. coins, margin, margin + barH + 30)

    local e_obj = enemy.get()
    if e_obj then
        local ex = love.graphics.getWidth() - barW - margin
        drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("ENEMY " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
    end

    -- 🛒 КНОПКА МАГАЗИНА
    local shop_btn_x = love.graphics.getWidth() / 2 - 50
    local shop_btn_y = 10
    love.graphics.setColor(0.4, 0.2, 0.8, 0.9)
    love.graphics.rectangle("fill", shop_btn_x, shop_btn_y, 100, 35, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("🛒 SHOP", shop_btn_x + 15, shop_btn_y + 8)

    controls.draw()
    
    -- Магазин
    if shop_open then
        drawShop()
    end
end

function game.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- Кнопка магазина
    local shop_btn_x = w/2 - 50
    local shop_btn_y = 10
    if x >= shop_btn_x and x <= shop_btn_x + 100 and y >= shop_btn_y and y <= shop_btn_y + 35 then
        shop_open = not shop_open
        return
    end
    
    -- Магазин
    if shop_open then
        local shop_w = 400
        local shop_h = 350
        local shop_x = w/2 - shop_w/2
        local shop_y = h/2 - shop_h/2
        
        -- Кнопка CLOSE
        if x >= shop_x + shop_w - 80 and x <= shop_x + shop_w - 20 and 
           y >= shop_y + shop_h - 45 and y <= shop_y + shop_h - 15 then
            shop_open = false
            return
        end
        
        -- Кнопка BUY (Diamond Cube)
        local item_x = shop_x + 20
        local item_y = shop_y + 80
        local item_w = shop_w - 40
        local item_h = 65
        
        if x >= item_x + item_w - 80 and x <= item_x + item_w - 20 and
           y >= item_y + 30 and y <= item_y + 55 then
            if not skins.diamond.owned and coins >= skins.diamond.price then
                coins = coins - skins.diamond.price
                skins.diamond.owned = true
                selected_skin = "diamond"
                print("💎 Diamond Cube purchased!")
            elseif skins.diamond.owned then
                selected_skin = "diamond"
                print("💎 Diamond Cube equipped!")
            else
                print("❌ Not enough coins!")
            end
            return
        end
    end
    
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then
        spawnBullet(cube.x, cube.y, dx, dy)
    end
end

function game.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if shop_open then
            shop_open = false
        else
            GameState.current = "lobby"
        end
    end
end

return game
