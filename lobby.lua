local lobby = {}

local fontTitle, fontBtn
local animTimer = 0
local game = nil
local coins = 0
local shop_open = false

-- Загрузка сохранений
local function loadSave()
    local success, data = pcall(love.filesystem.read, "save.txt")
    if success and data then
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        if #lines >= 1 then
            coins = tonumber(lines[1]) or 0
        end
        if #lines >= 2 then
            if lines[2] == "diamond" then
                skins.diamond.owned = true
            end
        end
        if #lines >= 3 then
            selected_skin = lines[3] or "default"
        end
    end
end

-- Сохранение
local function saveGame()
    local data = tostring(coins) .. "\n"
    if skins.diamond.owned then
        data = data .. "diamond\n"
    else
        data = data .. "default\n"
    end
    data = data .. selected_skin .. "\n"
    love.filesystem.write("save.txt", data)
end

-- Скины
local skins = {
    default = {
        name = "Default Cube",
        color = {1, 1, 1},
        ability = nil,
        ability_name = "None",
        price = 0,
        owned = true
    },
    diamond = {
        name = "Diamond Cube",
        color = {0.2, 0.8, 1},
        ability = "shield",
        ability_name = "Shield",
        ability_desc = "Blocks 1 hit every 10 sec",
        price = 100,
        owned = false
    }
}

local selected_skin = "default"

local function tryLoadGame()
    if not game then
        game = require("game")
    end
    return game
end

local function startGame()
    local g = tryLoadGame()
    if g then
        -- Передаём данные в игру
        g.setCoins(coins)
        g.setSkin(selected_skin)
        g.load()
        GameState.current = "game"
    end
end

local function buySkin(skin_name)
    if skins[skin_name] and not skins[skin_name].owned then
        if coins >= skins[skin_name].price then
            coins = coins - skins[skin_name].price
            skins[skin_name].owned = true
            selected_skin = skin_name
            saveGame()
            print("✅ " .. skins[skin_name].name .. " purchased!")
        else
            print("❌ Not enough coins!")
        end
    elseif skins[skin_name] and skins[skin_name].owned then
        selected_skin = skin_name
        saveGame()
        print("✅ " .. skins[skin_name].name .. " equipped!")
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
    
    makeButton("⚔ PLAY", startY, startGame, {0.2, 0.6, 0.8})
    makeButton("🛒 SHOP", startY + 65, function()
        shop_open = not shop_open
    end, {0.4, 0.2, 0.8})
end

-- ============================================================
-- ОТРИСОВКА МАГАЗИНА В ЛОББИ
-- ============================================================

local function drawShop()
    local w, h = love.graphics.getDimensions()
    local shop_w = 400
    local shop_h = 350
    local shop_x = w/2 - shop_w/2
    local shop_y = h/2 - shop_h/2 + 50
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", shop_x, shop_y, shop_w, shop_h, 16, 16)
    love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
    love.graphics.rectangle("fill", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12, 12)
    love.graphics.setColor(0.4, 0.4, 0.6, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12, 12)
    
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontTitle)
    love.graphics.print("🛒 SHOP", shop_x + 20, shop_y + 15)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(fontBtn)
    love.graphics.print("💰 Coins: " .. coins, shop_x + 20, shop_y + 55)
    
    -- Алмазный куб
    local item_x = shop_x + 20
    local item_y = shop_y + 90
    local item_w = shop_w - 40
    local item_h = 80
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", item_x, item_y, item_w, item_h, 8, 8)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", item_x, item_y, item_w, item_h, 8, 8)
    
    love.graphics.setColor(0.2, 0.8, 1, 0.9)
    love.graphics.setFont(fontBtn)
    love.graphics.print("💎 Diamond Cube", item_x + 10, item_y + 8)
    love.graphics.setColor(0.7, 0.7, 0.9, 0.7)
    love.graphics.print("🛡️ Shield (blocks 1 hit / 10 sec)", item_x + 10, item_y + 32)
    love.graphics.setColor(1, 1, 0, 0.8)
    
    if skins.diamond.owned then
        if selected_skin == "diamond" then
            love.graphics.setColor(0, 1, 0, 0.9)
            love.graphics.print("✅ EQUIPPED", item_x + item_w - 100, item_y + 8)
        else
            love.graphics.setColor(0.3, 0.8, 0.3, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 90, item_y + 8, 70, 25, 6, 6)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("EQUIP", item_x + item_w - 75, item_y + 13)
        end
    else
        love.graphics.print("💰 " .. skins.diamond.price .. " coins", item_x + item_w - 110, item_y + 8)
        if coins >= skins.diamond.price then
            love.graphics.setColor(0.2, 0.8, 0.3, 0.9)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        end
        love.graphics.rectangle("fill", item_x + item_w - 90, item_y + 32, 70, 25, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BUY", item_x + item_w - 75, item_y + 37)
    end
    
    -- Кнопка закрытия
    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", shop_x + shop_w - 80, shop_y + shop_h - 45, 60, 30, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("CLOSE", shop_x + shop_w - 65, shop_y + shop_h - 38)
end

-- ============================================================
-- ОСНОВНЫЕ ФУНКЦИИ
-- ============================================================

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont("Fredoka-Bold.ttf", 48)
    fontBtn = fontBtn or love.graphics.newFont("Fredoka-Bold.ttf", 20)
    
    loadSave()
    tryLoadGame()
    updateButtons()
    animTimer = 0
    shop_open = false
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
    love.graphics.printf("CUBIC BATTLE 3", 0, titleY, w, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.9, 0.5)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Open World Arena", 0, titleY + 55, w, "center")
    
    -- 💰 ПОКАЗ МОНЕТ
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("💰 " .. coins, 0, titleY + 100, w, "center")
    
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
    
    -- Магазин
    if shop_open then
        drawShop()
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- ============================================================
-- ОБРАБОТКА КАСАНИЙ
-- ============================================================

function lobby.touchpressed(id, x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local bw, bh = 240, 50
    
    -- Магазин
    if shop_open then
        local shop_w = 400
        local shop_h = 350
        local shop_x = w/2 - shop_w/2
        local shop_y = h/2 - shop_h/2 + 50
        
        -- Кнопка CLOSE
        if x >= shop_x + shop_w - 80 and x <= shop_x + shop_w - 20 and 
           y >= shop_y + shop_h - 45 and y <= shop_y + shop_h - 15 then
            shop_open = false
            return
        end
        
        -- Кнопка BUY/EQUIP (Diamond Cube)
        local item_x = shop_x + 20
        local item_y = shop_y + 90
        local item_w = shop_w - 40
        
        if skins.diamond.owned then
            -- Кнопка EQUIP
            if x >= item_x + item_w - 90 and x <= item_x + item_w - 20 and
               y >= item_y + 8 and y <= item_y + 33 then
                buySkin("diamond")
                saveGame()
                return
            end
        else
            -- Кнопка BUY
            if x >= item_x + item_w - 90 and x <= item_x + item_w - 20 and
               y >= item_y + 32 and y <= item_y + 57 then
                buySkin("diamond")
                saveGame()
                return
            end
        end
        return
    end
    
    -- Кнопки меню
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

function lobby.mousepressed(x, y)
    lobby.touchpressed(1, x, y)
end

function lobby.resize()
    updateButtons()
end

return lobby
