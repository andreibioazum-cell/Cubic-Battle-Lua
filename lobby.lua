local lobby = {}

local fontLarge = nil
local fontMedium = nil
local fontSmall = nil
local coins = 0
local selectedSkin = "default"
local shopOpen = false
local skins = {
    default = { name = "Default", price = 0, owned = true },
    diamond = { name = "Diamond", price = 100, owned = false }
}

function lobby.load()
    fontLarge = love.graphics.newFont(48)
    fontMedium = love.graphics.newFont(24)
    fontSmall = love.graphics.newFont(16)
    
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
        selectedSkin = lines[3] or "default"
    end
    
    print("Lobby loaded! Coins: " .. coins)
end

function lobby.update(dt)
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()
    
    love.graphics.setColor(0.1, 0.05, 0.2)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    for i = 1, 30 do
        local x = (i * 137 + 42) % w
        local y = (i * 251 + 13) % h
        love.graphics.setColor(1, 1, 1, 0.3 + 0.3 * math.sin(i + love.timer.getTime()))
        love.graphics.circle("fill", x, y, 1 + i % 3)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontLarge)
    love.graphics.printf("CUBIC BATTLE", 0, h/2 - 120, w, "center")
    
    love.graphics.setColor(0.6, 0.3, 1, 0.7)
    love.graphics.setFont(fontMedium)
    love.graphics.printf("SURVIVE AND COLLECT", 0, h/2 - 70, w, "center")
    
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.setFont(fontMedium)
    love.graphics.printf("COINS: " .. coins, 0, h/2 - 35, w, "center")
    
    local bx = w/2 - 100
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", bx + 3, h/2 + 10, 200, 50, 10)
    love.graphics.setColor(0.2, 0.6, 0.8)
    love.graphics.rectangle("fill", bx, h/2 + 7, 200, 50, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontMedium)
    love.graphics.printf("PLAY", bx, h/2 + 20, 200, "center")
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", bx + 3, h/2 + 70, 200, 50, 10)
    love.graphics.setColor(0.5, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, h/2 + 67, 200, 50, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SHOP", bx, h/2 + 80, 200, "center")
    
    if shopOpen then
        drawShop()
    end
end

function drawShop()
    local w, h = love.graphics.getDimensions()
    local sw, sh = 400, 250
    local sx, sy = w/2 - sw/2, h/2 - sh/2
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(0.15, 0.08, 0.3, 0.95)
    love.graphics.rectangle("fill", sx, sy, sw, sh, 10)
    love.graphics.setColor(0.5, 0.2, 1, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", sx, sy, sw, sh, 10)
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(fontMedium)
    love.graphics.printf("SHOP", sx, sy + 10, sw, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    love.graphics.printf("Diamond Skin", sx + 20, sy + 60, sw - 40, "left")
    
    if skins.diamond.owned then
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("OWNED", sx + 20, sy + 85, sw - 40, "left")
    else
        love.graphics.setColor(1, 0.8, 0)
        love.graphics.printf("100 coins", sx + 20, sy + 85, sw - 40, "left")
    end
    
    local buyX = sx + sw - 100
    if skins.diamond.owned then
        love.graphics.setColor(0.2, 0.8, 0.2)
    else
        love.graphics.setColor(1, 0.8, 0.2)
    end
    love.graphics.rectangle("fill", buyX, sy + 60, 80, 35, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fontSmall)
    if skins.diamond.owned then
        if selectedSkin == "diamond" then
            love.graphics.printf("ON", buyX, sy + 70, 80, "center")
        else
            love.graphics.printf("EQUIP", buyX, sy + 70, 80, "center")
        end
    else
        love.graphics.printf("BUY", buyX, sy + 70, 80, "center")
    end
    
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", sx + sw - 40, sy + 5, 30, 30, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("X", sx + sw - 40, sy + 10, 30, "center")
end

function lobby.mousepressed(x, y, button)
    local w, h = love.graphics.getDimensions()
    local bx = w/2 - 100
    
    if x >= bx and x <= bx + 200 then
        if y >= h/2 + 7 and y <= h/2 + 57 then
            print("Starting game...")
            local game = require("game")
            game.setCoins(coins)
            game.setSkin(selectedSkin)
            game.load()
            _G.GameState.current = "game"
            return
        end
        
        if y >= h/2 + 67 and y <= h/2 + 117 then
            shopOpen = not shopOpen
            return
        end
    end
    
    if shopOpen then
        local sw, sh = 400, 250
        local sx, sy = w/2 - sw/2, h/2 - sh/2
        
        if x >= sx + sw - 40 and x <= sx + sw - 10 and
           y >= sy + 5 and y <= sy + 35 then
            shopOpen = false
            return
        end
        
        local buyX = sx + sw - 100
        if x >= buyX and x <= buyX + 80 and
           y >= sy + 60 and y <= sy + 95 then
            if not skins.diamond.owned and coins >= 100 then
                coins = coins - 100
                skins.diamond.owned = true
                selectedSkin = "diamond"
                love.filesystem.write("save.txt", coins .. "\ndiamond\ndiamond")
                print("Bought diamond skin!")
            elseif skins.diamond.owned then
                selectedSkin = "diamond"
                love.filesystem.write("save.txt", coins .. "\ndiamond\ndiamond")
                print("Equipped diamond skin!")
            else
                print("Not enough coins!")
            end
        end
    end
end

function lobby.keypressed(key)
    if key == "escape" and shopOpen then
        shopOpen = false
    end
end

function lobby.resize()
end

return lobby
