local controls = require("controls")
local online = require("online")

local game = {}

local player = {
    x = 0, y = 0,
    size = 60,
    speed = 220,
    vx = 0, vy = 0,
    accel = 18,
    dirX = 0, dirY = -1,
    hp = 5
}

local cam = { x = 0, y = 0, smooth = 12 }

local sandTex, sandW, sandH

local particles = {}
local pool = {}
local MAX = 3000

local enemies = {}
local boss = nil
local wave = 1
local score = 0
local mode = "normal"
local bossTimer = 0
local spawnTimer = 0
local enemyPlayer = nil
local enemyBullets = {}

local fpsFont

local function spawnParticle(x, y, spread, life, size, r, g, b)
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

local function burstParticles(x, y, count, spread, life, size, r, g, b)
    for i = 1, math.min(count, MAX - #particles) do
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
            if #pool < 500 then pool[#pool + 1] = p end
            particles[i] = particles[#particles]
            particles[#particles] = nil
        end
    end
end

local function drawParticles()
    for _, p in ipairs(particles) do
        local a = p.life / p.maxLife
        love.graphics.setColor(p.r, p.g, p.b, a)
        love.graphics.circle("fill", p.x, p.y, p.size * a)
    end
end

local function spawnEnemy()
    local e = {
        x = player.x + (math.random() - 0.5) * 800,
        y = player.y + (math.random() - 0.5) * 800,
        size = 40,
        hp = 2 + wave,
        speed = 80 + wave * 20,
        damage = 1
    }
    enemies[#enemies + 1] = e
end

local function spawnBoss()
    boss = {
        x = player.x + 300,
        y = player.y - 200,
        size = 100,
        hp = 20 + wave * 10,
        speed = 50,
        damage = 2,
        timer = 0
    }
end

local function hitEnemy(enemy, damage)
    enemy.hp = enemy.hp - damage
    burstParticles(enemy.x, enemy.y, 8, 30, 0.3, 5, 1, 0.6, 0.1)
    if enemy.hp <= 0 then
        burstParticles(enemy.x, enemy.y, 20, 60, 0.5, 8, 1, 0.3, 0)
        score = score + 100
        return true
    end
    return false
end

function game.setMode(m)
    mode = m
    game.reset()
    if m == "online" then
        online.joinGame()
    end
end

function game.reset()
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    player.hp = 5
    cam.x, cam.y = 0, 0
    enemies = {}
    boss = nil
    wave = 1
    score = 0
    bossTimer = 0
    spawnTimer = 0
    enemyPlayer = nil
    enemyBullets = {}
    particles = {}
    pool = {}
    if mode == "online" then
        online.leaveRoom()
    end
end

function game.load()
    player.x, player.y = 0, 0
    player.vx, player.vy = 0, 0
    cam.x, cam.y = 0, 0
    enemies = {}
    boss = nil
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

    if player.hp <= 0 then
        updateParticles(dt)
        controls.update(dt, player.dirX, player.dirY)
        return
    end

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
        if math.random() < 0.5 then
            spawnParticle(player.x - player.dirX * 20,
                player.y - player.dirY * 20 + player.size / 3,
                20, 0.4, 4, 0.9, 0.8, 0.4)
        end
    else
        player.vx = 0
        player.vy = 0
    end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    cam.x = cam.x + (player.x - w / 2 - cam.x) * cam.smooth * dt
    cam.y = cam.y + (player.y - h / 2 - cam.y) * cam.smooth * dt

    if mode == "online" then
        online.sendPlayer(player.x, player.y, player.hp, player.dirX, player.dirY)
        online.sendBullets(controls.bullets)
        enemyPlayer = online.getEnemy()
        enemyBullets = online.getEnemyBullets()

        if enemyPlayer then
            for _, b in pairs(enemyBullets or {}) do
                local dx = player.x - (b.x or 0)
                local dy = player.y - (b.y or 0)
                if dx * dx + dy * dy < (player.size / 2) ^ 2 then
                    player.hp = player.hp - 1
                    burstParticles(player.x, player.y, 15, 40, 0.4, 6, 1, 0.2, 0.2)
                end
            end
        end
    end

    if mode == "normal" then
        spawnTimer = spawnTimer + dt
        if spawnTimer > 1.5 and #enemies < 5 + wave then
            spawnTimer = 0
            spawnEnemy()
        end

        if #enemies == 0 and not boss then
            bossTimer = bossTimer + dt
            if bossTimer > 2 then
                spawnBoss()
                bossTimer = 0
            end
        end
    end

    for _, e in ipairs(enemies) do
        local dx = player.x - e.x
        local dy = player.y - e.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 0 then
            e.x = e.x + (dx / d) * e.speed * dt
            e.y = e.y + (dy / d) * e.speed * dt
        end
        if d < player.size / 2 + e.size / 2 then
            player.hp = player.hp - e.damage
            burstParticles(player.x, player.y, 15, 40, 0.4, 6, 1, 0.2, 0.2)
            e.hp = 0
        end
    end

    if boss then
        local dx = player.x - boss.x
        local dy = player.y - boss.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 0 then
            boss.x = boss.x + (dx / d) * boss.speed * dt
            boss.y = boss.y + (dy / d) * boss.speed * dt
        end
        boss.timer = boss.timer + dt
        if boss.timer > 2 then
            boss.timer = 0
            burstParticles(boss.x, boss.y, 10, 50, 0.5, 8, 0.8, 0.2, 0.8)
        end
        if d < player.size / 2 + boss.size / 2 then
            player.hp = player.hp - boss.damage
            burstParticles(player.x, player.y, 20, 50, 0.5, 8, 1, 0.1, 0.1)
        end
    end

    for _, b in ipairs(controls.bullets) do
        for i = #enemies, 1, -1 do
            local dx = b.x - enemies[i].x
            local dy = b.y - enemies[i].y
            if dx * dx + dy * dy < (6 + enemies[i].size / 2) ^ 2 then
                if hitEnemy(enemies[i], 1) then
                    table.remove(enemies, i)
                end
                b.life = 0
                break
            end
        end

        if boss and b.life > 0 then
            local dx = b.x - boss.x
            local dy = b.y - boss.y
            if dx * dx + dy * dy < (6 + boss.size / 2) ^ 2 then
                boss.hp = boss.hp - 1
                burstParticles(boss.x, boss.y, 6, 30, 0.3, 5, 1, 0.6, 0.1)
                b.life = 0
                if boss.hp <= 0 then
                    burstParticles(boss.x, boss.y, 40, 100, 0.8, 12, 1, 0.2, 0)
                    score = score + 500
                    boss = nil
                    wave = wave + 1
                end
            end
        end

        if mode == "online" and enemyPlayer and b.life > 0 then
            local dx = b.x - (enemyPlayer.x or 0)
            local dy = b.y - (enemyPlayer.y or 0)
            if dx * dx + dy * dy < 900 then
                burstParticles(enemyPlayer.x or 0, enemyPlayer.y or 0, 12, 40, 0.3, 6, 0.2, 0.5, 0.9)
                score = score + 50
                b.life = 0
            end
        end
    end

    updateParticles(dt)
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

    drawParticles()
    controls.drawWorld(player.x, player.y)

    if mode == "online" and enemyPlayer then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", enemyPlayer.x - 30 + 4, enemyPlayer.y - 30 + 4, 60, 60, 10, 10)
        love.graphics.setColor(0.2, 0.5, 0.9)
        love.graphics.rectangle("fill", enemyPlayer.x - 30, enemyPlayer.y - 30, 60, 60, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", enemyPlayer.x - 30, enemyPlayer.y - 30, 60, 60, 10, 10)

        for _, b in pairs(enemyBullets or {}) do
            love.graphics.setColor(1, 0.3, 0.3, 1)
            love.graphics.circle("fill", b.x or 0, b.y or 0, 6)
        end
    end

    for _, e in ipairs(enemies) do
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", e.x - e.size/2 + 3, e.y - e.size/2 + 3, e.size, e.size, 8, 8)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.rectangle("fill", e.x - e.size/2, e.y - e.size/2, e.size, e.size, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", e.x - e.size/2, e.y - e.size/2, e.size, e.size, 8, 8)
    end

    if boss then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", boss.x - boss.size/2 + 4, boss.y - boss.size/2 + 4,
            boss.size, boss.size, 14, 14)
        love.graphics.setColor(0.8, 0.1, 0.3)
        love.graphics.rectangle("fill", boss.x - boss.size/2, boss.y - boss.size/2,
            boss.size, boss.size, 14, 14)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", boss.x - boss.size/2, boss.y - boss.size/2,
            boss.size, boss.size, 14, 14)
    end

    if player.hp > 0 then
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
    end

    love.graphics.pop()

    controls.drawUI()

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(fpsFont)
    love.graphics.print("Score: " .. score, 20, 70)
    love.graphics.print("HP: " .. string.rep("♥ ", player.hp), 20, 90)
    if mode ~= "online" then
        love.graphics.print("Wave: " .. wave, 20, 110)
    else
        love.graphics.print("Online PvP", 20, 110)
    end
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)

    if player.hp <= 0 then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.print("GAME OVER", w/2 - 100, h/2 - 20)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Score: " .. score, w/2 - 50, h/2 + 30)
        love.graphics.print("Tap to menu", w/2 - 45, h/2 + 55)
    end
end

local origRelease = controls.touchreleased
controls.touchreleased = function(id, x, y)
    local n = #controls.bullets
    origRelease(id, x, y)
    if #controls.bullets > n then
        local b = controls.bullets[#controls.bullets]
        burstParticles(b.x, b.y, 12, 40, 0.15, 6, 1, 0.9, 0.3)
    end
end

function game.touchpressed(id, x, y)
    if player.hp <= 0 then
        game.reset()
        GameState.current = "lobby"
        return
    end
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
