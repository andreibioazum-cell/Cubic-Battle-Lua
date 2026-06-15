local lobby = require("lobby")
local game = require("game")

GameState = { current = "lobby" }

local mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
local lastTap = 0

function love.load()
    love.graphics.setDefaultFilter("linear", "linear", 2)
    lobby.load()
    game.load()
end

function love.update(dt)
    if dt > 0.033 then dt = 0.033 end
    
    local state = GameState.current
    if state == "lobby" then
        lobby.update(dt)
    elseif state == "game" then
        game.update(dt)
    end
end

function love.draw()
    local state = GameState.current
    if state == "lobby" then
        lobby.draw()
    elseif state == "game" then
        game.draw()
    end
end

function love.resize(w, h)
    if lobby.resize then lobby.resize(w, h) end
    if game.load then game.load() end
end

local function handleTouch(fn, id, x, y)
    local state = GameState.current
    if state == "lobby" and lobby[fn] then
        lobby[fn](id, x, y)
    elseif state == "game" and game[fn] then
        game[fn](id, x, y)
    end
end

function love.touchpressed(id, x, y)
    local now = love.timer.getTime()
    if now - lastTap < 0.03 then return end
    lastTap = now
    handleTouch("touchpressed", id, x, y)
end

function love.touchmoved(id, x, y)
    handleTouch("touchmoved", id, x, y)
end

function love.touchreleased(id, x, y)
    handleTouch("touchreleased", id, x, y)
end

-- мышь только на десктопе
function love.mousepressed(x, y)
    if mobile then return end
    love.touchpressed(1, x, y)
end

function love.mousemoved(x, y)
    if mobile then return end
    if love.mouse.isDown(1) then love.touchmoved(1, x, y) end
end

function love.mousereleased(x, y)
    if mobile then return end
    love.touchreleased(1, x, y)
end
