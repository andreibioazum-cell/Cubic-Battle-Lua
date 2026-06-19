local controls = require("controls")
local enemy = require("enemy")

local game = {}

local PLAYER_SIZE = 55
local PLAYER_HP_MAX = 5
local BULLET_SPEED = 400

local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = PLAYER_HP_MAX, hit = 0 }
local bullets = {}
local bg, playerImg, font
local cam = { x = 0, y = 0 }
local dead = false

local exitBtn = { x = 30, y = 30, w = 210, h = 55 }

local function spawnBullet(x, y, dx, dy)
    local offset = PLAYER_SIZE * 0.6
    table.insert(bullets, {
        x = x + dx * offset,
        y = y + dy * offset,
        vx = dx * BULLET_SPEED,
        vy = dy * BULLET_SPEED,
        life = 3
    })
end

function game.setOnDeath(callback) end
function game.setOnlineMode(enabled) end

function game.load()
    cube.x, cube.y = 0, 0
    cube.hp = PLAYER_HP_MAX
    cube.hit = 0
    dead = false
    bullets = {}
    
    bg = love.graphics.newImage("grass.png")
    bg:setWrap("repeat", "repeat")
    playerImg = love.graphics.newImage("player.png")
    playerImg:setFilter("nearest", "nearest")
    font = love.graphics.newFont("Fredoka-Bold.ttf", 20)

    controls.load()
    enemy.load()
    enemy.reset()
end

function game.update(dt)
    if dead then return end
    controls.update(dt)

    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx) + math.pi / 2
    end
    cube.hit = math.max(0, cube.hit - dt * 3)

    -- Плавная камера
    local targetX = cube.x - love.graphics.getWidth() / 2
    local targetY = cube.y - love.graphics.getHeight() / 2
    cam.x = cam.x + (targetX - cam.x) * (1 - math.exp(-dt * 8))
    cam.y = cam.y + (targetY - cam.y) * (1 - math.exp(-dt * 8))

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets, i) end
    end

    enemy.update(dt, cube.x, cube.y, bullets, function(dmg)
        cube.hp = cube.hp - dmg
        cube.hit = 1
        if cube.hp <= 0 then GameState.current = "lobby" end
    end)
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    -- Фон
    love.graphics.setColor(1, 1, 1)
    local w, h = love.graphics.getDimensions()
    local tw, th = bg:getWidth(), bg:getHeight()
    for x = math.floor(cam.x/tw)*tw, cam.x+w+tw, tw do
        for y = math.floor(cam.y/th)*th, cam.y+h+th, th do
            love.graphics.draw(bg, x, y)
        end
    end

    -- Пули игрока (ЧЁРНЫЕ)
    for _, b in ipairs(bullets) do
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.circle("fill", b.x, b.y, 9)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", b.x, b.y, 6)
    end

    enemy.draw()

    -- Игрок
    love.graphics.push()
    love.graphics.translate(cube.x, cube.y)
    love.graphics.rotate(cube.angle)
    love.graphics.setColor(1, 1 - cube.hit, 1 - cube.hit)
    love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
    love.graphics.pop()

    love.graphics.pop()

    -- Кнопка EXIT (стиль как в лобби)
    local bx, by, bw, bh = exitBtn.x, exitBtn.y, exitBtn.w, exitBtn.h
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 4, by + 4, bw, bh, 15, 15)
    love.graphics.setColor(0.45, 0.15, 0.75, 1)
    love.graphics.rectangle("fill", bx, by, bw, bh, 15, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("BACK TO MENU", bx, by + bh/2 - 12, bw, "center")

    controls.draw()
end

function game.touchpressed(id, x, y)
    if x >= exitBtn.x and x <= exitBtn.x + exitBtn.w and y >= exitBtn.y and y <= exitBtn.y + exitBtn.h then
        GameState.current = "lobby"
        return
    end
    controls.touchpressed(id, x, y)
end

function game.touchreleased(id)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then spawnBullet(cube.x, cube.y, dx, dy) end
end

function game.touchmoved(id, x, y) controls.touchmoved(id, x, y) end
function game.resize() controls.resize() end

return game
