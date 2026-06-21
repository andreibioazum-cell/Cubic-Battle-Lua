local game = require("game")
local lobby = require("lobby")

_G.GameState = { current = "lobby" }

local states = {
    lobby = lobby,
    game = game
}

local lastState = "lobby"

function love.load()
    love.window.setTitle("Cubic Battle")
    print("Game started!")
    
    local current = states[_G.GameState.current]
    if current and current.load then
        current.load()
    end
    lastState = _G.GameState.current
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end
    
    if _G.GameState.current ~= lastState then
        local new_state = states[_G.GameState.current]
        if new_state and new_state.load then
            new_state.load()
        end
        lastState = _G.GameState.current
    end
    
    local current = states[_G.GameState.current]
    if current and current.update then
        current.update(dt)
    end
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then
        current.draw()
    end
end

function love.mousepressed(x, y, button)
    local current = states[_G.GameState.current]
    if current and current.mousepressed then
        current.mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    if key == "escape" then
        _G.GameState.current = "lobby"
    end
    
    local current = states[_G.GameState.current]
    if current and current.keypressed then
        current.keypressed(key)
    end
end

function love.resize(w, h)
    for _, state in pairs(states) do
        if state.resize then
            state.resize(w, h)
        end
    end
end
