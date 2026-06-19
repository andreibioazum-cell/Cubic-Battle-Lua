local controls = require("controls")
local enemy = require("enemy")
local game = {}

local PLAYER_SIZE = 55
local cube = { x = 0, y = 0, speed = 260, angle = 0, hp = 5, maxHp = 5, hit = 0 }
local bullets = {}
local cam = { x = 0, y = 0 }
local playerImg, font

function game.load()
    playerImg = love.graphics.newImage("player.png")
    font = love.graphics.newFont("Fredoka-Bold.ttf", 22)
    cube.hp = cube.maxHp
    bullets = {}
    controls.load()
    enemy.load()
    enemy.reset()
end

local function drawHPBar(x, y, w, h, hp, max)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x-2, y-2, w+4, h+4, 5)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, w * (hp/max), h, 3)
end

function game.update(dt)
    controls.update(dt)
    local dx, dy = controls.getMove()
    cube.x, cube.y = cube.x + dx * cube.speed * dt, cube.y + dy * cube.speed * dt
    if dx ~= 0 or dy ~= 0 then cube.angle = math.atan2(dy, dx) + math.pi/2 end
    
    local tw, th = love.graphics.getDimensions()
    cam.x = cam.x + (cube.x - tw/2 - cam.x) * dt * 8
    cam.y = cam.y + (cube.y - th/2 - cam.y) * dt * 8

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
        b.life = b.life - dt
        if b.life < 0 then table.remove(bullets, i) end
    end

    enemy.update(dt, cube.x, cube.y, bullets, function(dmg)
        cube.hp = cube.hp - dmg
        if cube.hp <= 0 then GameState.current = "lobby" end
    end)
end

function game.draw()
    love.graphics.clear(0.2, 0.2, 0.2)
    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    -- Пули игрока (ЧЁРНЫЕ)
    love.graphics.setColor(0, 0, 0)
    for _, b in ipairs(bullets) do love.graphics.circle("fill", b.x, b.y, 8) end

    enemy.draw()

    -- Игрок + Тень (КРУТИТСЯ ВМЕСТЕ)
    love.graphics.push()
    love.graphics.translate(cube.x, cube.y)
    love.graphics.rotate(cube.angle)
    -- Тень СТРОГО ниже игрока
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.draw(playerImg, -PLAYER_SIZE/2 + 5, -PLAYER_SIZE/2 + 5)
    -- Сам игрок
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
    love.graphics.pop()

    love.graphics.pop()

    -- ХП Игрока
    drawHPBar(love.graphics.getWidth() - 220, 30, 200, 15, cube.hp, cube.maxHp)
    
    -- Кнопка EXIT (стиль как в лобби)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 24, 24, 180, 50, 14, 14)
    love.graphics.setColor(0.45, 0.15, 0.75)
    love.graphics.rectangle("fill", 20, 20, 180, 50, 14, 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("EXIT", 20, 32, 180, "center")

    controls.draw()
end

function game.touchpressed(id, x, y)
    if x > 20 and x < 200 and y > 20 and y < 70 then GameState.current = "lobby" end
    controls.touchpressed(id, x, y)
end
function game.touchreleased(id)
    local s, dx, dy = controls.touchreleased(id)
    if s then table.insert(bullets, {x=cube.x, y=cube.y, vx=dx*400, vy=dy*400, life=2}) end
end
function game.touchmoved(id, x, y) controls.touchmoved(id, x, y) end
function game.setOnlineMode(m) end
return game
