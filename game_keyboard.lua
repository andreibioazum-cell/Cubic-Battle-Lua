local keyboard = {}

local isVisible = false
local inputText = ""
local callback = nil
local maxLength = 20
local allowedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local keyboardX = 0
local keyboardY = 0
local keyboardWidth = 0
local keyboardHeight = 0
local keyWidth = 0
local keyHeight = 0
local keySpacing = 4

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

function keyboard.init()
    return keyboard
end

function keyboard.show(maxLen, allowed, onComplete)
    isVisible = true
    inputText = ""
    maxLength = maxLen or 20
    allowedChars = allowed or "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    callback = onComplete
    
    local w, h = love.graphics.getDimensions()
    keyboardWidth = w * 0.9
    keyboardHeight = h * 0.4
    keyboardX = (w - keyboardWidth) / 2
    keyboardY = h - keyboardHeight - 20
    
    local cols = 10
    keyWidth = (keyboardWidth - (cols + 1) * keySpacing) / cols
    keyHeight = (keyboardHeight - 5 * keySpacing) / 4
end

function keyboard.hide()
    isVisible = false
    inputText = ""
    callback = nil
end

function keyboard.getInput()
    return inputText
end

function keyboard.isActive()
    return isVisible
end

function keyboard.update(dt) end

function keyboard.draw()
    if not isVisible then return end
    
    love.graphics.setColor(0.1, 0.05, 0.2, 0.95)
    love.graphics.rectangle("fill", keyboardX, keyboardY, keyboardWidth, keyboardHeight, 10)
    
    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", keyboardX, keyboardY, keyboardWidth, keyboardHeight, 10)
    
    local inputY = keyboardY + 10
    local inputHeight = keyHeight + 10
    love.graphics.setColor(0.05, 0.02, 0.1, 0.9)
    love.graphics.rectangle("fill", keyboardX + 10, inputY, keyboardWidth - 20, inputHeight, 5)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    local displayText = inputText
    if displayText == "" then
        displayText = "Enter code..."
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    love.graphics.printf(displayText, keyboardX + 20, inputY + 8, keyboardWidth - 40, "left")
    
    local keyY = inputY + inputHeight + keySpacing
    
    local keyX = keyboardX + keySpacing
    for _, key in ipairs(keyDefinitions.row1) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    local offsetX = (keyboardWidth - (9 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row2) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    offsetX = (keyboardWidth - (7 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row3) do
        drawKey(keyX, keyY, keyWidth, keyHeight, key)
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    local specialWidth = (keyboardWidth - (4 * keySpacing) - keySpacing) / 4
    local spaceWidth = specialWidth * 2 + keySpacing
    
    drawSpecialKey(keyboardX + keySpacing, keyY, spaceWidth, keyHeight, "SPACE")
    drawSpecialKey(keyboardX + keySpacing + spaceWidth + keySpacing, keyY, specialWidth, keyHeight, "⌫")
    drawSpecialKey(keyboardX + keySpacing + spaceWidth + keySpacing + specialWidth + keySpacing, keyY, specialWidth, keyHeight, "CLEAR")
    drawSpecialKey(keyboardX + keyboardWidth - specialWidth, keyY, specialWidth, keyHeight, "DONE")
end

function drawKey(x, y, w, h, label)
    love.graphics.setColor(0.2, 0.1, 0.4, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 5)
    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(label, x, y + h/2 - 10, w, "center")
end

function drawSpecialKey(x, y, w, h, label)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 5)
    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 5)
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf(label, x, y + h/2 - 8, w, "center")
end

function keyboard.handleTouch(x, y)
    if not isVisible then return false end
    
    if x < keyboardX or x > keyboardX + keyboardWidth or
       y < keyboardY or y > keyboardY + keyboardHeight then
        return false
    end
    
    local keyY = keyboardY + 10 + keyHeight + 10 + keySpacing
    
    local keyX = keyboardX + keySpacing
    for _, key in ipairs(keyDefinitions.row1) do
        if x >= keyX and x <= keyX + keyWidth and y >= keyY and y <= keyY + keyHeight then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    local offsetX = (keyboardWidth - (9 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row2) do
        if x >= keyX and x <= keyX + keyWidth and y >= keyY and y <= keyY + keyHeight then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    offsetX = (keyboardWidth - (7 * (keyWidth + keySpacing) - keySpacing)) / 2
    keyX = keyboardX + offsetX
    for _, key in ipairs(keyDefinitions.row3) do
        if x >= keyX and x <= keyX + keyWidth and y >= keyY and y <= keyY + keyHeight then
            handleKeyPress(key)
            return true
        end
        keyX = keyX + keyWidth + keySpacing
    end
    
    keyY = keyY + keyHeight + keySpacing
    local specialWidth = (keyboardWidth - (4 * keySpacing) - keySpacing) / 4
    local spaceWidth = specialWidth * 2 + keySpacing
    
    if x >= keyboardX + keySpacing and x <= keyboardX + keySpacing + spaceWidth and
       y >= keyY and y <= keyY + keyHeight then
        handleSpecialKey("SPACE")
        return true
    end
    
    local bx = keyboardX + keySpacing + spaceWidth + keySpacing
    if x >= bx and x <= bx + specialWidth and y >= keyY and y <= keyY + keyHeight then
        handleSpecialKey("BACKSPACE")
        return true
    end
    
    local cx = bx + specialWidth + keySpacing
    if x >= cx and x <= cx + specialWidth and y >= keyY and y <= keyY + keyHeight then
        handleSpecialKey("CLEAR")
        return true
    end
    
    local dx = keyboardX + keyboardWidth - specialWidth
    if x >= dx and x <= dx + specialWidth and y >= keyY and y <= keyY + keyHeight then
        handleSpecialKey("DONE")
        return true
    end
    
    return false
end

function handleKeyPress(key)
    if string.len(inputText) >= maxLength then
        return
    end
    
    if allowedChars and not allowedChars:find(key) then
        return
    end
    
    inputText = inputText .. key
end

function handleSpecialKey(key)
    if key == "SPACE" then
        if string.len(inputText) < maxLength then
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
end

function keyboard.handleTextInput(text)
    if isVisible and text then
        handleKeyPress(string.upper(text))
    end
end

return keyboard
