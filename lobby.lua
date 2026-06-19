local lobby = {}

local fontTitle, fontBtn, fontSmall
local animTimer = 0
local game = nil
local connecting = false
local connect_error = ""
local input_ip = ""
local input_port = "12345"
local show_join_menu = false
local status_messages = {}

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

local function connectToServer(ip, port)
    if connecting then return end
    
    local g = tryLoadGame()
    if not g then return end
    
    connecting = true
    connect_error = ""
    
    local success = g.connect(ip, tonumber(port) or 12345)
    
    if success then
        g.setMode("client")
        GameState.current = "game"
    else
        connect_error = "❌ Не удалось подключиться"
    end
    
    connecting = false
end

local function hostServer(port)
    local g = tryLoadGame()
    if not g then return end
    
    local success = g.hostGame(tonumber(port) or 12345)
    
    if success then
        GameState.current = "game"
    else
        connect_error = "❌ Не удалось создать сервер"
    end
end

local buttons = {}
local function makeButton(text, y, action, color, size)
    table.insert(buttons, { 
        text = text, 
        y = y, 
        action = action,
        color = color or {0.45, 0.15, 0.75},
        size = size or 1
    })
end

local function updateButtons()
    buttons = {}
    local h = love.graphics.getHeight()
    local startY = h/2 - 50
    
    makeButton("🏠 OFFLINE GAME", startY, function()
        local g = tryLoadGame()
        if g then
            g.disconnect()
            g.setMode("offline")
            g.load()
            GameState.current = "game"
        end
    end, {0.2, 0.6, 0.8})
    
    makeButton("👑 CREATE SERVER", startY + 65, function()
        hostServer(12345)
    end, {0.8, 0.5, 0.2})
    
    makeButton("🔗 JOIN GAME", startY + 130, function()
        show_join_menu = true
    end, {0.2, 0.7, 0.4})
    
    makeButton("❌ QUIT", startY + 195, function()
        love.event.quit()
    end, {0.6, 0.2, 0.2})
end

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 48)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 20)
    fontSmall = fontSmall or love.graphics.newFont("Fredoka-Bold.ttf", 16)
    
    tryLoadGame()
    updateButtons()
    animTimer = 0
    show_join_menu = false
    input_ip = ""
    input_port = "12345"
end

function lobby.update(dt)
    animTimer = animTimer + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Градиент
    local gradientSteps = 60
    local stepH = h / gradientSteps
    for i = 0, gradientSteps - 1 do
        local t = i / (gradientSteps - 1)
        local r = 0.08 + t * 0.07
        local g = 0.02 + t * 0.05
        local b = 0.18 + t * 0.30
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", 0, i * stepH, w, stepH + 1)
    end
    
    -- Звёзды
    love.graphics.setColor(1, 1, 1, 0.35)
    for i = 1, 50 do
        local px = (math.sin(animTimer * 0.3 + i * 7.3) * 0.5 + 0.5) * w
        local py = (math.cos(animTimer * 0.5 + i * 4.7) * 0.5 + 0.5) * h
        local size = 1 + math.sin(animTimer * 2 + i) * 1
        love.graphics.circle("fill", px, py, size)
    end
    
    -- Заголовок
    local titleY = h/2 - 180
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("⚔ CUBIC BATTLE", 0, titleY, w, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.9, 0.5)
    love.graphics.setFont(fontSmall)
    love.graphics.printf("Multiplayer Arena", 0, titleY + 55, w, "center")
    
    -- Кнопки
    local bw, bh = 240, 50
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", bx + 3, by + 3, bw, bh, 12, 12)
        
        local color = btn.color or {0.45, 0.15, 0.75}
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.rectangle("fill", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(
            math.min(1, color[1] + 0.2),
            math.min(1, color[2] + 0.2),
            math.min(1, color[3] + 0.2),
            0.3
        )
        love.graphics.rectangle("fill", bx + 3, by + 2, bw - 6, bh/2, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, bw, bh, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf(btn.text, bx, by + bh/2 - 11, bw, "center")
    end
    
    -- Меню подключения
    if show_join_menu then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", w/2 - 150, h/2 - 80, 300, 160, 12, 12)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("Введите IP сервера", 0, h/2 - 60, w, "center")
        
        -- Поле ввода IP
        love.graphics.setColor(0.2, 0.2, 0.3, 1)
        love.graphics.rectangle("fill", w/2 - 130, h/2 - 25, 260, 35, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", w/2 - 130, h/2 - 25, 260, 35, 8, 8)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontSmall)
        local ip_text = input_ip ~= "" and input_ip or "IP адрес..."
        love.graphics.print(ip_text, w/2 - 120, h/2 - 17)
        
        -- Кнопки
        love.graphics.setColor(0.2, 0.7, 0.4, 1)
        love.graphics.rectangle("fill", w/2 - 130, h/2 + 25, 125, 35, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Подключиться", w/2 - 120, h/2 + 33)
        
        love.graphics.setColor(0.6, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", w/2 + 5, h/2 + 25, 125, 35, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Отмена", w/2 + 15, h/2 + 33)
    end
    
    -- Статус
    if connecting then
        love.graphics.setColor(1, 0.9, 0, 0.7)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("⏳ Подключение...", 0, h - 60, w, "center")
    end
    
    if connect_error ~= "" then
        love.graphics.setColor(1, 0.3, 0.3, 0.8)
        love.graphics.setFont(fontSmall)
        love.graphics.printf(connect_error, 0, h - 40, w, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    if show_join_menu then
        -- Кнопка "Подключиться"
        if x >= w/2 - 130 and x <= w/2 - 5 and y >= h/2 + 25 and y <= h/2 + 60 then
            if input_ip ~= "" then
                connectToServer(input_ip, input_port)
                show_join_menu = false
            end
            return
        end
        
        -- Кнопка "Отмена"
        if x >= w/2 + 5 and x <= w/2 + 130 and y >= h/2 + 25 and y <= h/2 + 60 then
            show_join_menu = false
            return
        end
        
        -- Клик по полю ввода (для ввода IP)
        if x >= w/2 - 130 and x <= w/2 + 130 and y >= h/2 - 25 and y <= h/2 + 10 then
            input_ip = ""  -- Очищаем поле для ввода
            return
        end
    end
    
    local bw, bh = 240, 50
    
    for _, btn in ipairs(buttons) do
        local bx = w/2 - bw/2
        local by = btn.y
        if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
            if btn.action then 
                btn.action() 
            end
            return
        end
    end
end

function lobby.keypressed(key)
    if show_join_menu then
        if key == "return" or key == "enter" then
            if input_ip ~= "" then
                connectToServer(input_ip, input_port)
                show_join_menu = false
            end
        elseif key == "escape" then
            show_join_menu = false
        elseif key == "backspace" then
            input_ip = input_ip:sub(1, -2)
        elseif #input_ip < 25 then
            if key >= "0" and key <= "9" then
                input_ip = input_ip .. key
            elseif key == "." or key == ":" then
                input_ip = input_ip .. key
            end
        end
    end
end

function lobby.mousepressed(x, y)
    lobby.touchpressed(1, x, y)
end

function lobby.resize()
    updateButtons()
end

return lobby
