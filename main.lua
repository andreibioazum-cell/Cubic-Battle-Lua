local codescreen = require("codescreen")
local lobby = require("lobby")
local game = require("game")

GameState = {
    current = "code"
}

-- Защита от двойных тапов (Android иногда дублирует события)
local lastTouchTime = 0
local TOUCH_COOLDOWN = 0.05  -- 50 мс

-- Определяем платформу
local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

function love.load()
    love.window.setMode(0, 0, {
        fullscreen = true,
        borderless = true,
        vsync = 0,
        msaa = 0,
        resizable = true
    })
    love.graphics.setDefaultFilter("linear", "linear")

    codescreen.load()
    lobby.load()
    game.load()
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end

    if GameState.current == "code" then
        codescreen.update(dt)
    elseif GameState.current == "lobby" then
        lobby.update(dt)
    elseif GameState.current == "game" then
        game.update(dt)
    end
end

function love.draw()
    if GameState.current == "code" then
        codescreen.draw()
    elseif GameState.current == "lobby" then
        lobby.draw()
    elseif GameState.current == "game" then
        game.draw()
    end
end

function love.resize(w, h)
    if codescreen.resize then codescreen.resize(w, h) end
    if lobby.resize then lobby.resize(w, h) end
    if game.load then game.load() end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    -- Защита от дабл-тапа
    local now = love.timer.getTime()
    if now - lastTouchTime < TOUCH_COOLDOWN then return end
    lastTouchTime = now

    if GameState.current == "code" then
        codescreen.touchpressed(id, x, y)
    elseif GameState.current == "lobby" then
        lobby.touchpressed(id, x, y)
    elseif GameState.current == "game" then
        game.touchpressed(id, x, y)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if GameState.current == "game" then
        game.touchmoved(id, x, y)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if GameState.current == "game" then
        game.touchreleased(id, x, y)
    end
end

-- Мышь — ТОЛЬКО на ПК (на мобиле игнорируем, чтобы не было дублей)
function love.mousepressed(x, y, button)
    if isMobile then return end   -- ВАЖНО: на Android не дублируем
    love.touchpressed(1, x, y)
end

function love.mousemoved(x, y, dx, dy)
    if isMobile then return end
    if love.mouse.isDown(1) then
        love.touchmoved(1, x, y)
    end
end

function love.mousereleased(x, y, button)
    if isMobile then return end
    love.touchreleased(1, x, y)
end
