local controls = require("controls")

local game = {}

-- ===== ИГРОК =====
local player = {
    x = 0, y = 0,
    size = 60,
    speed = 220,
    vx = 0, vy = 0,
    accel = 18,
    dirX = 0, dirY = -1
}

-- ===== КАМЕРА =====
local cam = { x = 0, y = 0, smoothness = 12 }
local sand = { img = nil, w = 0, h = 0 }
local fontFps
local walkTimer = 0

-- ===== ЧАСТИЦЫ (Lua) =====
local particles = {}
local particlePool = {}
local MAX_PARTICLES = 3000

local function spawnParticle(x, y, spread, life, size, r, g, b)
    if #particles >= MAX_PARTICLES then return end
    
    local p
    if #particlePool > 0 then
        p = particlePool[#particlePool]
        particlePool[#particlePool] = nil
    else
        p = {}
    end
    
    local angle = math.random() * math.pi * 2
    local speed = math.random() * spread
    
    p.x, p.y = x, y
    p.vx = math.cos(angle) * speed
    p.vy = math.sin(angle) * speed
    p.life = life * (0.5 + math.random() * 0.5)
    p.maxLife = p.life
    p.size = size * (0.7 + math.random() * 0.6)
    p.r, p.g, p.b = r, g, b
    
    particles[#particles + 1] = p
end

local function burstParticles(x, y, count, spread, life, size, r, g, b)
    for i = 1, math.min(count, MAX_PARTICLES - #particles) do
        spawnParticle(x, y, spread, life, size, r, g, b)
    end
end

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
        p.life = p.life - dt
        
        if p.life <= 0 then
            if #particlePool < 500 then
                particlePool[#particlePool + 1] = p
            end
            particles[i] = particles[#particles]
            particles[#particles] = nil
        end
    end
end

local function drawParticles()
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.r, p.g, p.b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
end

function game.load()
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    cam.x, cam.y = 0, 0
    particles = {}
    particlePool = {}
    
    if not sand.img then
        local ok, img = pcall(love.graphics.newImage, "sand.png", {mipmaps=true})
        if ok then
            sand.img = img
            sand.img:setWrap("repeat", "repeat")
            sand.img:setFilter("linear", "linear", 2)
            sand.w, sand.h = sand.img:getWidth(), sand.img:getHeight()
        end
    end
    
    controls.load()
    fontFps = fontFps or love.graphics.newFont(14)
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    controls.reposition()
    
    local inputX, inputY = controls.getMoveDir()
    local isMoving = (inputX ~= 0 or inputY ~= 0)
    
    if isMoving then
        player.vx = player.vx + (inputX * player.speed - player.vx) * player.accel * dt
        player.vy = player.vy + (inputY * player.speed - player.vy) * player.accel * dt
        local len = math.sqrt(inputX*inputX + inputY*inputY)
        if len > 0.1 then
            player.dirX, player.dirY = inputX/len, inputY/len
        end
        
        walkTimer = walkTimer + dt
        if walkTimer > 0.08 then
            walkTimer = 0
            spawnParticle(
                player.x - player.dirX * 20,
                player.y - player.dirY * 20 + player.size/3,
                20, 0.4, 4, 0.9, 0.8, 0.4
            )
        end
    else
        player.vx, player.vy = 0, 0
        walkTimer = 0
    end
    
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    
    cam.x = cam.x + (player.x - w/2 - cam.x) * cam.smoothness * dt
    cam.y = cam.y + (player.y - h/2 - cam.y) * cam.smoothness * dt
    
    updateParticles(dt)
    controls.update(dt, player.dirX, player.dirY)
end

function game.draw()
    local w, h = love.graphics.getDimensions()
    
    if sand.img then
        love.graphics.setColor(1, 1, 1, 1)
        local offX = -(cam.x % sand.w)
        local offY = -(cam.y % sand.h)
        local cols = math.ceil(w / sand.w) + 1
        local rows = math.ceil(h / sand.h) + 1
        for r = 0, rows do
            for col = 0, cols do
                love.graphics.draw(sand.img, offX + col * sand.w, offY + r * sand.h)
            end
        end
    else
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end
    
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)
    
    drawParticles()
    controls.drawWorld(player.x, player.y)
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", player.x - player.size/2 + 4, player.y - player.size/2 + 4, 
        player.size, player.size, 10, 10)
    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, 
        player.size, player.size, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", player.x - player.size/2, player.y - player.size/2, 
        player.size, player.size, 10, 10)
    
    love.graphics.pop()
    
    controls.drawUI()
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(fontFps)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

local origTouchReleased = controls.touchreleased
controls.touchreleased = function(id, x, y)
    local hadBullets = #controls.bullets
    origTouchReleased(id, x, y)
    if #controls.bullets > hadBullets then
        local b = controls.bullets[#controls.bullets]
        burstParticles(b.x, b.y, 12, 40, 0.15, 6, 1, 0.9, 0.3)
    end
end

function game.touchpressed(id, x, y)
    local action = controls.touchpressed(id, x, y, player.dirX, player.dirY)
    if action == "back" then GameState.current = "lobby" end
end

function game.touchmoved(id, x, y) controls.touchmoved(id, x, y) end
function game.touchreleased(id, x, y) controls.touchreleased(id, player.x, player.y) end

return game
