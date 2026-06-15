local controls = require("controls")

local game = {}

local player = {
    x = 0, y = 0,
    size = 60,
    speed = 220,
    vx = 0, vy = 0,
    accel = 18,
    dirX = 0, dirY = -1
}

local cam = { x = 0, y = 0, smooth = 12 }

local sandTex, sandW, sandH

local particles = {}
local pool = {}
local MAX = 3000

local fpsFont
local walkCd = 0

local function spawn(x, y, spread, life, size, r, g, b)
    if #particles >= MAX then return end

    local p
    if #pool > 0 then
        p = pool[#pool]
        pool[#pool] = nil
    else
        p = {}
    end

    local a = math.random() * math.pi * 2
    local s = math.random() * spread

    p.x = x
    p.y = y
    p.vx = math.cos(a) * s
    p.vy = math.sin(a) * s
    p.life = life * (0.5 + math.random() * 0.5)
    p.maxLife = p.life
    p.size = size * (0.7 + math.random() * 0.6)
    p.r = r
    p.g = g
    p.b = b

    particles[#particles + 1] = p
end

local function burst(x, y, count, spread, life, size, r, g, b)
    for i = 1, math.min(count, MAX - #particles) do
        spawn(x, y, spread, life, size, r, g, b)
    end
end

local function updateParts(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = p.vx * 0.98
        p.vy = p.vy * 0.98
        p.life = p.life - dt

        if p.life <= 0 then
            if #pool < 500 then
                pool[#pool + 1] = p
            end
            particles[i] = particles[#particles]
            particles[#particles] = nil
        end
    end
end

local function drawParts()
    for _, p in ipairs(particles) do
        local a = p.life / p.maxLife
        love.graphics.setColor(p.r, p.g, p.b, a)
        love.graphics.circle("fill", p.x, p.y, p.size * a)
    end
end

function game.load()
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    cam.x, cam.y = 0, 0
    particles = {}
    pool = {}

    if not sandTex then
        local ok, img = pcall(love.graphics.newImage, "sand.png", { mipmaps = true })
        if ok then
            sandTex = img
            sandTex:setWrap("repeat", "repeat")
            sandTex:setFilter("linear", "linear", 2)
            sandW = sandTex:getWidth()
            sandH = sandTex:getHeight()
        end
    end

    controls.load()
    fpsFont = fpsFont or love.graphics.newFont(14)
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    controls.reposition()

    local ix, iy = controls.getMoveDir()
    local moving = (ix ~= 0 or iy ~= 0)

    if moving then
        player.vx = player.vx + (ix * player.speed - player.vx) * player.accel * dt
        player.vy = player.vy + (iy * player.speed - player.vy) * player.accel * dt

        local len = math.sqrt(ix * ix + iy * iy)
        if len > 0.1 then
            player.dirX = ix / len
            player.dirY = iy / len
        end

        walkCd = walkCd + dt
        if walkCd > 0.08 then
            walkCd = 0
            spawn(player.x - player.dirX * 20,
                  player.y - player.dirY * 20 + player.size / 3,
                  20, 0.4, 4, 0.9, 0.8, 0.4)
        end
    else
        player.vx = 0
        player.vy = 0
        walkCd = 0
    end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    cam.x = cam.x + (player.x - w / 2 - cam.x) * cam.smooth * dt
    cam.y = cam.y + (player.y - h / 2 - cam.y) * cam.smooth * dt

    updateParts(dt)
    controls.update(dt, player.dirX, player.dirY)
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    if sandTex then
        love.graphics.setColor(1, 1, 1, 1)
        local ox = -(cam.x % sandW)
        local oy = -(cam.y % sandH)
        local cols = math.ceil(w / sandW) + 1
        local rows = math.ceil(h / sandH) + 1

        for row = 0, rows do
            for col = 0, cols do
                love.graphics.draw(sandTex, ox + col * sandW, oy + row * sandH)
            end
        end
    else
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    drawParts()
    controls.drawWorld(player.x, player.y)

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill",
        player.x - player.size / 2 + 4,
        player.y - player.size / 2 + 4,
        player.size, player.size, 10, 10)

    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.rectangle("fill",
        player.x - player.size / 2,
        player.y - player.size / 2,
        player.size, player.size, 10, 10)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",
        player.x - player.size / 2,
        player.y - player.size / 2,
        player.size, player.size, 10, 10)

    love.graphics.pop()

    controls.drawUI()

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(fpsFont)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

local origRelease = controls.touchreleased
controls.touchreleased = function(id, x, y)
    local n = #controls.bullets
    origRelease(id, x, y)
    if #controls.bullets > n then
        local b = controls.bullets[#controls.bullets]
        burst(b.x, b.y, 12, 40, 0.15, 6, 1, 0.9, 0.3)
    end
end

function game.touchpressed(id, x, y)
    local act = controls.touchpressed(id, x, y, player.dirX, player.dirY)
    if act == "back" then
        GameState.current = "lobby"
    end
end

function game.touchmoved(id, x, y)
    controls.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    controls.touchreleased(id, player.x, player.y)
end

return game
