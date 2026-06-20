local lobby = {}

local fontTitle, fontBtn
local animTimer = 0
local coins = 0
local shop_open = false
local bgCanvas = nil
local stars = {}

local skins = {
    default = { name = "Default Cube", price = 0, owned = true },
    diamond = { name = "Diamond Cube", price = 100, owned = false }
}
local selected_skin = "default"

local promoInput = ""
local promoActive = false
local promoResult = ""
local promoResultColor = {1, 1, 1}
local promoCooldown = 0

local promoCodes = {
    ["KAKAK"] = { reward = 100, description = "KAKAK!", maxUses = 999, used = 0 },
    ["KAKAK2026"] = { reward = 100, description = "Godzilla KAKAK!", maxUses = 999, used = 0 },
    ["CUBIC"] = { reward = 50, description = "Cubic", maxUses = 999, used = 0 },
    ["BETA2026"] = { reward = 200, description = "Beta tester", maxUses = 100, used = 0 },
    ["FURRY"] = { reward = 150, description = "Furry", maxUses = 50, used = 0 },
    ["GODZILLA"] = { reward = 500, description = "Godzilla!", maxUses = 10, used = 0 },
    ["PLATI"] = { reward = 1000, description = "Pay or no badge!", maxUses = 5, used = 0 }
}

local usedByPlayer = {}

-- ============================================================
-- СОХРАНЕНИЕ И ЗАГРУЗКА
-- ============================================================
local function saveGame()
    local data = string.format("%d\n%s\n%s", 
        coins or 0, 
        skins.diamond.owned and "diamond" or "default", 
        selected_skin or "default"
    )
    love.filesystem.write("save.txt", data)
end

local function loadSave()
    local data = love.filesystem.read("save.txt")
    if data then
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        coins = tonumber(lines[1]) or 0
        if lines[2] == "diamond" then
            skins.diamond.owned = true
        end
        selected_skin = lines[3] or "default"
    end
end

local function loadPromoCodes()
    local data = love.filesystem.read("promo_stats.txt")
    if data then
        for line in data:gmatch("[^\r\n]+") do
            local code, uses = line:match("([^:]+):(%d+)")
            if code and uses and promoCodes[code] then
                promoCodes[code].used = tonumber(uses) or 0
            end
        end
    end
    
    local used = love.filesystem.read("used_promos.txt")
    if used then
        for code in used:gmatch("[^\r\n]+") do
            usedByPlayer[code] = true
        end
    end
end

local function savePromoCodes()
    local stats = ""
    for code, info in pairs(promoCodes) do
        stats = stats .. code .. ":" .. info.used .. "\n"
    end
    love.filesystem.write("promo_stats.txt", stats)
    
    local used = ""
    for code in pairs(usedByPlayer) do
        used = used .. code .. "\n"
    end
    love.filesystem.write("used_promos.txt", used)
end

local function createBG()
    local w, h = love.graphics.getDimensions()
    bgCanvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(bgCanvas)
    for i = 0, 60 do
        local t = i / 60
        love.graphics.setColor(0.08 + t * 0.07, 0.02 + t * 0.05, 0.18 + t * 0.3)
        love.graphics.rectangle("fill", 0, i * (h / 60), w, h / 60 + 1)
    end
    love.graphics.setCanvas()
end

-- ============================================================
-- АКТИВАЦИЯ ПРОМО-КОДА
-- ============================================================
local function activatePromoCode()
    local code = string.upper(promoInput or "")
    
    if code == "" then
        promoResult = "Enter a code!"
        promoResultColor = {1, 0.3, 0.3}
        return
    end
    
    if not promoCodes[code] then
        promoResult = "Invalid code!"
        promoResultColor = {1, 0.3, 0.3}
        return
    end
    
    local promo = promoCodes[code]
    
    if usedByPlayer[code] then
        promoResult = "Already used!"
        promoResultColor = {1, 0.3, 0.3}
        return
    end
    
    if promo.used >= promo.maxUses then
        promoResult = "Code expired!"
        promoResultColor = {1, 0.3, 0.3}
        return
    end
    
    promo.used = promo.used + 1
    usedByPlayer[code] = true
    coins = (coins or 0) + promo.reward
    
    saveGame()
    savePromoCodes()
    
    promoResult = promo.description .. " +" .. promo.reward .. " coins!"
    promoResultColor = {0.3, 1, 0.3}
    promoInput = ""
    promoCooldown = 2
end

-- ============================================================
-- ЗАГРУЗКА ЛОББИ
-- ============================================================
function lobby.load()
    -- Пробуем загрузить шрифт с кириллицей
    local success, err = pcall(function()
        -- Сначала пробуем системный шрифт
        fontTitle = love.graphics.newFont("Arial.ttf", 48)
    end)
    if not success then
        success, err = pcall(function()
            -- Пробуем Fredoka (если есть)
            fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 48)
        end)
    end
    if not success then
        -- Если ничего нет, используем стандартный шрифт
        fontTitle = love.graphics.newFont(48)
    end
    
    success, err = pcall(function()
        fontBtn = love.graphics.newFont("Arial.ttf", 20)
    end)
    if not success then
        success, err = pcall(function()
            fontBtn = love.graphics.newFont("Fredoka-Bold.ttf", 20)
        end)
    end
    if not success then
        fontBtn = love.graphics.newFont(20)
    end
    
    loadSave()
    loadPromoCodes()
    createBG()
    
    stars = {}
    for i = 1, 50 do
        table.insert(stars, { x = math.random(), y = math.random(), s = 0.1 + math.random() * 0.4 })
    end
end

function lobby.update(dt)
    animTimer = animTimer + dt
    
    if promoCooldown > 0 then
        promoCooldown = promoCooldown - dt
    end
end

-- ============================================================
-- РИСОВАНИЕ
-- ============================================================
function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    -- ФОН
    love.graphics.setColor(1, 1, 1)
    if bgCanvas then
        love.graphics.draw(bgCanvas)
    end
    
    -- ЗВЕЗДЫ
    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, 0.3 + 0.3 * math.sin(animTimer * 2 + s.x * 10))
        love.graphics.circle("fill",
            (s.x * w + animTimer * 20 * s.s) % w,
            (s.y * h + animTimer * 10 * s.s) % h,
            1.5 + s.s
        )
    end
    
    -- ЗАГОЛОВОК
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 3, h / 2 - 177, w, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CUBIC BATTLE", 0, h / 2 - 180, w, "center")
    
    -- ПОДЗАГОЛОВОК
    love.graphics.setColor(0.5, 0.3, 1, 0.6)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SURVIVE & COLLECT", 0, h / 2 - 130, w, "center")
    
    -- МОНЕТЫ
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.circle("fill", w/2 - 80, h / 2 - 70, 14)
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.circle("fill", w/2 - 80, h / 2 - 70, 9)
    love.graphics.setColor(1, 0.7, 0)
    love.graphics.circle("fill", w/2 - 80, h / 2 - 70, 5)
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("x " .. (coins or 0), w/2 - 55, h / 2 - 82, 100, "left")
    
    -- КНОПКИ
    local bx = w / 2 - 120
    
    -- PLAY
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, h / 2 - 17, 240, 50, 12)
    love.graphics.setColor(0.2, 0.6, 0.8, 0.95)
    love.graphics.rectangle("fill", bx, h / 2 - 20, 240, 50, 12)
    love.graphics.setColor(0.3, 0.8, 1, 0.2)
    love.graphics.rectangle("fill", bx + 5, h / 2 - 15, 230, 15, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("PLAY", bx, h / 2 - 5, 240, "center")
    
    -- SHOP
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, h / 2 + 48, 240, 50, 12)
    love.graphics.setColor(0.4, 0.2, 0.8, 0.95)
    love.graphics.rectangle("fill", bx, h / 2 + 45, 240, 50, 12)
    love.graphics.setColor(0.6, 0.3, 1, 0.2)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 50, 230, 15, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SHOP", bx, h / 2 + 60, 240, "center")
    
    -- PROMO CODE
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, h / 2 + 113, 240, 40, 10)
    love.graphics.setColor(0.8, 0.2, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 + 110, 240, 40, 10)
    love.graphics.setColor(0.9, 0.3, 0.9, 0.2)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 115, 230, 12, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("PROMO CODE", bx, h / 2 + 123, 240, "center")
    
    -- ПОЛЕ ВВОДА ПРОМО-КОДА
    if promoActive then
        local inputX = bx
        local inputY = h / 2 + 160
        local inputW = 240
        local inputH = 40
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", inputX + 3, inputY + 3, inputW, inputH, 8)
        
        love.graphics.setColor(0.1, 0.05, 0.2, 0.95)
        love.graphics.rectangle("fill", inputX, inputY, inputW, inputH, 8)
        
        love.graphics.setColor(0.5, 0.2, 1, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", inputX, inputY, inputW, inputH, 8)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontBtn)
        local displayText = promoInput or ""
        if displayText == "" then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf("Enter code...", inputX + 15, inputY + 10, inputW - 80, "left")
        else
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf(displayText, inputX + 15, inputY + 10, inputW - 80, "left")
        end
        
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", inputX + inputW - 57, inputY + 8, 52, 30, 6)
        love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", inputX + inputW - 60, inputY + 5, 55, 30, 6)
        love.graphics.setColor(0.3, 1, 0.3, 0.2)
        love.graphics.rectangle("fill", inputX + inputW - 57, inputY + 8, 49, 12, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("OK", inputX + inputW - 60, inputY + 10, 55, "center")
        
        if promoResult ~= "" then
            love.graphics.setColor(promoResultColor)
            love.graphics.setFont(fontBtn)
            love.graphics.printf(promoResult, inputX, inputY + 50, inputW, "center")
        end
    end
    
    -- МАГАЗИН
    if shop_open then
        drawShop()
    end
    
    -- НИЖНЯЯ ПАНЕЛЬ
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, h - 30, w, 30)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("ESC - Exit | WASD - Move | SPACE - Shot", 0, h - 24, w, "center")
end

-- ============================================================
-- МАГАЗИН
-- ============================================================
function drawShop()
    local w, h = love.graphics.getDimensions()
    local shop_w, shop_h = 420, 320
    local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30
    
    -- Тень
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", shop_x + 10, shop_y + 10, shop_w, shop_h, 15)
    
    -- Фон
    love.graphics.setColor(0.08, 0.04, 0.15, 0.97)
    love.graphics.rectangle("fill", shop_x, shop_y, shop_w, shop_h, 15)
    
    -- Рамка
    love.graphics.setColor(0.5, 0.2, 1, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12)
    
    -- Заголовок
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("SHOP", shop_x + 20, shop_y + 15, 200, "left")
    
    -- Кнопка закрыть
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", shop_x + shop_w - 77, shop_y + 13, 62, 30, 8)
    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", shop_x + shop_w - 80, shop_y + 10, 60, 30, 8)
    love.graphics.setColor(1, 0.3, 0.3, 0.2)
    love.graphics.rectangle("fill", shop_x + shop_w - 77, shop_y + 13, 54, 12, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("X", shop_x + shop_w - 78, shop_y + 17, 56, "center")
    
    -- Линия
    love.graphics.setColor(0.5, 0.2, 1, 0.2)
    love.graphics.rectangle("fill", shop_x + 20, shop_y + 70, shop_w - 40, 2)
    
    -- Баланс
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Balance: " .. coins, shop_x + shop_w - 180, shop_y + 15, 150, "right")
    
    -- ТОВАР
    local item_x, item_y = shop_x + 20, shop_y + 85
    local item_w, item_h = shop_w - 40, 70
    
    -- Фон товара
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", item_x + 3, item_y + 3, item_w, item_h, 8)
    love.graphics.setColor(0.2, 0.1, 0.4, 0.8)
    love.graphics.rectangle("fill", item_x, item_y, item_w, item_h, 8)
    
    -- Рамка товара
    love.graphics.setColor(0.5, 0.2, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", item_x, item_y, item_w, item_h, 8)
    
    -- Иконка бриллианта
    love.graphics.setColor(0, 0.8, 1, 0.8)
    love.graphics.polygon("fill",
        item_x + 35, item_y + 20,
        item_x + 50, item_y + 8,
        item_x + 65, item_y + 20,
        item_x + 50, item_y + 55,
        item_x + 35, item_y + 20
    )
    
    -- Блик
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.polygon("fill",
        item_x + 42, item_y + 15,
        item_x + 48, item_y + 20,
        item_x + 42, item_y + 25
    )
    
    -- Название
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Diamond Cube", item_x + 80, item_y + 12, 150, "left")
    
    -- Цена
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    if skins.diamond.owned then
        love.graphics.printf("OWNED", item_x + 80, item_y + 35, 150, "left")
    else
        love.graphics.printf("100 coins", item_x + 80, item_y + 35, 150, "left")
    end
    
    -- Кнопка
    if skins.diamond.owned then
        if selected_skin == "diamond" then
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 62, 30, 8)
            love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(0.3, 1, 0.3, 0.2)
            love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 54, 12, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(fontBtn)
            love.graphics.printf("ON", item_x + item_w - 78, item_y + 22, 56, "center")
        else
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 62, 30, 8)
            love.graphics.setColor(0.2, 0.6, 1, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(0.3, 0.8, 1, 0.2)
            love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 54, 12, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(fontBtn)
            love.graphics.printf("EQUIP", item_x + item_w - 78, item_y + 22, 56, "center")
        end
    else
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 62, 30, 8)
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
        love.graphics.setColor(1, 0.9, 0.3, 0.2)
        love.graphics.rectangle("fill", item_x + item_w - 77, item_y + 18, 54, 12, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("BUY", item_x + item_w - 78, item_y + 22, 56, "center")
    end
end

-- ============================================================
-- ОБРАБОТКА КАСАНИЙ/КЛИКОВ
-- ============================================================
function lobby.touchpressed(id, x, y)
    local w, h = love.graphics.getDimensions()
    local bx = w / 2 - 120
    
    if x >= bx and x <= bx + 240 then
        if y >= h / 2 - 20 and y <= h / 2 + 30 then
            playSound("click")
            local g = require("game")
            g.setCoins(coins)
            g.setSkin(selected_skin)
            g.load()
            _G.GameState.current = "game"
            return
        end
        
        if y >= h / 2 + 45 and y <= h / 2 + 95 then
            playSound("click")
            shop_open = not shop_open
            return
        end
        
        if y >= h / 2 + 110 and y <= h / 2 + 150 then
            playSound("click")
            promoActive = not promoActive
            if promoActive then
                promoInput = ""
                promoResult = ""
                love.keyboard.setTextInput(true)
            else
                love.keyboard.setTextInput(false)
            end
            return
        end
    end
    
    if promoActive then
        local inputX = bx
        local inputY = h / 2 + 160
        local inputW = 240
        local inputH = 40
        
        if x >= inputX and x <= inputX + inputW - 60 and y >= inputY and y <= inputY + inputH then
            love.keyboard.setTextInput(true)
            return
        end
        
        if x >= inputX + inputW - 60 and x <= inputX + inputW and y >= inputY + 5 and y <= inputY + 35 then
            if promoCooldown <= 0 then
                activatePromoCode()
            end
            return
        end
    end
    
    if shop_open then
        local shop_w, shop_h = 420, 320
        local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30
        
        if x >= shop_x + shop_w - 80 and x <= shop_x + shop_w - 20 and
           y >= shop_y + 10 and y <= shop_y + 40 then
            shop_open = false
            playSound("click")
            return
        end
        
        local item_x, item_y = shop_x + 20, shop_y + 85
        local item_w, item_h = shop_w - 40, 70
        if x >= item_x + item_w - 80 and x <= item_x + item_w - 20 and
           y >= item_y + 15 and y <= item_y + 45 then
            playSound("click")
            if not skins.diamond.owned and coins >= 100 then
                coins = coins - 100
                skins.diamond.owned = true
                selected_skin = "diamond"
                saveGame()
            elseif skins.diamond.owned then
                selected_skin = "diamond"
                saveGame()
            end
            return
        end
    end
end

function lobby.touchreleased(id, x, y)
end

function lobby.resize()
    createBG()
end

-- ============================================================
-- КЛАВИАТУРА
-- ============================================================
function lobby.keypressed(key)
    if key == "escape" then
        if shop_open then
            shop_open = false
        elseif promoActive then
            promoActive = false
            love.keyboard.setTextInput(false)
        end
    end
    
    if key == "backspace" and promoActive then
        promoInput = promoInput:sub(1, -2)
    end
    
    if key == "return" or key == "enter" then
        if promoActive and promoCooldown <= 0 then
            activatePromoCode()
        end
    end
end

function lobby.handleTextInput(text)
    if promoActive then
        promoInput = promoInput .. text
    end
end

return lobby
