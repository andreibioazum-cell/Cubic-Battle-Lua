 local lobby = {}
local keyboard = require("game_keyboard")

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

-- ВСТРОЕННЫЕ ПРОМО-КОДЫ (без отдельного модуля)
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

local function saveGame()
    local data = string.format("%d\n%s\n%s", coins, skins.diamond.owned and "diamond" or "default", selected_skin)
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

-- ЗАГРУЗКА ПРОМО-КОДОВ
local function loadPromoCodes()
    local stats = love.filesystem.read("promo_stats.txt")
    if stats then
        for line in stats:gmatch("[^\r\n]+") do
            local code, uses = line:match("([^:]+):(%d+)")
            if code and uses and promoCodes[code] then
                promoCodes[code].used = tonumber(uses) or 0
            end
        end
    end
end

local function savePromoCodes()
    local stats = ""
    for code, info in pairs(promoCodes) do
        stats = stats .. code .. ":" .. info.used .. "\n"
    end
    love.filesystem.write("promo_stats.txt", stats)
end

function lobby.load()
    local success1, err1 = pcall(function()
        fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 48)
    end)
    if not success1 then
        fontTitle = love.graphics.newFont(48)
    end
    
    local success2, err2 = pcall(function()
        fontBtn = love.graphics.newFont("Fredoka-Bold.ttf", 20)
    end)
    if not success2 then
        fontBtn = love.graphics.newFont(20)
    end
    
    loadSave()
    loadPromoCodes()
    createBG()
    stars = {}
    for i = 1, 50 do
        table.insert(stars, { x = math.random(), y = math.random(), s = 0.1 + math.random() * 0.4 })
    end
    
    keyboard.init()
end

function lobby.update(dt)
    animTimer = animTimer + dt
    
    if promoCooldown > 0 then
        promoCooldown = promoCooldown - dt
    end
    
    if keyboard.isActive() then
        keyboard.update(dt)
    end
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1)
    if bgCanvas then
        love.graphics.draw(bgCanvas)
    end

    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, 0.3 + 0.3 * math.sin(animTimer * 2 + s.x * 10))
        love.graphics.circle("fill",
            (s.x * w + animTimer * 20 * s.s) % w,
            (s.y * h + animTimer * 10 * s.s) % h,
            1.5 + s.s
        )
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE 3", 0, h / 2 - 180, w, "center")

    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Cubicoins: " .. coins, 0, h / 2 - 80, w, "center")

    local bx = w / 2 - 120
    
    -- PLAY
    love.graphics.setColor(0.2, 0.6, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 - 20, 240, 50, 10)
    love.graphics.setColor(0.3, 0.8, 1, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 - 15, 230, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("PLAY", bx, h / 2 - 5, 240, "center")

    -- SHOP
    love.graphics.setColor(0.4, 0.2, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 + 45, 240, 50, 10)
    love.graphics.setColor(0.6, 0.3, 1, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 50, 230, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SHOP", bx, h / 2 + 60, 240, "center")

    -- PROMO CODE
    love.graphics.setColor(0.8, 0.2, 0.8, 0.8)
    love.graphics.rectangle("fill", bx, h / 2 + 110, 240, 40, 10)
    love.graphics.setColor(0.9, 0.3, 0.9, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 115, 230, 30, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("PROMO CODE", bx, h / 2 + 123, 240, "center")

    if promoActive then
        local inputX = bx
        local inputY = h / 2 + 160
        local inputW = 240
        local inputH = 40
        
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
            love.graphics.printf("Tap to enter code...", inputX + 10, inputY + 10, inputW - 20, "left")
        else
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf(displayText, inputX + 10, inputY + 10, inputW - 20, "left")
        end
        
        love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", inputX + inputW - 60, inputY + 5, 55, 30, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("OK", inputX + inputW - 60, inputY + 10, 55, "center")
        
        if promoResult ~= "" then
            love.graphics.setColor(promoResultColor)
            love.graphics.setFont(fontBtn)
            love.graphics.printf(promoResult, inputX, inputY + 50, inputW, "center")
        end
    end

    if shop_open then
        drawShop()
    end
    
    if keyboard.isActive() then
        keyboard.draw()
    end
end

function drawShop()
    local w, h = love.graphics.getDimensions()
    local shop_w, shop_h = 400, 300
    local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", shop_x + 10, shop_y + 10, shop_w, shop_h, 15)

    love.graphics.setColor(0.1, 0.05, 0.2, 0.95)
    love.graphics.rectangle("fill", shop_x, shop_y, shop_w, shop_h, 15)

    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12)

    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", shop_x + shop_w - 80, shop_y + 10, 60, 30, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("X", shop_x + shop_w - 78, shop_y + 17, 56, "center")

    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("SHOP", shop_x + 20, shop_y + 15, 200, "left")

    love.graphics.setColor(0.5, 0.2, 1, 0.2)
    love.graphics.rectangle("fill", shop_x + 20, shop_y + 70, shop_w - 40, 2)

    local item_x, item_y = shop_x + 20, shop_y + 85
    local item_w, item_h = shop_w - 40, 60

    love.graphics.setColor(0.2, 0.1, 0.4, 0.8)
    love.graphics.rectangle("fill", item_x, item_y, item_w, item_h, 8)

    love.graphics.setColor(0, 0.8, 1, 0.8)
    love.graphics.polygon("fill",
        item_x + 30, item_y + 15,
        item_x + 45, item_y + 5,
        item_x + 60, item_y + 15,
        item_x + 45, item_y + 50,
        item_x + 30, item_y + 15
    )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Diamond Cube", item_x + 70, item_y + 12, 150, "left")
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("100 Cubicoins", item_x + 70, item_y + 35, 150, "left")

    if skins.diamond.owned then
        if selected_skin == "diamond" then
            love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fontBtn)
            love.graphics.printf("ON", item_x + item_w - 78, item_y + 22, 56, "center")
        else
            love.graphics.setColor(0.2, 0.6, 1, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(fontBtn)
            love.graphics.printf("EQUIP", item_x + item_w - 78, item_y + 22, 56, "center")
        end
    else
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("BUY", item_x + item_w - 78, item_y + 22, 56, "center")
    end
end

function lobby.touchpressed(id, x, y)
    local w, h = love.graphics.getDimensions()

    if keyboard.isActive() then
        if keyboard.handleTouch(x, y) then
            promoInput = keyboard.getInput()
            return
        end
    end

    local bx = w / 2 - 120
    
    -- PLAY
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
        
        -- SHOP
        if y >= h / 2 + 45 and y <= h / 2 + 95 then
            playSound("click")
            shop_open = not shop_open
            return
        end
        
        -- PROMO CODE
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
    
    -- PROMO CODE INPUT
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

    -- SHOP
    if shop_open then
        local shop_w, shop_h = 400, 300
        local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30

        if x >= shop_x + shop_w - 80 and x <= shop_x + shop_w - 20 and
           y >= shop_y + 10 and y <= shop_y + 40 then
            shop_open = false
            playSound("click")
            return
        end

        local item_x, item_y = shop_x + 20, shop_y + 85
        local item_w, item_h = shop_w - 40, 60
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

function activatePromoCode()
    local code = string.upper(promoInput or "")
    
    if code == "" then
        promoResult = "Please enter a code!"
        promoResultColor = {1, 0.3, 0.3}
        return
    end
    
    -- Проверка кода
    if not promoCodes[code] then
        promoResult = "Invalid promo code!"
        promoResultColor = {1, 0.3, 0.3}
        playSound("error")
        return
    end
    
    local promo = promoCodes[code]
    
    -- Проверка использовался ли уже
    if usedByPlayer[code] then
        promoResult = "You already used this code!"
        promoResultColor = {1, 0.3, 0.3}
        playSound("error")
        return
    end
    
    -- Проверка лимита
    if promo.used >= promo.maxUses then
        promoResult = "This code is no longer active!"
        promoResultColor = {1, 0.3, 0.3}
        playSound("error")
        return
    end
    
    -- Активация
    promo.used = promo.used + 1
    usedByPlayer[code] = true
    coins = coins + promo.reward
    saveGame()
    savePromoCodes()
    
    promoResult = promo.description .. " +" .. promo.reward .. " coins!"
    promoResultColor = {0.3, 1, 0.3}
    playSound("success")
    
    promoInput = ""
    promoCooldown = 2
    
    if keyboard.isActive() then
        keyboard.hide()
    end
end

function lobby.handleTextInput(text)
    if promoActive then
        promoInput = promoInput .. text
    end
end

function lobby.keypressed(key)
    if key == "backspace" and promoActive then
        promoInput = promoInput:sub(1, -2)
    end
    
    if key == "return" or key == "enter" then
        if promoActive and promoCooldown <= 0 then
            activatePromoCode()
        end
    end
end

return lobby
