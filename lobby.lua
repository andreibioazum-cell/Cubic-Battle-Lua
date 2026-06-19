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
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("fill",
            (s.x * w + animTimer * 20 * s.s) % w,
            (s.y * h + animTimer * 10 * s.s) % h,
            1.5
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
    love.graphics.setColor(0.2, 0.6, 0.8)
    love.graphics.rectangle("fill", bx, h / 2 - 20, 240, 50, 10)
    love.graphics.setColor(0.4, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, h / 2 + 45, 240, 50, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PLAY", bx, h / 2 - 5, 240, "center")
    love.graphics.printf("SHOP", bx, h / 2 + 60, 240, "center")

    if shop_open then
        lobby.drawShop()
    end
end

function lobby.drawShop()
    local w, h = love.graphics.getDimensions()
    local sx, sy = w / 2 - 200, h / 2 - 150
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", sx, sy, 400, 350, 15)

    -- Кнопка BACK сверху по центру
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", sx + 150, sy + 10, 100, 35, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("BACK", sx + 150, sy + 18, 100, "center")

    -- Заголовок
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SHOP - Diamond Cube (100C)", sx + 20, sy + 70, 360, "center")

    -- Кнопка BUY / EQUIP
    if skins.diamond.owned then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", sx + 20, sy + 110, 360, 40, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(selected_skin == "diamond" and "EQUIPPED" or "EQUIP", sx + 20, sy + 120, 360, "center")
    else
        love.graphics.setColor(0.8, 0.8, 0.2)
        love.graphics.rectangle("fill", sx + 20, sy + 110, 360, 40, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("BUY", sx + 20, sy + 120, 360, "center")
    end
end

function lobby.touchpressed(id, x, y)
    local w, h = love.graphics.getDimensions()

    if shop_open then
        local sx, sy = w / 2 - 200, h / 2 - 150
        -- Кнопка BACK
        if x > sx + 150 and x < sx + 250 and y > sy + 10 and y < sy + 45 then
            shop_open = false
            return
        end
        -- Кнопка BUY / EQUIP
        if x > sx + 20 and x < sx + 380 and y > sy + 110 and y < sy + 150 then
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

    -- Главные кнопки
    if x > w / 2 - 120 and x < w / 2 + 120 then
        if y > h / 2 - 20 and y < h / 2 + 30 then
            local g = require("game")
            g.setCoins(coins)
            g.setSkin(selected_skin)
            g.load()
            _G.GameState.current = "game"
        elseif y > h / 2 + 45 and y < h / 2 + 95 then
            shop_open = true
        end
    end
end

function lobby.resize()
    createBG()
end

return lobby
