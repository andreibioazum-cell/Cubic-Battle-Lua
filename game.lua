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
local bg = nil
local playerImg = nil
local diamondImg = nil
local menuFont = nil
local uiFont = nil

-- Функция сохранения монет
local function saveCoins()
    local data = love.filesystem.read("save.txt")
    if data then
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        lines[1] = tostring(coins)
        local newData = table.concat(lines, "\n")
        love.filesystem.write("save.txt", newData)
    else
        local data = string.format("%d\n%s\n%s", coins, "default", selected_skin)
        love.filesystem.write("save.txt", data)
    end
end

local function safeLoadImage(name, fallbackColor)
    local success, img = pcall(function()
        return love.graphics.newImage(name)
    end)
    if success and img then
        return img
    else
        local canvas = love.graphics.newCanvas(64, 64)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(fallbackColor or {1, 1, 1, 1})
        love.graphics.setCanvas()
        return canvas
    end
end

function game.load()
    controls.load()
    
    menuFont = love.graphics.newFont(16)
    uiFont = love.graphics.newFont(14)
    
    cube.x, cube.y = 1500, 1500
    cube.hp = 5
    dead = false
    bullets = {}
    
    bg = safeLoadImage("grass.png", {0.2, 0.5, 0.2, 1})
    if bg.setWrap then
        bg:setWrap("repeat", "repeat")
    end
    
    playerImg = safeLoadImage("player.png", {0, 0.5, 1, 1})
    diamondImg = safeLoadImage("player_diamond.png", {0, 1, 1, 1})
    
    enemy.load()
    enemy.reset()
    enemy.spawnNow(cube.x + 300, cube.y + 300)
    enemy.setDeathCallback(function()
        coins = coins + 50
        saveCoins()
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
    local tw = bg and bg:getWidth() or 64
    local th = bg and bg:getHeight() or 64
    
    if bg then
        for x = math.floor(cam.x / tw) * tw, cam.x + sw, tw do
            for y = math.floor(cam.y / th) * th, cam.y + sh, th do
                love.graphics.draw(bg, x, y)
            end
        end
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
        love.graphics.rectangle("fill", 0, 0, WORLD_SIZE, WORLD_SIZE)
    end

    enemy.draw()

    love.graphics.setColor(1, 1, 1)
    local img = selected_skin == "diamond" and diamondImg or playerImg
    if img then
        local w = img:getWidth() or 64
        local h = img:getHeight() or 64
        love.graphics.draw(
            img, cube.x, cube.y,
            cube.angle,
            55 / w, 55 / h,
            w / 2, h / 2
        )
    else
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.rectangle("fill", cube.x - 27, cube.y - 27, 54, 54)
    end

    -- Линия направления
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(2)
    local aimX, aimY = controls.getAim()
    local len = 40
    love.graphics.line(
        cube.x, cube.y,
        cube.x + aimX * len,
        cube.y + aimY * len
    )

    -- Пули
    for _, b in ipairs(bullets) do
        if b and type(b.x) == "number" and type(b.y) == "number" then
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", b.x, b.y, 5)
            love.graphics.setColor(1, 1, 0, 0.2)
            love.graphics.circle("fill", b.x, b.y, 10)
        end
    end
    love.graphics.pop()

    -- ============================================================
    -- УЛУЧШЕННЫЙ UI (БЕЗ ЭМОДЗИ)
    -- ============================================================
    local screenW, screenH = love.graphics.getDimensions()
    
    -- Верхняя панель
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, screenW, 65)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.rectangle("fill", 0, 63, screenW, 2)
    
    -- HP Бар
    -- Иконка сердца (рисуем вручную)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", 30, 22, 8)
    love.graphics.circle("fill", 44, 22, 8)
    love.graphics.polygon("fill",
        30, 18,
        37, 30,
        44, 18
    )
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 58, 12, 150, 20, 10)
    
    local hpPercent = cube.hp / 5
    if hpPercent > 0.6 then
        love.graphics.setColor(0, 1, 0)
    elseif hpPercent > 0.3 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", 58, 12, 150 * hpPercent, 20, 10)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 58, 12, 150, 20, 10)
    
    -- Текст HP
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(uiFont or love.graphics.newFont(12))
    love.graphics.printf(math.ceil(cube.hp) .. "/5", 58, 15, 150, "center")
    
    -- Монеты (БЕЗ ЭМОДЗИ)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(uiFont or love.graphics.newFont(16))
    love.graphics.printf("COINS: " .. coins, 230, 8, 200, "left")
    
    -- Рисуем монетку (круг)
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.circle("fill", 220, 18, 10)
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.circle("fill", 220, 18, 6)
    love.graphics.setColor(1, 0.7, 0)
    love.graphics.circle("fill", 220, 18, 3)
    
    -- Название скина
    if selected_skin == "diamond" then
        love.graphics.setColor(0, 1, 1)
        love.graphics.setFont(uiFont or love.graphics.newFont(14))
        love.graphics.printf("DIAMOND", screenW - 180, 10, 150, "left")
        -- Рисуем бриллиант
        love.graphics.setColor(0, 1, 1)
        love.graphics.polygon("fill",
            screenW - 190, 18,
            screenW - 185, 10,
            screenW - 175, 10,
            screenW - 170, 18,
            screenW - 180, 30
        )
    end
    
    -- КНОПКА MENU
    local menuBtnX = screenW - 100
    local menuBtnY = 10
    local menuBtnW = 85
    local menuBtnH = 40
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", menuBtnX + 2, menuBtnY + 2, menuBtnW, menuBtnH, 10)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", menuBtnX, menuBtnY, menuBtnW, menuBtnH, 10)
    love.graphics.setColor(1, 0.3, 0.3, 0.2)
    love.graphics.rectangle("fill", menuBtnX + 3, menuBtnY + 3, menuBtnW - 6, 15, 8)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(menuFont or love.graphics.newFont(14))
    love.graphics.printf("MENU", menuBtnX, menuBtnY + 12, menuBtnW, "center")
    
    -- Нижняя панель
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, screenH - 30, screenW, 30)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(uiFont or love.graphics.newFont(12))
    love.graphics.printf("WASD - Move | SPACE - Attack | ESC - Menu", 10, screenH - 24, screenW - 20, "center")
    
    controls.draw()
end

function game.touchpressed(id, x, y)
    local screenW, screenH = love.graphics.getDimensions()
    local menuBtnX = screenW - 100
    local menuBtnY = 10
    local menuBtnW = 85
    local menuBtnH = 40
    
    if x >= menuBtnX and x <= menuBtnX + menuBtnW and
       y >= menuBtnY and y <= menuBtnY + menuBtnH then
        playSound("click")
        saveCoins()
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
        
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then
            dx = dx / len
            dy = dy / len
        else
            dx, dy = 0, -1
        end
        
        local bullet = {
            x = cube.x or 0,
            y = cube.y or 0,
            vx = dx * 400,
            vy = dy * 400
        }
        
        table.insert(bullets, bullet)
    end
end

function game.keypressed(key)
    if key == "escape" then
        playSound("click")
        saveCoins()
        _G.GameState.current = "lobby"
        return
    end
    
    if controls.keypressed then
        controls.keypressed(key)
    end
end

function game.keyreleased(key)
    if controls.keyreleased then
        local shot, dx, dy = controls.keyreleased(key)
        if shot then
            playSound("shot")
            
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                dx = dx / len
                dy = dy / len
            else
                dx, dy = 0, -1
            end
            
            local bullet = {
                x = cube.x or 0,
                y = cube.y or 0,
                vx = dx * 400,
                vy = dy * 400
            }
            table.insert(bullets, bullet)
        end
    end
end

function game.setOnDeath(fn)
    game.onDeath = fn
end

function game.setCoins(c)
    coins = c or 0
end

function game.setSkin(s)
    selected_skin = s or "default"
end

return game
