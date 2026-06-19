local lobby = require("lobby")
local game = require("game")

GameState = { current = "lobby" }

local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    
    local success, err = xpcall(function()
        if game.setOnDeath then
            game.setOnDeath(function()
                GameState.current = "lobby"
            end)
        end
        
        local current = states[GameState.current]
        if current and current.load then
            current.load()
        end
        lastState = GameState.current
    end, function(err)
        print("❌ Error: " .. tostring(err))
        print(debug.traceback())
    end)
    
    if not success then
        print("❌ Load error: " .. tostring(err))
    end
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end
    
    if GameState.current ~= lastState then
        local new_state = states[GameState.current]
        if new_state and new_state.load then
            new_state.load()
        end
        lastState = GameState.current
    end
    
    local current = states[GameState.current]
    if current and current.update then
        current.update(dt)
    end
end

function love.draw()
    local current = states[GameState.current]
    if current and current.draw then
        current.draw()
    end
end

function love.resize(w, h)
    local current = states[GameState.current]
    if current and current.resize then
        current.resize(w, h)
    end
end

function love.touchpressed(id, x, y, pressure)
    local current = states[GameState.current]
    if current and current.touchpressed then
        current.touchpressed(id, x, y, pressure)
    end
end

function love.touchmoved(id, x, y, pressure)
    local current = states[GameState.current]
    if current and current.touchmoved then
        current.touchmoved(id, x, y, pressure)
    end
end

function love.touchreleased(id, x, y, pressure)
    local current = states[GameState.current]
    if current and current.touchreleased then
        current.touchreleased(id, x, y, pressure)
    end
end

function love.keypressed(key, scancode, isrepeat)
    local current = states[GameState.current]
    if current and current.keypressed then
        current.keypressed(key, scancode, isrepeat)
    end
    
    if key == "escape" then
        love.event.quit()
    end
end

-- ⚠️ ВАЖНО: НЕ ЗАБУДЬ ЗАКРЫТЬ ВСЕ ФУНКЦИИ!
-- Конец файла
