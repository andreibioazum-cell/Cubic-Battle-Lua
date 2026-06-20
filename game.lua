local controls = require("controls")
local enemy = require("enemy")
local game = {}

local WORLD_SIZE = 3000
local cube = { x = 1500, y = 1500, speed = 260, hp = 5, angle = 0, hit = 0 }
local cam = { x = 0, y = 0 }
local bullets = {}
local coins = 0
local selected_skin = "default"
local dead = false
local bg, playerImg, diamondImg
local menuFont = nil

function game.load()
    controls.load()
    
    menuFont = love.graphics.newFont(16)
    
    cube.x, cube.y = 1500, 1500
    cube.hp = 5
    dead = false
    bullets = {}
    bg = love.graphics.newImage("grass.png")
    bg:setWrap("repeat", "repeat")
    playerImg = love.graphics.newImage("player.png")
    diamondImg = love.graphics.newImage("player_diamond.png")
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x + 300, cube.y + 300)
    enemy.setDeathCallback(function()
        coins = coins + 50
        _G.GameState.current = "lobby"
    end)
end

function game.update(dt)
    if dead then return end
    controls.update(dt)

    local dx, dy = controls.getMove()
    cube.x = math.max(0, math.min(WORLD_SIZE, cube.x + dx * cube.speed * dt))
    cube.y = math.max(0, math.min(WORLD_SIZE, cube.y + dy * cube.speed * dt))
    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end

    local sw, sh = love.graphics.getDimensions()
    cam.x = cam.x + (cube.x - sw / 2 - cam.x) * 5 * dt
    cam.y = cam.y + (cube.y - sh / 2 - cam.y) * 5 * dt

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b and type(b.x) == "number" and type(b.y) == "number" then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if b.x < 0 or b.x > WORLD_SIZE or b.y < 0 or b.y > WORLD_SIZE then
                table.remove(bullets, i)
            end
        else
            table.remove(bullets, i)
        end
    end

    enemy.update(dt, cube.x, cube.y, bullets, function(dmg)
        cube.hp = cube.hp - dmg
        if cube.hp <= 0 then
            dead = true
            if game.onDeath then
                game.onDeath()
            end
            _G.GameState.current = "lobby"
        end
    end)
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local sw, sh = love.graphics.getDimensions()
    local tw, th = bg:getDimensions()
    for x = math.floor(cam.x / tw) * tw, cam.x + sw, tw do
        for y = math.floor(cam.y / th) * th, cam.y + sh, th do
            love.graphics.draw(bg, x, y)
        end
    end

    enemy.draw()

    love.graphics.setColor(1, 1, 1)
    local img = selected_skin == "diamond" and diamondImg or playerImg
    love.graphics.draw(
        img, cube.x, cube.y,
        cube.angle,
        55 / img:getWidth(), 55 / img:getHeight(),
        img:getWidth() / 2, img:getHeight() / 2
    )

    for _, b in ipairs(bullets) do
        if b and type(b.x) == "number" and type(b.y) == "number" then
            love.graphics.circle("fill", b.x, b.y, 5)
        end
    end
    love.graphics.pop()

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 20, 20, 200, 20)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", 20, 20, 200 * (cube.hp / 5), 20)
    
    local screenW, screenH = love.graphics.getDimensions()
    local menuBtnX = screenW - 120
    local menuBtnY = 15
    local menuBtnW = 100
    local menuBtnH = 35
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", menuBtnX + 2, menuBtnY + 2, menuBtnW, menuBtnH, 8)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.85)
    love.graphics.rectangle("fill", menuBtnX, menuBtnY, menuBtnW, menuBtnH, 8)
    love.graphics.setColor(1, 0.3, 0.3, 0.2)
    love.graphics.rectangle("fill", menuBtnX + 3, menuBtnY + 3, menuBtnW - 6, menuBtnH / 2 - 2, 6)
    
    love.graphics.setColor(1, 1, 1)
    if menuFont then
        love.graphics.setFont(menuFont)
    end
    love.graphics.printf("MENU", menuBtnX, menuBtnY + 8, menuBtnW, "center")
    
    controls.draw()
end

function game.touchpressed(id, x, y)
    local screenW, screenH = love.graphics.getDimensions()
    local menuBtnX = screenW - 120
    local menuBtnY = 15
    local menuBtnW = 100
    local menuBtnH = 35
    
    if x >= menuBtnX and x <= menuBtnX + menuBtnW and
       y >= menuBtnY and y <= menuBtnY + menuBtnH then
        playSound("click")
        _G.GameState.current = "lobby"
        return
    end
    
    controls.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then
        playSound("shot")
        
        local bullet = {
            x = cube.x or 0,
            y = cube.y or 0,
            vx = (dx or 0) * 400,
            vy = (dy or 0) * 400
        }
        
        table.insert(bullets, bullet)
    end
end

-- ============================================================
-- ПОДДЕРЖКА КЛАВИАТУРЫ В ИГРЕ
-- ============================================================
function game.keypressed(key)
    if key == "escape" then
        playSound("click")
        _G.GameState.current = "lobby"
        return
    end
    
    -- Передаем в controls
    if controls.keypressed then
        controls.keypressed(key)
    end
end

function game.keyreleased(key)
    if controls.keyreleased then
        local shot, dx, dy = controls.keyreleased(key)
        if shot then
            playSound("shot")
            local bullet = {
                x = cube.x or 0,
                y = cube.y or 0,
                vx = (dx or 0) * 400,
                vy = (dy or 0) * 400
            }
            table.insert(bullets, bullet)
        end
    end
end

function game.setOnDeath(fn)
    game.onDeath = fn
end

function game.setCoins(c)
    coins = c
end

function game.setSkin(s)
    selected_skin = s
end

return game
