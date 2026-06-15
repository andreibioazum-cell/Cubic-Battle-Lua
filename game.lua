local controls = require("controls")

local game = {}

local cube = {
    x=0, y=0, size=60, speed=260,
    color={1,0.5,0.3},
    angle=0
}

local bullets = {}
local bg
local cam = { x=0, y=0 }

local BULLET_SPEED = 340 * 1.15

local function spawnBullet(x,y,dx,dy)
    table.insert(bullets, {
        x=x, y=y,
        vx=dx*BULLET_SPEED,
        vy=dy*BULLET_SPEED,
        life=3
    })
end

function game.load()
    cube.x = 0
    cube.y = 0
    bg = love.graphics.newImage("grass.png")
    bg:setWrap("repeat","repeat")
    controls.load()
end

function game.resize()
    controls.resize()
end

function game.update(dt)
    controls.update(dt)

    local dx, dy = controls.getMove()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt

    if dx ~= 0 or dy ~= 0 then
        cube.angle = math.atan2(dy, dx)
    end

    local targetX = cube.x - love.graphics.getWidth()/2
    local targetY = cube.y - love.graphics.getHeight()/2
    local k = 1 - math.exp(-dt * 6)
    cam.x = cam.x + (targetX - cam.x) * k
    cam.y = cam.y + (targetY - cam.y) * k

    for i=#bullets,1,-1 do
        local b = bullets[i]
        b.x = b.x + b.vx*dt
        b.y = b.y + b.vy*dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets,i) end
    end
end

function game.draw()
    love.graphics.setColor(1,1,1,1)

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local w,h = love.graphics.getDimensions()
    local tw,th = bg:getWidth(), bg:getHeight()
    local startX = math.floor(cam.x/tw)*tw
    local startY = math.floor(cam.y/th)*th

    for x=startX, startX+w+tw, tw do
        for y=startY, startY+h+th, th do
            love.graphics.draw(bg, x, y)
        end
    end

    love.graphics.setColor(0,0,0,1)
    for _,b in ipairs(bullets) do
        love.graphics.circle("fill", b.x, b.y, 8)
    end

    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.setLineWidth(6)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + ax*140,
            cube.y + ay*140
        )
        love.graphics.setLineWidth(2)
    end

    love.graphics.push()
    love.graphics.translate(cube.x, cube.y)
    love.graphics.rotate(cube.angle)
    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill",
        -cube.size/2, -cube.size/2,
        cube.size, cube.size, 10, 10)
    love.graphics.setColor(0,0,0,1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        -cube.size/2, -cube.size/2,
        cube.size, cube.size, 10, 10)
    love.graphics.pop()

    love.graphics.pop()

    love.graphics.setColor(1,1,1,1)
    controls.draw()
end

function game.touchpressed(id,x,y)
    controls.touchpressed(id,x,y)
end

function game.touchmoved(id,x,y)
    controls.touchmoved(id,x,y)
end

function game.touchreleased(id,x,y)
    local shot, dx, dy = controls.touchreleased(id)
    if shot then
        spawnBullet(cube.x, cube.y, dx, dy)
    end
end

return game
