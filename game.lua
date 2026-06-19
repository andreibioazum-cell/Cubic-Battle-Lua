local controls = require("controls")
local enemy = require("enemy")

local game = {}

-- ═══════════════════════════════════════════════════════════
-- ПРИЁМ ДАННЫХ ИЗ ЛОББИ
-- ═══════════════════════════════════════════════════════════

local coins_from_lobby = 0
local skin_from_lobby = "default"

function game.setCoins(amount)
    coins_from_lobby = amount
end

function game.setSkin(skin_name)
    skin_from_lobby = skin_name
end

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
local bg, playerImg, diamondImg, font
local cam = { x = 0, y = 0 }
local dead = false
local onDeathCallback = nil

-- ═══════════════════════════════════════════════════════════
-- ДЕНЬГИ И СКИНЫ (только данные, магазина в игре нет)
-- ═══════════════════════════════════════════════════════════

local coins = 0
local selected_skin = "default"
local abilities = {
    shield = {
        cooldown = 10,
        timer = 0,
        active = false,
        duration = 0
    }
}

-- ═══════════════════════════════════════════════════════════
-- ЗАГРУЗКА РЕСУРСОВ
-- ═══════════════════════════════════════════════════════════

local function loadTexture(path)
    local success, img = pcall(love.graphics.newImage, path)
    if success then
        return img
    else
        print("File not found: " .. path .. " (using fallback)")
        local fallback = love.graphics.newImage(love.image.newImageData(64, 64))
        return fallback
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
    
    if selected_skin == "diamond" and abilities.shield.timer > 0 then
        abilities.shield.active = true
        abilities.shield.timer = abilities.shield.timer - 1
        print("Shield blocked damage!")
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
-- ПОБЕДА НАД БОССОМ
-- ═══════════════════════════════════════════════════════════

local function onEnemyDefeated()
    coins = coins + 50
    print("+50 Cubicoins! Total: " .. coins)
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
    
    coins = coins_from_lobby
    selected_skin = skin_from_lobby

    -- Загрузка текстур
    bg = loadTexture("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end

    playerImg = loadTexture("player.png")
    if playerImg then playerImg:setFilter("nearest", "nearest") end
    
    diamondImg = loadTexture("player_diamond.png")
    if diamondImg then diamondImg:setFilter("nearest", "nearest") end

    font = font or love.graphics.newFont("Fredoka-Bold.ttf", 16)

    controls.load()
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x, cube.y)

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

    -- 🔥 ВСЕГДА РИСУЕМ ВРАГА
    enemy.draw()

    -- Отрисовка игрока
    if playerImg then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        
        if selected_skin == "diamond" and diamondImg then
            love.graphics.draw(diamondImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        else
            love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        end
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        
        if selected_skin == "diamond" and diamondImg then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(diamondImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
            love.graphics.setColor(0.2, 0.8, 1, 0.2)
            love.graphics.circle("fill", 0, 0, PLAYER_SIZE * 0.9)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        end
        
        if abilities.shield.active then
            love.graphics.setColor(0.2, 0.8, 1, 0.3)
            love.graphics.circle("fill", 0, 0, PLAYER_SIZE * 0.8)
            love.graphics.setColor(0.2, 0.8, 1, 0.5)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", 0, 0, PLAYER_SIZE * 0.8)
        end
        
        love.graphics.pop()
        
        if selected_skin == "diamond" then
            love.graphics.setColor(0.2, 0.8, 1, 0.8)
            love.graphics.setFont(font)
            local shield_text = "Shield " .. math.floor(abilities.shield.timer) .. "s"
            love.graphics.print(shield_text, cube.x - 20, cube.y - 70)
        end
    end

    love.graphics.pop()

    -- HUD
    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.print("Cubicoins: " .. coins, margin, margin + barH + 30)

    -- HP босса
    local e_obj = enemy.get()
    if e_obj then
        local ex = love.graphics.getWidth() - barW - margin
        drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BOSS " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
    end

    controls.draw()
end

function game.touchpressed(id, x, y)
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
        GameState.current = "lobby"
    end
end

return game
