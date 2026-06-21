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

local function createBG()
    local w, h = love.graphics.getDimensions()
    if w <= 0 or h <= 0 then return end
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
    fontTitle = love.graphics.newFont(48)
    fontBtn = love.graphics.newFont(20)
    
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
    if w <= 0 or h <= 0 then return end
    
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
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("CUBIC BATTLE", 3, h / 2 - 177, w, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CUBIC BATTLE", 0, h / 2 - 180, w, "center")
    
    love.graphics.setColor(0.5, 0.3, 1, 0.6)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SURVIVE & COLLECT", 0, h / 2 - 130, w, "center")
    
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.circle("fill", w/2 - 80, h / 2 - 70, 14)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("x " .. (coins or 0), w/2 - 55, h / 2 - 82, 100, "left")
    
    local bx = w / 2 - 120
    
    -- PLAY
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, h / 2 - 17, 240, 50, 12)
    love.graphics.setColor(0.2, 0.6, 0.8, 0.95)
    love.graphics.rectangle("fill", bx, h / 2 - 20, 240, 50, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("PLAY", bx, h / 2 - 5, 240, "center")
    
    -- SHOP
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, h / 2 + 48, 240, 50, 12)
    love.graphics.setColor(0.4, 0.2, 0.8, 0.95)
    love.graphics.rectangle("fill", bx, h / 2 + 45, 240, 50, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("SHOP", bx, h / 2 + 60, 240, "center")
    
    if shop_open then
        drawShop()
    end
end

function drawShop()
    local w, h = love.graphics.getDimensions()
    if w <= 0 or h <= 0 then return end
    
    local shop_w, shop_h = 420, 280
    local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", shop_x + 10, shop_y + 10, shop_w, shop_h, 15)
    love.graphics.setColor(0.08, 0.04, 0.15, 0.97)
    love.graphics.rectangle("fill", shop_x, shop_y, shop_w, shop_h, 15)
    love.graphics.setColor(0.5, 0.2, 1, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", shop_x + 5, shop_y + 5, shop_w - 10, shop_h - 10, 12)
    
    love.graphics.setColor(1, 1, 0, 0.9)
    love.graphics.setFont(fontTitle)
    love.graphics.printf("SHOP", shop_x + 20, shop_y + 15, 150, "left")
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Balance: " .. coins, shop_x + shop_w - 160, shop_y + 22, 140, "right")
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", shop_x + shop_w - 57, shop_y + 8, 42, 30, 8)
    love.graphics.setColor(0.6, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", shop_x + shop_w - 60, shop_y + 5, 40, 30, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("X", shop_x + shop_w - 58, shop_y + 12, 36, "center")
    
    love.graphics.setColor(0.5, 0.2, 1, 0.2)
    love.graphics.rectangle("fill", shop_x + 20, shop_y + 60, shop_w - 40, 2)
    
    local item_x, item_y = shop_x + 20, shop_y + 75
    local item_w, item_h = shop_w - 40, 70
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", item_x + 3, item_y + 3, item_w, item_h, 8)
    love.graphics.setColor(0.2, 0.1, 0.4, 0.8)
    love.graphics.rectangle("fill", item_x, item_y, item_w, item_h, 8)
    love.graphics.setColor(0.5, 0.2, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", item_x, item_y, item_w, item_h, 8)
    
    love.graphics.setColor(0, 0.8, 1, 0.8)
    love.graphics.polygon("fill",
        item_x + 35, item_y + 20,
        item_x + 50, item_y + 8,
        item_x + 65, item_y + 20,
        item_x + 50, item_y + 55,
        item_x + 35, item_y + 20
    )
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontBtn)
    love.graphics.printf("Diamond Cube", item_x + 80, item_y + 12, 150, "left")
    
    love.graphics.setColor(1, 1, 0)
    if skins.diamond.owned then
        love.graphics.printf("OWNED", item_x + 80, item_y + 38, 150, "left")
    else
        love.graphics.printf("100 coins", item_x + 80, item_y + 38, 150, "left")
    end
    
    if skins.diamond.owned then
        if selected_skin == "diamond" then
            love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 60, item_y + 15, 40, 30, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("ON", item_x + item_w - 58, item_y + 22, 36, "center")
        else
            love.graphics.setColor(0.2, 0.6, 1, 0.9)
            love.graphics.rectangle("fill", item_x + item_w - 60, item_y + 15, 40, 30, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("EQ", item_x + item_w - 58, item_y + 22, 36, "center")
        end
    else
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", item_x + item_w - 60, item_y + 15, 40, 30, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("BUY", item_x + item_w - 58, item_y + 22, 36, "center")
    end
end

function lobby.touchpressed(id, x, y)
    local w, h = love.graphics.getDimensions()
    if w <= 0 or h <= 0 then return end
    
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
    end
    
    if shop_open then
        local shop_w, shop_h = 420, 280
        local shop_x, shop_y = w / 2 - shop_w / 2, h / 2 - shop_h / 2 + 30
        
        if x >= shop_x + shop_w - 60 and x <= shop_x + shop_w - 20 and
           y >= shop_y + 5 and y <= shop_y + 35 then
            shop_open = false
            playSound("click")
            return
        end
        
        local item_x, item_y = shop_x + 20, shop_y + 75
        local item_w, item_h = shop_w - 40, 70
        if x >= item_x + item_w - 60 and x <= item_x + item_w - 20 and
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

function lobby.keypressed(key)
    if key == "escape" then
        if shop_open then
            shop_open = false
        end
    end
end

return lobby
