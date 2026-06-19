local lobby = {}

local fontTitle, fontBtn, fontSmall
local animTimer = 0
local game = nil
local connecting = false
local connect_error = ""
local input_ip = ""
local input_port = "12345"
local show_join_menu = false
local input_active = false
local keyboard_visible = false

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
local function makeButton(text, y, action, color)
    table.insert(buttons, { 
        text = text, 
        y = y, 
        action = action,
        color = color or {0.45, 0.15, 0.75}
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
        input_active = true
        keyboard_visible = true
    end, {0.2, 0.7, 0.4})
    
    makeButton("❌ QUIT", startY + 195, function()
        love.event.quit()
    end, {0.6, 0.2, 0.2})
end

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 48)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 20)
    fontSmall = fontSmall or love.graphics.newFont("Fredoka-Bold.ttf", 18)
    
    tryLoadGame()
    updateButtons()
    animTimer = 0
    show_join_menu = false
    input_ip = ""
    input_port = "12345"
    input_active = false
    keyboard_visible = false
end

function lobby.update(dt)
    animTimer = animTimer + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Фон
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
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Панель
        local panel_w = math.min(350, w - 40)
        local panel_h = 300
        local panel_x = w/2 - panel_w/2
        local panel_y = 60
        
        love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
        love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, 16, 16)
        love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panel_x, panel_y, panel_w, panel_h, 16, 16)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("🔗 ПОДКЛЮЧЕНИЕ", panel_x, panel_y + 15, panel_w, "center")
        
        -- Поле ввода IP
        local input_y = panel_y + 60
        love.graphics.setColor(0.05, 0.05, 0.1, 1)
        love.graphics.rectangle("fill", panel_x + 20, input_y, panel_w - 40, 45, 8, 8)
        love.graphics.setColor(0.3, 0.3, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panel_x + 20, input_y, panel_w - 40, 45, 8, 8)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontSmall)
        local display_text = input_ip
        if display_text == "" then
            display_text = "Введите IP адрес"
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        else
            love.graphics.setColor(0, 1, 0, 1)
        end
        love.graphics.print(display_text, panel_x + 30, input_y + 12)
        
        -- Кнопки
        local btn_y = panel_y + panel_h - 65
        local btn_w = (panel_w - 50) / 2
        
        -- Кнопка "Подключиться"
        love.graphics.setColor(0.2, 0.7, 0.4, 1)
        love.graphics.rectangle("fill", panel_x + 15, btn_y, btn_w, 45, 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontSmall)
        love.graphics.printf("✅ Подключиться", panel_x + 15, btn_y + 12, btn_w, "center")
        
        -- Кнопка "Отмена"
        love.graphics.setColor(0.6, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", panel_x + 30 + btn_w, btn_y, btn_w, 45, 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("❌ Отмена", panel_x + 30 + btn_w, btn_y + 12, btn_w, "center")
        
        -- Экранная клавиатура (для телефона)
        drawKeyboard(panel_x, panel_y + panel_h + 10, panel_w)
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

-- ============================================================
-- ЭКРАННАЯ КЛАВИАТУРА (ДЛЯ ТЕЛЕФОНА)
-- ============================================================

function drawKeyboard(panel_x, panel_y, panel_w)
    if not keyboard_visible then return end
    
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    -- Клавиатура
    local keys = {
        {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"},
        {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p"},
        {"a", "s", "d", "f", "g", "h", "j", "k", "l"},
        {".", ":", "-", "_", "/", "⌫", "␣", "OK"}
    }
    
    local key_w = 45
    local key_h = 45
    local spacing = 4
    local keyboard_w = #keys[1] * (key_w + spacing) - spacing
    local start_x = w/2 - keyboard_w/2
    
    -- Если клавиатура не помещается, уменьшаем клавиши
    if keyboard_w > w - 20 then
        key_w = (w - 20 - (#keys[1] - 1) * spacing) / #keys[1]
    end
    
    for row, row_keys in ipairs(keys) do
        -- Центрируем каждый ряд
        local row_w = #row_keys * (key_w + spacing) - spacing
        local row_x = w/2 - row_w/2
        
        for col, k in ipairs(row_keys) do
            local bx = row_x + col * (key_w + spacing) - key_w - spacing
            local by = panel_y + 10 + (row - 1) * (key_h + spacing)
            
            -- Цвет клавиши
            if k == "⌫" then
                love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
            elseif k == "OK" then
                love.graphics.setColor(0.2, 0.6, 0.3, 0.9)
            elseif k == "␣" then
                love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
                -- Делаем пробел шире
                key_w = key_w * 2.5
            else
                love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
            end
            
            -- Рисуем клавишу
            love.graphics.rectangle("fill", bx, by, key_w, key_h, 6, 6)
            love.graphics.setColor(0.4, 0.4, 0.6, 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", bx, by, key_w, key_h, 6, 6)
            
            -- Текст на клавише
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fontSmall)
            local text_w = fontSmall:getWidth(k)
            love.graphics.print(k, bx + key_w/2 - text_w/2, by + key_h/2 - 12)
            
            -- Возвращаем ширину пробела
            if k == "␣" then
                key_w = 45
            end
        end
    end
    
    -- Сохраняем клавиши для обработки касаний
    lobby.keyboard_keys = keys
    lobby.keyboard_data = {
        key_w = key_w,
        key_h = key_h,
        spacing = spacing,
        start_y = panel_y + 10,
        panel_x = panel_x,
        panel_y = panel_y,
        panel_w = panel_w
    }
end

-- ============================================================
-- ОБРАБОТКА КАСАНИЙ
-- ============================================================

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    if show_join_menu then
        local panel_w = math.min(350, w - 40)
        local panel_x = w/2 - panel_w/2
        local panel_y = 60
        local panel_h = 300
        
        -- Кнопка "Подключиться"
        local btn_w = (panel_w - 50) / 2
        local btn_y = panel_y + panel_h - 65
        
        if x >= panel_x + 15 and x <= panel_x + 15 + btn_w and 
           y >= btn_y and y <= btn_y + 45 then
            if input_ip ~= "" then
                connectToServer(input_ip, input_port)
                show_join_menu = false
                keyboard_visible = false
                input_active = false
            end
            return
        end
        
        -- Кнопка "Отмена"
        if x >= panel_x + 30 + btn_w and x <= panel_x + 30 + btn_w + btn_w and 
           y >= btn_y and y <= btn_y + 45 then
            show_join_menu = false
            keyboard_visible = false
            input_active = false
            return
        end
        
        -- Обработка экранной клавиатуры
        if keyboard_visible and lobby.keyboard_keys then
            local data = lobby.keyboard_data
            if data then
                for row, row_keys in ipairs(lobby.keyboard_keys) do
                    local row_w = #row_keys * (data.key_w + data.spacing) - data.spacing
                    local row_x = w/2 - row_w/2
                    
                    for col, k in ipairs(row_keys) do
                        local bx = row_x + col * (data.key_w + data.spacing) - data.key_w - data.spacing
                        local by = data.start_y + (row - 1) * (data.key_h + data.spacing)
                        
                        if x >= bx and x <= bx + data.key_w and y >= by and y <= by + data.key_h then
                            handleKeyPress(k)
                            return
                        end
                    end
                end
            end
        end
        
        return
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

-- ============================================================
-- ОБРАБОТКА НАЖАТИЙ КЛАВИШ
-- ============================================================

function handleKeyPress(key)
    if key == "⌫" then
        input_ip = input_ip:sub(1, -2)
    elseif key == "OK" then
        if input_ip ~= "" then
            connectToServer(input_ip, input_port)
            show_join_menu = false
            keyboard_visible = false
            input_active = false
        end
    elseif key == "␣" then
        if #input_ip < 25 then
            input_ip = input_ip .. " "
        end
    else
        if #input_ip < 25 then
            input_ip = input_ip .. key
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
