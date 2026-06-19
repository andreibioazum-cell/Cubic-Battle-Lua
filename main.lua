local lobby = require("lobby")
local game = require("game")

_G.GameState = { current = "lobby" }

local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    -- Предзагрузка звуков
    local soundSuccess, soundErr = pcall(function()
        _G.sounds = {
            click = love.audio.newSource("cartoon-button-click-sound.mp3", "static"),
            shot = love.audio.newSource("loud-pistol-shot.mp3", "static")
        }
        -- Устанавливаем громкость
        if _G.sounds.click then _G.sounds.click:setVolume(0.5) end
        if _G.sounds.shot then _G.sounds.shot:setVolume(0.3) end
    end)
    if not soundSuccess then
        print("⚠️ Sounds not loaded: " .. tostring(soundErr))
        _G.sounds = {}
    end

    local success, err = xpcall(function()
        if game.setOnDeath then
            game.setOnDeath(function()
                _G.GameState.current = "lobby"
            end)
        end

        local current = states[_G.GameState.current]
        if current and current.load then current.load() end
        lastState = _G.GameState.current
    end, function(err)
        print("❌ Error: " .. tostring(err))
        print(debug.traceback())
    end)
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end

    if _G.GameState.current ~= lastState then
        local new_state = states[_G.GameState.current]
        if new_state and new_state.load then new_state.load() end
        lastState = _G.GameState.current
    end

    local current = states[_G.GameState.current]
    if current and current.update then current.update(dt) end
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then current.draw() end
end

function love.touchpressed(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchpressed then current.touchpressed(id, x, y) end
end

function love.touchmoved(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchmoved then current.touchmoved(id, x, y) end
end

function love.touchreleased(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchreleased then current.touchreleased(id, x, y) end
end

function love.mousepressed(x, y, b)
    love.touchpressed(1, x, y)
end

function love.mousemoved(x, y)
    love.touchmoved(1, x, y)
end

function love.mousereleased(x, y, b)
    love.touchreleased(1, x, y)
end

function love.resize(w, h)
    for _, s in pairs(states) do
        if s.resize then s.resize(w, h) end
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end

-- Вспомогательная функция для воспроизведения звуков
function playSound(name)
    if _G.sounds and _G.sounds[name] then
        _G.sounds[name]:play()
    end
end
