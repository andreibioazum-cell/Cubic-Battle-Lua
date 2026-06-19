local controls = require("controls")
local enemy = require("enemy")

local game = {}

-- ═══════════════════════════════════════════════════════════
-- КОНСТАНТЫ ОТКРЫТОГО МИРА
-- ═══════════════════════════════════════════════════════════

local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 340 * 1.15
local WORLD_WIDTH = 3000      -- 🔥 ОГРОМНЫЙ МИР
local WORLD_HEIGHT = 3000     -- 🔥 ОГРОМНЫЙ МИР

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
-- ДЕРЕВЬЯ, КАМНИ, КУСТЫ (ОБЪЕКТЫ МИРА)
-- ═══════════════════════════════════════════════════════════

local world_objects = {}

local function generateWorld()
    world_objects = {}
    
    -- Генерируем деревья
    for i = 1, 80 do
        table.insert(world_objects, {
            type = "tree",
            x = math.random(100, WORLD_WIDTH - 100),
            y = math.random(100, WORLD_HEIGHT - 100),
            size = math.random(30, 60)
        })
    end
    
    -- Генерируем камни
    for i = 1, 40 do
        table.insert(world_objects, {
            type = "rock",
            x = math.random(100, WORLD_WIDTH - 100),
            y = math.random(100, WORLD_HEIGHT - 100),
            size = math.random(15, 35)
        })
    end
    
    -- Генерируем кусты
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
            -- Ствол
            love.graphics.setColor(0.4, 0.25, 0.1, 1)
            love.graphics.rectangle("fill", obj.x - 4, obj.y - obj.size/2, 8, obj.size * 0.6)
            -- Крона
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

    bg = bg or love.graphics.newImage("grass.png")
    if bg then bg:setWrap("repeat", "repeat") end

    playerImg = playerImg or love.graphics.newImage("player.png")
    if playerImg then playerImg:setFilter("nearest", "nearest") end

    font = font or love.graphics.newFont("Fredoka-Bold.ttf", 16)

    controls.load()
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x, cube.y)
    
    generateWorld()  -- 🔥 ГЕНЕРИРУЕМ МИР

    enemy.setDeathCallback(function()
        GameState.current = "lobby"
    end)

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
    
    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt
    
    -- 🔥 ГРАНИЦЫ ОТКРЫТОГО МИРА
    cube.x = math.max(0, math.min(WORLD_WIDTH, cube.x))
    cube.y = math.max(0, math.min(WORLD_HEIGHT, cube.y))

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    cube.hit = math.max(0, cube.hit - dt * 3)

    -- 🔥 КАМЕРА СЛЕДИТ ЗА ИГРОКОМ
    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    local k = 1 - math.exp(-dt * 7.3)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

    -- Пули
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

    -- 🔥 ФОН
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

    -- 🔥 ОБЪЕКТЫ МИРА
    drawWorldObjects()

    -- 🔥 ПУЛИ
    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
    end

    -- 🔥 ПРИЦЕЛ
    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(14)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(cube.x, cube.y, cube.x + ax * 180, cube.y + ay * 180)
    end

    -- 🔥 ВРАГ
    enemy.draw()

    -- 🔥 ИГРОК
    if playerImg then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        local t = cube.hit
        love.graphics.setColor(1, 1 - t * 0.6, 1 - t * 0.6, 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE / 2, -PLAYER_SIZE / 2)
        love.graphics.pop()
    end

    love.graphics.pop()

    -- 🔥 HUD
    love.graphics.setColor(1, 1, 1, 1)
    if font then love.graphics.setFont(font) end
    
    local barW, barH = 180, 16
    local margin = 16
    
    drawHPBar(margin, margin, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3, 0.85, 0.35})
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP " .. math.max(0, cube.hp), margin, margin + barH + 4)

    local e_obj = enemy.get()
    if e_obj then
        local ex = love.graphics.getWidth() - barW - margin
        drawHPBar(ex, margin, barW, barH, e_obj.hp, 5, {0.9, 0.2, 0.2})
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("ENEMY " .. math.max(0, e_obj.hp), ex, margin + barH + 4)
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
