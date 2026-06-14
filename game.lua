local joystick = require("joystick")

local game = {}

-- Кубик
local cube = {
    x = 400,
    y = 300,
    size = 60,
    speed = 300,
    color = {1, 0.5, 0.3}
}

-- Кнопка "Назад"
local backButton = {
    x = 20,
    y = 20,
    w = 100,
    h = 50
}

function game.load()
    -- Стартовая позиция кубика
    local w, h = love.graphics.getDimensions()
    cube.x = w / 2
    cube.y = h / 2
    
    -- Джойстик внизу слева
    joystick.load(180, h - 180)
end

function game.update(dt)
    local w, h = love.graphics.getDimensions()
    
    -- Движение кубика через джойстик
    local dx, dy = joystick.getDirection()
    cube.x = cube.x + dx * cube.speed * dt
    cube.y = cube.y + dy * cube.speed * dt
    
    -- Не выходим за границы
    cube.x = math.max(cube.size/2, math.min(w - cube.size/2, cube.x))
    cube.y = math.max(cube.size/2, math.min(h - cube.size/2, cube.y))
end

function game.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Тёмный фон
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    -- Сетка на фоне (для красоты)
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.setLineWidth(1)
    for i = 0, w, 50 do
        love.graphics.line(i, 0, i, h)
    end
    for i = 0, h, 50 do
        love.graphics.line(0, i, w, i)
    end
    
    -- Кубик с тенью
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 
        cube.x - cube.size/2 + 5, 
        cube.y - cube.size/2 + 5, 
        cube.size, cube.size, 10, 10)
    
    -- Сам кубик
    love.graphics.setColor(cube.color)
    love.graphics.rectangle("fill", 
        cube.x - cube.size/2, 
        cube.y - cube.size/2, 
        cube.size, cube.size, 10, 10)
    
    -- Обводка кубика
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 
        cube.x - cube.size/2, 
        cube.y - cube.size/2, 
        cube.size, cube.size, 10, 10)
    
    -- Кнопка "Назад"
    love.graphics.setColor(0.4, 0.2, 0.5, 0.8)
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backButton.x, backButton.y, backButton.w, backButton.h, 10, 10)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("BACK", backButton.x + 25, backButton.y + 13)
    
    -- Джойстик
    joystick.draw()
    
    -- FPS в углу
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("FPS: " .. love.timer.getFPS(), w - 80, 10)
end

function game.touchpressed(id, x, y)
    -- Кнопка "Назад"
    if x >= backButton.x and x <= backButton.x + backButton.w and
       y >= backButton.y and y <= backButton.y + backButton.h then
        GameState.current = "lobby"
        return
    end
    
    -- Иначе передаём в джойстик
    joystick.touchpressed(id, x, y)
end

function game.touchmoved(id, x, y)
    joystick.touchmoved(id, x, y)
end

function game.touchreleased(id, x, y)
    joystick.touchreleased(id, x, y)
end

return game
