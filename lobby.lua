local lobby = {}

local buttonX, buttonY, buttonW, buttonH
local titleY = 0

function lobby.load()
    -- Будет пересчитано в draw, но инициализируем
    buttonW = 300
    buttonH = 100
end

function lobby.update(dt)
    -- Анимация заголовка (плавно качается)
    titleY = titleY + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Фиолетовый фон с градиентом
    love.graphics.clear(0.2, 0.05, 0.35, 1)  -- тёмно-фиолетовый
    
    -- Светлый фиолетовый сверху (имитация градиента)
    love.graphics.setColor(0.5, 0.2, 0.7, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h/3)
    
    -- Заголовок
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.newFont(50)
    love.graphics.setFont(font)
    local title = "MY GAME"
    local tw = font:getWidth(title)
    local offsetY = math.sin(titleY * 2) * 10  -- анимация
    love.graphics.print(title, w/2 - tw/2, h/4 + offsetY)
    
    -- Подзаголовок
    local font2 = love.graphics.newFont(20)
    love.graphics.setFont(font2)
    love.graphics.setColor(0.8, 0.8, 1, 0.7)
    local sub = "Touch screen to play"
    local sw = font2:getWidth(sub)
    love.graphics.print(sub, w/2 - sw/2, h/4 + 80)
    
    -- Кнопка "PLAY"
    buttonX = w/2 - buttonW/2
    buttonY = h/2
    
    -- Тень кнопки
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", buttonX + 5, buttonY + 5, buttonW, buttonH, 20, 20)
    
    -- Сама кнопка
    love.graphics.setColor(0.6, 0.3, 0.9, 1)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 20, 20)
    
    -- Обводка
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 20, 20)
    
    -- Текст на кнопке
    love.graphics.setColor(1, 1, 1, 1)
    local font3 = love.graphics.newFont(40)
    love.graphics.setFont(font3)
    local btnText = "PLAY"
    local btw = font3:getWidth(btnText)
    local bth = font3:getHeight()
    love.graphics.print(btnText, buttonX + buttonW/2 - btw/2, buttonY + buttonH/2 - bth/2)
    
    -- Версия внизу
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("v1.0", 10, h - 25)
end

function lobby.touchpressed(id, x, y)
    -- Проверяем нажатие на кнопку PLAY
    if x >= buttonX and x <= buttonX + buttonW and
       y >= buttonY and y <= buttonY + buttonH then
        GameState.current = "game"
    end
end

return lobby
