-- Главный файл игры
local lobby = require("lobby")
local game = require("game")

-- Глобальное состояние: какой экран показывать
GameState = {
    current = "lobby"  -- "lobby" или "game"
}

function love.load()
    love.window.setMode(0, 0, {fullscreen = true})
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    lobby.load()
    game.load()
end

function love.update(dt)
    if GameState.current == "lobby" then
        lobby.update(dt)
    elseif GameState.current == "game" then
        game.update(dt)
    end
end

function love.draw()
    if GameState.current == "lobby" then
        lobby.draw()
    elseif GameState.current == "game" then
        game.draw()
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if GameState.current == "lobby" then
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

-- Для тестов на ПК (мышь = тач)
function love.mousepressed(x, y, button)
    love.touchpressed(1, x, y)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) then
        love.touchmoved(1, x, y)
    end
end

function love.mousereleased(x, y, button)
    love.touchreleased(1, x, y)
end
