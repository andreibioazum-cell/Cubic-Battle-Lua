local codescreen = {}

local CORRECT_CODE = "3827"
local enteredCode = ""
local wrongFlash = 0   -- таймер красной вспышки при неверном коде
local buttons = {}     -- кнопки цифр

-- Геометрия
local btnSize = 80
local gridGap = 12

local function rebuildButtons(w, h)
    buttons = {}
    -- Раскладка 3x4 (1-9, *, 0, ←)
    local labels = {
        "1", "2", "3",
        "4", "5", "6",
        "7", "8", "9",
        "C", "0", "<"
    }
    local gridW = btnSize * 3 + gridGap * 2
    local gridH = btnSize * 4 + gridGap * 3
    local startX = w/2 - gridW/2
    local startY = h/2 - gridH/2 + 60

    for i, label in ipairs(labels) do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        table.insert(buttons, {
            x = startX + col * (btnSize + gridGap),
            y = startY + row * (btnSize + gridGap),
            w = btnSize,
            h = btnSize,
            label = label
        })
    end
end

function codescreen.load()
    enteredCode = ""
    wrongFlash = 0
    rebuildButtons(love.graphics.getWidth(), love.graphics.getHeight())
end

function codescreen.resize(w, h)
    rebuildButtons(w, h)
end

function codescreen.update(dt)
    if wrongFlash > 0 then
        wrongFlash = wrongFlash - dt
    end
end

function codescreen.draw()
    local w, h = love.graphics.getDimensions()

    -- Фон (тёмный с лёгким красным при ошибке)
    if wrongFlash > 0 then
        local r = 0.15 + wrongFlash * 0.3
        love.graphics.clear(r, 0.05, 0.08, 1)
    else
        love.graphics.clear(0.08, 0.08, 0.12, 1)
    end

    -- Заголовок
    love.graphics.setColor(1, 1, 1, 1)
    local titleFont = love.graphics.newFont(36)
    love.graphics.setFont(titleFont)
    local title = "ENTER CODE"
    local tw = titleFont:getWidth(title)
    love.graphics.print(title, w/2 - tw/2, h/2 - 280)

    -- Поле с введённым кодом (точки)
    local dotSize = 18
    local dotGap = 22
    local totalDotsW = 4 * dotSize + 3 * dotGap
    local dotsX = w/2 - totalDotsW/2
    local dotsY = h/2 - 200

    for i = 1, 4 do
        local x = dotsX + (i - 1) * (dotSize + dotGap)
        if i <= #enteredCode then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.circle("fill", x + dotSize/2, dotsY + dotSize/2, dotSize/2)
        else
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", x + dotSize/2, dotsY + dotSize/2, dotSize/2)
        end
    end

    -- Кнопки
    local btnFont = love.graphics.newFont(32)
    love.graphics.setFont(btnFont)

    for _, btn in ipairs(buttons) do
        -- Тень
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", btn.x + 2, btn.y + 3, btn.w, btn.h, 12, 12)
        -- Кнопка
        love.graphics.setColor(0.2, 0.2, 0.28, 1)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12, 12)
        -- Обводка
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 12, 12)
        -- Текст
        love.graphics.setColor(1, 1, 1, 0.95)
        local lw = btnFont:getWidth(btn.label)
        local lh = btnFont:getHeight()
        love.graphics.print(btn.label, btn.x + btn.w/2 - lw/2, btn.y + btn.h/2 - lh/2)
    end
end

function codescreen.touchpressed(id, x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x <= btn.x + btn.w and
           y >= btn.y and y <= btn.y + btn.h then
            if btn.label == "<" then
                -- Backspace
                if #enteredCode > 0 then
                    enteredCode = enteredCode:sub(1, #enteredCode - 1)
                end
            elseif btn.label == "C" then
                -- Clear
                enteredCode = ""
            else
                -- Цифра
                if #enteredCode < 4 then
                    enteredCode = enteredCode .. btn.label
                end
                -- Проверка после 4-й цифры
                if #enteredCode == 4 then
                    if enteredCode == CORRECT_CODE then
                        GameState.current = "lobby"
                        enteredCode = ""
                    else
                        wrongFlash = 0.5
                        enteredCode = ""
                    end
                end
            end
            return
        end
    end
end

return codescreen
