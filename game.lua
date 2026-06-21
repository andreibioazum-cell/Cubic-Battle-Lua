local controls = require("controls")
local enemy = require("enemy")
local game = {}

local WORLD_SIZE = 3000
local cube = { x = 1500, y = 1500, speed = 260, hp = 5, angle = 0 }
local cam = { x = 0, y = 0 }
local bullets = {}
local coins = 0
local selected_skin = "default"
local dead = false
local bg = nil
local playerImg = nil
local diamondImg = nil
local uiFont = nil

local abilityActive = false
local abilityTimer = 0
local abilityDuration = 2.5
local isInvulnerable = false

local function saveCoins()
    local data = love.filesystem.read("save.txt")
    if data then
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        lines[1] = tostring(coins)
        love.filesystem.write("save.txt", table.concat(lines, "\n"))
    else
        love.filesystem.write("save.txt", string.format("%d\n%s\n%s", coins, "default", selected_skin))
    end
end

local function safeLoadImage(name, color)
    local success, img = pcall(function()
        return love.graphics.newImage(name)
    end)
    if success and img then
        return img
    else
        local canvas = love.graphics.newCanvas(64, 64)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(color or {1, 1, 1, 1})
        love.graphics.setCanvas()
        return canvas
    end
end

function game.load()
    controls.load()
    uiFont = love.graphics.newFont(14)
    
    cube.x, cube.y = 1500, 1500
    cube.hp = 5
    dead = false
    bullets = {}
    abilityActive = false
    isInvulnerable = false
    
    bg = safeLoadImage("grass.png", {0.2, 0.5, 0.2, 1})
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

    if abilityActive then
        abilityTimer = abilityTimer - dt
        if abilityTimer <= 0 then
            abilityActive = false
            isInvulnerable = false
        end
    end

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
        if b then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if b.x < 0 or b.x > WORLD_SIZE or b.y < 0 or b.y > WORLD_SIZE then
                table.remove(bullets, i)
            end
        end
    end

    enemy.update(dt, cube.x, cube.y, bullets, function(dmg)
        if isInvulnerable then return end
        cube.hp = cube.hp - dmg
        if cube.hp <= 0 then
            dead = true
            if game.onDeath then game.onDeath() end
            _G.GameState.current = "lobby"
        end
    end)
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local sw, sh = love.graphics.getDimensions()
    if bg then
        local tw, th = bg:getWidth() or 64, bg:getHeight() or 64
        for x = math.floor(cam.x / tw) * tw, cam.x + sw, tw do
            for y = math.floor(cam.y / th) * th, cam.y + sh, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end

    enemy.draw()

    love.graphics.setColor(1, 1, 1)
    local img = selected_skin == "diamond" and diamondImg or playerImg
    
    if abilityActive and selected_skin == "diamond" then
        love.graphics.setColor(0.6, 0.2, 1, 0.4)
        love.graphics.circle("fill", cube.x, cube.y, 50)
        love.graphics.setColor(0.8, 0.4, 1, 0.2)
        love.graphics.circle("fill", cube.x, cube.y, 60)
        love.graphics.setColor(0.6, 0.2, 1, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", cube.x, cube.y, 50)
    end
    
    if img then
        local w, h = img:getWidth() or 64, img:getHeight() or 64
        love.graphics.draw(img, cube.x, cube.y, cube.angle, 55/w, 55/h, w/2, h/2)
    end

    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(2)
    local aimX, aimY = controls.getAim()
    love.graphics.line(cube.x, cube.y, cube.x + aimX * 40, cube.y + aimY * 40)

    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, 5)
        love.graphics.setColor(1, 1, 0, 0.2)
        love.graphics.circle("fill", b.x, b.y, 10)
    end
    love.graphics.pop()

    -- UI
    local screenW, screenH = love.graphics.getDimensions()
    
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, screenW, 50)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.rectangle("fill", 0, 48, screenW, 2)
    
    -- HP
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", 20, 22, 10)
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 40, 12, 160, 20, 10)
    
    local hpPercent = cube.hp / 5
    if hpPercent > 0.6 then love.graphics.setColor(0, 1, 0)
    elseif hpPercent > 0.3 then love.graphics.setColor(1, 1, 0)
    else love.graphics.setColor(1, 0, 0) end
    love.graphics.rectangle("fill", 42, 14, 156 * hpPercent, 16, 8)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(uiFont)
    love.graphics.printf(math.ceil(cube.hp) .. "/5", 40, 14, 160, "center")
    
    -- Монеты
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.circle("fill", 225, 19, 10)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(uiFont)
    love.graphics.printf(coins, 242, 12, 100, "left")
    
    -- MENU
    local menuBtnX = screenW - 90
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", menuBtnX + 2, 10, 75, 34, 8)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", menuBtnX, 8, 75, 34, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("MENU", menuBtnX, 16, 75, "center")
    
    controls.draw()
end

function game.touchpressed(id, x, y)
    local screenW, screenH = love.graphics.getDimensions()
    local menuBtnX = screenW - 90
    
    if x >= menuBtnX and x <= menuBtnX + 75 and y >= 8 and y <= 42 then
        playSound("click")
        saveCoins()
        _G.GameState.current = "lobby"
        return
    end
    
    local result = controls.touchpressed(id, x, y)
    if result == "ability" and selected_skin == "diamond" then
        activateAbility()
    end
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    local shot, dx, dy, abilityUsed = controls.touchreleased(id)
    
    if shot then
        playSound("shot")
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0 then dx, dy = dx/len, dy/len else dx, dy = 0, -1 end
        table.insert(bullets, {x = cube.x, y = cube.y, vx = dx * 400, vy = dy * 400})
    end
    
    if abilityUsed and selected_skin == "diamond" then
        activateAbility()
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
        local result = controls.keypressed(key)
        if result == "ability" and selected_skin == "diamond" then
            activateAbility()
        end
    end
end

function game.keyreleased(key)
    if controls.keyreleased then
        local shot, dx, dy, abilityUsed = controls.keyreleased(key)
        if shot then
            playSound("shot")
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then dx, dy = dx/len, dy/len else dx, dy = 0, -1 end
            table.insert(bullets, {x = cube.x, y = cube.y, vx = dx * 400, vy = dy * 400})
        end
        if abilityUsed and selected_skin == "diamond" then
            activateAbility()
        end
    end
end

function activateAbility()
    if selected_skin ~= "diamond" then return end
    if abilityActive then return end
    if not controls.canUseAbility() then return end
    
    abilityActive = true
    abilityTimer = abilityDuration
    isInvulnerable = true
    controls.useAbility()
    playSound("success")
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
