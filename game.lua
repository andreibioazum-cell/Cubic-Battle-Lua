local joy = require("joystick")
local game = {}

local cube = {x=0, y=0, size=60, speed=220, vx=0, vy=0, accel=18, dirX=0, dirY=-1}
local cam = {x=0, y=0, smoothness=12}
local backBtn = {x=20, y=20, w=100, h=44}
local atkBtn = {x=0, y=0, r=70}
local atk = {pressed=false, id=nil, ax=0, ay=-1, len=200}
local bullets = {}
local BSPD, BLIFE = 800, 2.5

local sandImg, sandQuad, sandW, sandH
local fontUI

local function recalcUI()
    local w, h = love.graphics.getDimensions()
    atkBtn.x = w - 100
    atkBtn.y = h - 100
end

function game.load()
    local w, h = love.graphics.getDimensions()
    cube.x, cube.y, cube.vx, cube.vy = 0, 0, 0, 0
    cam.x, cam.y = 0, 0
    bullets = {}
    joy.load(90, h - 90)
    recalcUI()
    fontUI = fontUI or love.graphics.newFont(16)

    if not sandImg then
        local ok, img = pcall(love.graphics.newImage, "sand.png", {mipmaps=true})
        if ok then
            sandImg = img
            sandImg:setWrap("repeat", "repeat")
            sandImg:setFilter("linear", "linear", 4)
            sandW, sandH = sandImg:getWidth(), sandImg:getHeight()
            sandQuad = love.graphics.newQuad(0, 0, 1, 1, sandW, sandH)
        end
    end
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    recalcUI()

    local dx, dy = joy.dir()
    if dx ~= 0 or dy ~= 0 then
        cube.vx = cube.vx + (dx * cube.speed - cube.vx) * cube.accel * dt
        cube.vy = cube.vy + (dy * cube.speed - cube.vy) * cube.accel * dt
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 0.1 then
            cube.dirX, cube.dirY = dx/len, dy/len
        end
    else
        cube.vx, cube.vy = 0, 0
    end

    cube.x = cube.x + cube.vx * dt
    cube.y = cube.y + cube.vy * dt

    cam.x = cam.x + (cube.x - w/2 - cam.x) * cam.smoothness * dt
    cam.y = cam.y + (cube.y - h/2 - cam.y) * cam.smoothness * dt

    if atk.pressed then
        atk.ax, atk.ay = cube.dirX, cube.dirY
    end

    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets, i) end
    end
end

function game.draw()
    local w, h = love.graphics.getDimensions()

    -- Фон: рисуем песок как тайл-сетку которая ВСЕГДА покрывает экран целиком
    if sandImg then
        love.graphics.setColor(1, 1, 1, 1)
        -- Смещение тайла на основе камеры
        local offX = -(cam.x % sandW)
        local offY = -(cam.y % sandH)
        -- Рисуем тайлы по экрану (+1 чтобы покрыть края при смещении)
        local cols = math.ceil(w / sandW) + 1
        local rows = math.ceil(h / sandH) + 1
        for r = 0, rows do
            for c = 0, cols do
                love.graphics.draw(sandImg, offX + c * sandW, offY + r * sandH)
            end
        end
    else
        love.graphics.clear(0.4, 0.3, 0.15, 1)
    end

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    -- Прицел
    if atk.pressed then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        love.graphics.setLineWidth(3)
        local tx, ty = cube.x + atk.ax * atk.len, cube.y + atk.ay * atk.len
        love.graphics.line(cube.x, cube.y, tx, ty)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        love.graphics.circle("line", tx, ty, 12)
        love.graphics.line(tx-8, ty, tx+8, ty)
        love.graphics.line(tx, ty-8, tx, ty+8)
    end

    -- Пули
    for _, b in ipairs(bullets) do
        love.graphics.setColor(1, 0.9, 0.3, 1)
        love.graphics.circle("fill", b.x, b.y, 6)
        love.graphics.setColor(1, 0.6, 0.1, 0.5)
        love.graphics.circle("fill", b.x, b.y, 10)
    end

    -- Кубик
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.rectangle("fill", cube.x - cube.size/2 + 4, cube.y - cube.size/2 + 4, cube.size, cube.size, 10, 10)
    love.graphics.setColor(1, 0.5, 0.3)
    love.graphics.rectangle("fill", cube.x - cube.size/2, cube.y - cube.size/2, cube.size, cube.size, 10, 10)
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", cube.x - cube.size/2, cube.y - cube.size/2, cube.size, cube.size, 10, 10)

    love.graphics.pop()

    -- UI
    love.graphics.setFont(fontUI)
    love.graphics.setColor(0.4, 0.2, 0.5, 0.85)
    love.graphics.rectangle("fill", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backBtn.x, backBtn.y, backBtn.w, backBtn.h, 10, 10)
    love.graphics.print("Back", backBtn.x + 30, backBtn.y + 12)

    -- Атака
    local c = atk.pressed and {0.9,0.3,0.2} or {0.7,0.2,0.15}
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.circle("fill", atkBtn.x + 3, atkBtn.y + 4, atkBtn.r)
    love.graphics.setColor(c)
    love.graphics.circle("fill", atkBtn.x, atkBtn.y, atkBtn.r)
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", atkBtn.x, atkBtn.y, atkBtn.r)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Fire", atkBtn.x - 18, atkBtn.y - 10)

    joy.draw()

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

function game.touchpressed(id, x, y)
    if x >= backBtn.x and x <= backBtn.x + backBtn.w and y >= backBtn.y and y <= backBtn.y + backBtn.h then
        GameState.current = "lobby"
        return
    end
    local dx, dy = x - atkBtn.x, y - atkBtn.y
    if dx*dx + dy*dy <= atkBtn.r * atkBtn.r then
        atk.pressed = true
        atk.id = id
        atk.ax, atk.ay = cube.dirX, cube.dirY
        return
    end
    joy.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    joy.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    if atk.pressed and id == atk.id then
        atk.pressed = false
        atk.id = nil
        table.insert(bullets, {
            x = cube.x, y = cube.y,
            vx = atk.ax * BSPD, vy = atk.ay * BSPD,
            life = BLIFE
        })
        return
    end
    joy.touchreleased(id, x, y)
end

return game
