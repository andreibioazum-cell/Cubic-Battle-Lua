local controls = require("controls")

local game = {}

local cube = { x=0,y=0,size=60,speed=260,color={1,0.5,0.3} }
local bullets = {}
local bg
local cam = { x=0,y=0 }

local function spawnBullet(x,y,dx,dy)
    table.insert(bullets,{
        x=x,y=y,
        vx=dx*360,
        vy=dy*360,
        life=3
    })
end

function game.load()
    cube.x=0
    cube.y=0
    bg=love.graphics.newImage("grass.png")
    bg:setWrap("repeat","repeat")
    controls.load()
end

function game.resize()
    controls.resize()
end

function game.update(dt)

    local dx,dy = controls.getMove()
    cube.x = cube.x + dx*cube.speed*dt
    cube.y = cube.y + dy*cube.speed*dt

    cam.x = cube.x - love.graphics.getWidth()/2
    cam.y = cube.y - love.graphics.getHeight()/2

    for i=#bullets,1,-1 do
        local b=bullets[i]
        b.x=b.x+b.vx*dt
        b.y=b.y+b.vy*dt
        b.life=b.life-dt
        if b.life<=0 then table.remove(bullets,i) end
    end
end

function game.draw()

    love.graphics.push()
    love.graphics.translate(-cam.x,-cam.y)

    local w,h = love.graphics.getDimensions()
    local tw,th = bg:getWidth(),bg:getHeight()

    local startX = math.floor(cam.x/tw)*tw
    local startY = math.floor(cam.y/th)*th

    for x=startX,startX+w+tw,tw do
        for y=startY,startY+h+th,th do
            love.graphics.draw(bg,x,y)
        end
    end

    -- прицел и пули ПОД игроком
    local dx,dy,hold = controls.getMove()
    if hold then
        love.graphics.setColor(0,0,0,0.3)
    end

    for _,b in ipairs(bullets) do
        love.graphics.setColor(0,0,0,1)
        love.graphics.circle("fill",b.x,b.y,8)
    end

    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill",
        cube.x-cube.size/2,
        cube.y-cube.size/2,
        cube.size,cube.size,10,10)

    love.graphics.pop()

    controls.draw(cube.x,cube.y)
end

function game.touchpressed(id,x,y)
    controls.touchpressed(id,x,y)
end

function game.touchmoved(id,x,y)
    controls.touchmoved(id,x,y)
end

function game.touchreleased(id,x,y)
    local shot,dx,dy = controls.touchreleased(id)
    if shot then
        spawnBullet(cube.x,cube.y,dx,dy)
    end
end

return game
