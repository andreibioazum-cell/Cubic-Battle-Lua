local controls = require("controls")

local game = {}

local cube = { x=0,y=0,size=60,speed=260,color={1,0.5,0.3} }
local bullets = {}
local bg
local cam = { x=0,y=0 }

local function spawnBullet(x,y,dx,dy)
    table.insert(bullets,{
        x=x,y=y,
        vx=dx*420,
        vy=dy*420,
        life=3
    })
end

function game.load()
    local w,h = love.graphics.getDimensions()
    cube.x=w/2
    cube.y=h/2
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

    cam.x = cam.x + (cube.x - cam.x - love.graphics.getWidth()/2)*dt*5
    cam.y = cam.y + (cube.y - cam.y - love.graphics.getHeight()/2)*dt*5

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
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(bg,cam.x,cam.y,0,
        w/bg:getWidth(),
        h/bg:getHeight()
    )

    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill",
        cube.x-cube.size/2,
        cube.y-cube.size/2,
        cube.size,cube.size,10,10)

    love.graphics.setColor(0,0,0,1)
    for _,b in ipairs(bullets) do
        love.graphics.circle("fill",b.x,b.y,8)
    end

    love.graphics.pop()

    controls.draw()
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
