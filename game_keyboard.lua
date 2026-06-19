-- ============================================================
-- ПОЛЬЗОВАТЕЛЬСКАЯ КЛАВИАТУРА
-- Встроенная клавиатура для мобильных устройств и ПК
-- ============================================================

local keyboard = {}

-- ========== НАСТРОЙКИ ==========
local CONFIG = {
    rows = {
        {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
        {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
        {"Z", "X", "C", "V", "B", "N", "M"}
    },
    specialKeys = {
        "SPACE",
        "BACKSPACE",
        "CLEAR",
        "DONE"
    },
    colors = {
        background = {0.1, 0.05, 0.2, 0.95},
        key = {0.2, 0.1, 0.4, 0.9},
        keyActive = {0.4, 0.2, 0.8, 0.9},
        keyText = {1, 1, 1, 1},
        keySpecial = {0.3, 0.3, 0.5, 0.9},
        keySpecialText = {1, 0.8, 0, 1},
        border = {0.5, 0.2, 1, 0.3}
    }
}

-- ========== ПЕРЕМЕННЫЕ ==========
local isVisible = false          -- Видимость клавиатуры
local inputText = ""             -- Текст ввода
local callback = nil             -- Функция обратного вызова
local keyboardX = 0              -- Позиция по X
local keyboardY = 0              -- Позиция по Y
local keyboardWidth = 0          -- Ширина
local keyboardHeight = 0         -- Высота
local keyWidth = 0               -- Ширина клавиши
local keyHeight = 0              -- Высота клавиши
local keySpacing = 0             -- Отступ между клавишами
local keyboardState = {
    active = false,
    input = "",
    maxLength = 20,              -- Максимальная длина
    allowedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"  -- Разрешённые символы
}

-- ========== ОПРЕДЕЛЕНИЕ КЛАВИШ ==========
local keyDefinitions = {
    row1 = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
    row2 = {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
    row3 = {"Z", "X", "C", "V", "B", "N", "M"},
    special = {
        {label = "SPACE", type = "space"},
        {label = "⌫", type = "backspace"},
        {label = "CLEAR", type = "clear"},
        {label = "DONE", type = "done"}
    }
}

-- ========== ИНИЦИАЛИЗАЦИЯ ==========
function keyboard.init()
    print("Пользовательская клавиатура инициализирована!")
    return keyboard
end

-- ========== ПОКАЗАТЬ КЛАВИАТУРУ ==========
function keyboard.show(maxLength, allowedChars, onComplete)
    isVisible = true
    inputText = ""
    keyboardState.input = ""
    keyboardState.maxLength = maxLength or 20
    keyboardState.allowedChars = allowedChars or "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    callback = onComplete
    
    -- Вычисляем позицию клавиатуры
    local w, h = love.graphics.getDimensions()
    keyboardWidth = w * 0.9
    keyboardHeight = h * 0.4
    keyboardX = (w - keyboardWidth) / 2
    keyboardY = h - keyboardHeight - 20
    
    -- Вычисляем размеры клавиш
    local cols = 10
    keySpacing = 4
    keyWidth = (keyboardWidth - (cols + 1) * keySpacing) / cols
    keyHeight = (keyboardHeight - 5 * keySpacing) / 4
    
    print("Клавиатура показана!")
end

-- ========== СКРЫТЬ КЛАВИАТУРУ ==========
function keyboard.hide()
    isVisible = false
    inputText = ""
    callback = nil
    print("Клавиатура скрыта!")
end

-- ========== ПОЛУЧИТЬ ВВЕДЁННЫЙ ТЕКСТ ==========
function keyboard.getInput()
    return inputText
end

-- ========== ПРОВЕРКА АКТИВНОСТИ ==========
function keyboard.isActive()
    return isVisible
end

-- ========== ОБНОВЛЕНИЕ ==========
function keyboard.update(dt)
    -- Здесь можно добавить анимации
end

-- ========== ОТРИСОВКА КЛАВИАТУРЫ ==========
function keyboard.draw()
    if not isVisible then return end
    
    -- Фон клавиатуры
    love.graphics.setColor(CONFIG.colors.background)
    love.graphics.rectangle("fill", keyboardX, keyboardY, keyboardWidth, keyboardHeight, 10)
    
    -- Рамка
    love.graphics.setColor(CONFIG.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", keyboardX, keyboardY, keyboardWidth, keyboardHeight, 10)
    
    -- Поле ввода
    local inputY = keyboardY + 10
    local inputHeight = keyHeight + 10
    love.graphics.setColor(0.05, 0.02, 0.1, 0.9)
    love.graphics.rectangle("fill", keyboardX + 10, inputY, keyboardWidth - 20, inputHeight, 5)
    
    love.graphics.setColor(CONFIG.colors.keyText)
    love.graphics.setFont(love.graphics.newFont(18))
    local displayText = inputText
    if displayText == "" then
        displayText = "Введите код..."
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    love.graphics.printf(displayText, keyboardX + 20, inputY + 8, keyboardWidth - 40, "left")
    
    -- Рисуем клавиши
    local keyY = inputY + inputHeight + keySpacing
    
    -- Первый ряд
    local keyX = keyboardX + keySpacing
    for _, key in ipairs(keyDefinitions.row1) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Второй ряд
    keyY = keyY + keyHeight + keySpacing
    local offsetX = (keyboardWidth - (9 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row2) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Третий ряд
    keyY = keyY + keyHeight + keySpacing
    offsetX = (keyboardWidth - (7 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row3) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Специальные клавиши
    keyY = keyY + keyHeight + keySpacing
    local specialWidth = (keyboardWidth - (4 * keySpacing) - keySpacing) / 4
    
    -- SPACE (занимает 2 слота)
    local spaceWidth = specialWidth * 2 + keySpacing
    drawSpecialKey(keyboardX + keySpacing, keyY, spaceWidth, keyHeight, "SPACE")
    
    -- BACKSPACE
    drawSpecialKey(keyboardX + keySpacing + spaceWidth + keySpacing, keyY, specialWidth, keyHeight, "⌫")
    
    -- CLEAR
    drawSpecialKey(keyboardX + keySpacing + spaceWidth + keySpacing + specialWidth + keySpacing, keyY, specialWidth, keyHeight, "CLEAR")
    
    -- DONE
    drawSpecialKey(keyboardX + keyboardWidth - specialWidth, keyY, specialWidth, keyHeight, "DONE")
end

-- ========== ОТРИСОВКА ОБЫЧНОЙ КЛАВИШИ ==========
function drawKey(x, y, w, h, label)
    -- Фон клавиши
    love.graphics.setColor(CONFIG.colors.key)
    love.graphics.rectangle("fill", x, y, w, h, 5)
    
    -- Рамка
    love.graphics.setColor(CONFIG.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 5)
    
    -- Текст
    love.graphics.setColor(CONFIG.colors.keyText)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(label, x, y + h/2 - 10, w, "center")
end

-- ========== ОТРИСОВКА СПЕЦИАЛЬНОЙ КЛАВИШИ ==========
function drawSpecialKey(x, y, w, h, label)
    love.graphics.setColor(CONFIG.colors.keySpecial)
    love.graphics.rectangle("fill", x, y, w, h, 5)
    
    love.graphics.setColor(CONFIG.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 5)
    
    love.graphics.setColor(CONFIG.colors.keySpecialText)
    love.graphics.setFont(love.graphics.newFont(14))
    
    if label == "SPACE" then
        love.graphics.printf("ПРОБЕЛ", x, y + h/2 - 8, w, "center")
    elseif label == "⌫" then
        love.graphics.printf("⌫", x, y + h/2 - 10, w, "center")
    elseif label == "CLEAR" then
        love.graphics.printf("ОЧИСТИТЬ", x, y + h/2 - 8, w, "center")
    elseif label == "DONE" then
        love.graphics.printf("ГОТОВО", x, y + h/2 - 8, w, "center")
    end
end

-- ========== ОБРАБОТКА КАСАНИЙ ==========
function keyboard.handleTouch(x, y)
    if not isVisible then return false end
    
    -- Проверяем, нажали ли на клавиатуру
    if x < keyboardX or x > keyboardX + keyboardWidth or
       y < keyboardY or y > keyboardY + keyboardHeight then
        return false
    end
    
    -- Определяем, какая клавиша нажата
    local keyY = keyboardY + 10 + keyHeight + 10 + keySpacing
    
    -- Первый ряд
    local keyX = keyboardX + keySpacing
    for _, key in ipairs(keyDefinitions.row1) do
        if isPointInKey(x, y, keyX, keyY, keyWidth, keyHeight) then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Второй ряд
    keyY = keyY + keyHeight + keySpacing
    local offsetX = (keyboardWidth - (9 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row2) do
        if isPointInKey(x, y, keyX, keyY, keyWidth, keyHeight) then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Третий ряд
    keyY = keyY + keyHeight + keySpacing
    offsetX = (keyboardWidth - (7 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row3) do
        if isPointInKey(x, y, keyX, keyY, keyWidth, keyHeight) then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    -- Специальные клавиши
    keyY = keyY + keyHeight + keySpacing
    local specialWidth = (keyboardWidth - (4 * keySpacing) - keySpacing) / 4
    
    -- SPACE
    local spaceWidth = specialWidth * 2 + keySpacing
    if isPointInKey(x, y, keyboardX + keySpacing, keyY, spaceWidth, keyHeight) then
        handleSpecialKey("SPACE")
        return true
    end
    
    -- BACKSPACE
    local bx = keyboardX + keySpacing + spaceWidth + keySpacing
    if isPointInKey(x, y, bx, keyY, specialWidth, keyHeight) then
        handleSpecialKey("BACKSPACE")
        return true
    end
    
    -- CLEAR
    local cx = bx + specialWidth + keySpacing
    if isPointInKey(x, y, cx, keyY, specialWidth, keyHeight) then
        handleSpecialKey("CLEAR")
        return true
    end
    
    -- DONE
    local dx = keyboardX + keyboardWidth - specialWidth
    if isPointInKey(x, y, dx, keyY, specialWidth, keyHeight) then
        handleSpecialKey("DONE")
        return true
    end
    
    return false
end

-- ========== ПРОВЕРКА ПОПАДАНИЯ В КЛАВИШУ ==========
function isPointInKey(px, py, kx, ky, kw, kh)
    return px >= kx and px <= kx + kw and py >= ky and py <= ky + kh
end

-- ========== ОБРАБОТКА НАЖАТИЯ НА КЛАВИШУ ==========
function handleKeyPress(key)
    -- Проверяем длину
    if string.len(inputText) >= keyboardState.maxLength then
        return
    end
    
    -- Проверяем разрешённые символы
    if keyboardState.allowedChars and not keyboardState.allowedChars:find(key) then
        return
    end
    
    inputText = inputText .. key
    print("Нажата клавиша: " .. key .. " -> " .. inputText)
end

-- ========== ОБРАБОТКА СПЕЦИАЛЬНЫХ КЛАВИШ ==========
function handleSpecialKey(key)
    if key == "SPACE" then
        if string.len(inputText) < keyboardState.maxLength then
            inputText = inputText .. " "
        end
    elseif key == "BACKSPACE" then
        inputText = string.sub(inputText, 1, -2)
    elseif key == "CLEAR" then
        inputText = ""
    elseif key == "DONE" then
        if callback then
            callback(inputText)
        end
        keyboard.hide()
    end
    print("Специальная клавиша: " .. key .. " -> " .. inputText)
end

return keyboard
