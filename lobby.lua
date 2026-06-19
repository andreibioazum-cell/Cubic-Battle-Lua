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
local showInstallMenu = false
local installer = nil

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

function lobby.load()
    fontTitle = love.graphics.newFont("Fredoka-Bold.ttf", 48)
    fontBtn = love.graphics.newFont("Fredoka-Bold.ttf", 20)
    loadSave()
    createBG()
    stars = {}
    for i = 1, 50 do
        table.insert(stars, { x = math.random(), y = math.random(), s = 0.1 + math.random() * 0.4 })
    end
    
    -- Загружаем установщик
    installer = require("game_installer")
end

function lobby.update(dt)
    animTimer = animTimer + dt
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

    -- Кнопки
    local bx = w / 2 - 120
    
    -- PLAY
    love.graphics.setColor(0.2, 0.6, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 - 20, 240, 50, 10)
    love.graphics.setColor(0.3, 0.8, 1, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 - 15, 230, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("▶ PLAY", bx, h / 2 - 5, 240, "center")

    -- SHOP
    love.graphics.setColor(0.4, 0.2, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 + 45, 240, 50, 10)
    love.graphics.setColor(0.6, 0.3, 1, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 50, 230, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("🛒 SHOP", bx, h / 2 + 60, 240, "center")

    -- КНОПКА УСТАНОВКИ МОДОВ
    love.graphics.setColor(0.8, 0.2, 0.8, 0.9)
    love.graphics.rectangle("fill", bx, h / 2 + 110, 240, 40, 10)
    love.graphics.setColor(0.9, 0.3, 0.9, 0.3)
    love.graphics.rectangle("fill", bx + 5, h / 2 + 115, 230, 30, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("📦 УПРАВЛЕНИЕ МОДАМИ", bx, h / 2 + 123, 240, "center")

    -- Кнопка безопасного режима
    love.graphics.setColor(0.8, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", w - 130, 10, 120, 30, 8)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("🔒 Safe Mode", w - 130, 15, 120, "center")

    if shop_open then
        drawShop()
    end
    
    if showInstallMenu then
        drawInstallMenu()
    end
    
    -- Информация об установленном моде
    local installedMod = installer and installer.getInstalledMod()
    if installedMod then
        love.graphics.setColor(0, 1, 0, 0.6)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("📦 Мод: " .. installedMod.title, 10, h - 40, 300, "left")
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.printf("v" .. installedMod.version, 10, h - 20, 300, "left")
    end
end

-- ============================================================
-- МЕНЮ УПРАВЛЕНИЯ МОДАМИ
-- ============================================================

function drawInstallMenu()
    local w, h = love.graphics.getDimensions()
    local menu_w, menu_h = 500, 400
    local menu_x, menu_y = w / 2 - menu_w / 2, h / 2 - menu_h / 2

    -- Тень
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", menu_x + 10, menu_y + 10, menu_w, menu_h, 15)

    -- Фон
    love.graphics.setColor(0.1, 0.05, 0.2, 0.95)
    love.graphics.rectangle("fill", menu_x, menu_y, menu_w, menu_h, 15)

    -- Рамка
    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", menu_x + 5, menu_y + 5, menu_w - 10, menu_h - 10, 12)

    -- Заголовок
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("📦 УПРАВЛЕНИЕ МОДАМИ", menu_x + 20, menu_y + 20, menu_w - 40, "center")

    -- Кнопка закрыть
    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", menu_x + menu_w - 80, menu_y + 15, 60, 30, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("✕", menu_x + menu_w - 80, menu_y + 22, 60, "center")

    local y_offset = 80
    
    -- Информация об установленном моде
    local installedMod = installer and installer.getInstalledMod()
    if installedMod then
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.setFont(fontBtn)
        love.graphics.printf("✅ Установлен мод:", menu_x + 20, menu_y + y_offset, menu_w - 40, "left")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("   " .. installedMod.title, menu_x + 20, menu_y + y_offset + 25, menu_w - 40, "left")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("   Автор: " .. installedMod.author, menu_x + 20, menu_y + y_offset + 45, menu_w - 40, "left")
        love.graphics.printf("   Версия: " .. installedMod.version, menu_x + 20, menu_y + y_offset + 65, menu_w - 40, "left")
        
        -- Кнопка удаления
        love.graphics.setColor(0.8, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", menu_x + 20, menu_y + y_offset + 90, menu_w - 40, 40, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("🗑️ УДАЛИТЬ МОД", menu_x + 20, menu_y + y_offset + 102, menu_w - 40, "center")
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("📭 Нет установленных модов", menu_x + 20, menu_y + y_offset + 10, menu_w - 40, "center")
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
        love.graphics.printf("Загрузите мод на сайте и установите его", menu_x + 20, menu_y + y_offset + 35, menu_w - 40, "center")
    end

    -- Кнопка открыть сайт
    love.graphics.setColor(0.2, 0.6, 1, 0.9)
    love.graphics.rectangle("fill", menu_x + 20, menu_y + menu_h - 60, menu_w - 40, 40, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("🌐 ОТКРЫТЬ САЙТ С МОДАМИ", menu_x + 20, menu_y + menu_h - 48, menu_w - 40, "center")
end

-- ============================================================
-- МАГАЗИН
-- ============================================================

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
    love.graphics.printf("✕ CLOSE", shop_x + shop_w - 78, shop_y + 17, 56, "center")

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
    love.graphics.printf("100 Cubicoins", item_x + 70, item_y + 35, 150, "left")

    if skins.diamond.owned then
        if selected_skin == "diamond" then
            love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("✓ ON", item_x + item_w - 78, item_y + 22, 56, "center")
        else
            love.graphics.setColor(0.2, 0.6, 1, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("EQUIP", item_x + item_w - 78, item_y + 22, 56, "center")
        end
    else
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", item_x + item_w - 80, item_y + 15, 60, 30, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("BUY", item_x + item_w - 78, item_y + 22, 56, "center")
    end
end

-- ============================================================
-- ОБРАБОТКА НАЖАТИЙ
-- ============================================================

function lobby.touchpressed(id, x, y)
    local w, h = love.graphics.getDimensions()

    -- Кнопка Safe Mode
    if x >= w - 130 and x <= w - 10 and y >= 10 and y <= 40 then
        playSound("click")
        if installer then
            installer.enterSafeMode()
        end
        return
    end

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
        end
        return
    end
    
    if showInstallMenu then
        local menu_w, menu_h = 500, 400
        local menu_x, menu_y = w / 2 - menu_w / 2, h / 2 - menu_h / 2
        
        -- Кнопка закрыть
        if x >= menu_x + menu_w - 80 and x <= menu_x + menu_w - 20 and
           y >= menu_y + 15 and y <= menu_y + 45 then
            showInstallMenu = false
            playSound("click")
            return
        end
        
        -- Кнопка удалить мод
        if x >= menu_x + 20 and x <= menu_x + menu_w - 20 and
           y >= menu_y + 170 and y <= menu_y + 210 then
            playSound("click")
            if installer then
                local installedMod = installer.getInstalledMod()
                if installedMod then
                    local success = installer.uninstallMod()
                    if success then
                        showInstallMenu = false
                    end
                end
            end
            return
        end
        
        -- Кнопка открыть сайт
        if x >= menu_x + 20 and x <= menu_x + menu_w - 20 and
           y >= menu_y + menu_h - 60 and y <= menu_y + menu_h - 20 then
            playSound("click")
            love.system.openURL("https://ваш-сайт.com/mods")
            return
        end
        
        return
    end

    -- Главные кнопки
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
            shop_open = true
            return
        end
        
        -- УПРАВЛЕНИЕ МОДАМИ
        if y >= h / 2 + 110 and y <= h / 2 + 150 then
            playSound("click")
            showInstallMenu = true
            return
        end
    end
end

function lobby.resize()
    createBG()
end

return lobby
