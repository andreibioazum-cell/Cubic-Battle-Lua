local lobby = require("lobby")
local game = require("game")

GameState = { current = "lobby" }
local states = { lobby = lobby, game = game }
local lastState = nil

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    if game.load then game.load() end
    if lobby.load then lobby.load() end
    lastState = GameState.current
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end
    if GameState.current ~= lastState then
        if states[GameState.current].load then states[GameState.current].load() end
        lastState = GameState.current
    end
    states[GameState.current].update(dt)
end

function love.draw()
    states[GameState.current].draw()
end

function love.resize(w, h)
    for _, s in pairs(states) do if s.resize then s.resize(w, h) end end
end

function love.touchpressed(id, x, y) states[GameState.current].touchpressed(id, x, y) end
function love.touchmoved(id, x, y) states[GameState.current].touchmoved(id, x, y) end
function love.touchreleased(id, x, y) states[GameState.current].touchreleased(id, x, y) end
