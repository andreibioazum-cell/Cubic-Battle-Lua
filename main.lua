local lobby = require("lobby")
local game = require("game")
local modSystem = require("mod_system")

_G.GameState = { current = "lobby" }

local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

-- ============================================================
-- ИСПРАВЛЕННАЯ ФУНКЦИЯ playSound
-- ============================================================
function playSound(name)
    if _G.sounds and _G.sounds[name] then
        local source = _G.sounds[name]
        -- Проверяем что источник существует и у него есть метод clone
        if source and source:clone then
            local clone = source:clone()
            if clone then
                clone:setVolume(source:getVolume() or 0.5)
                clone:setLooping(false)
                clone:play()
                -- Автоматически останавливаем через 0.5 секунды
                love.timer.after(0.5, function()
                    if clone and clone:isPlaying then
                        clone:stop()
                    end
                end)
            end
        elseif source and source:play then
            -- Fallback: просто проигрываем без клонирования
            source:play()
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    -- Инициализируем систему модов
    modSystem.autoInit()
    
    -- Загружаем звуки
    local soundSuccess, soundErr = pcall(function()
        _G.sounds = {
            click = love.audio.newSource("cartoon-button-click-sound.mp3", "static"),
            shot = love.audio.newSource("loud-pistol-shot.mp3", "static")
        }
        if _G.sounds.click then 
            _G.sounds.click:setVolume(0.5)
            _G.sounds.click:setLooping(false)
        end
        if _G.sounds.shot then 
            _G.sounds.shot:setVolume(0.3)
            _G.sounds.shot:setLooping(false)
        end
    end)
    if not soundSuccess then
        print("⚠️ Звуки не загружены: " .. tostring(soundErr))
        _G.sounds = {}
    end

    -- Загружаем состояния
    local success, err = xpcall(function()
        if game.setOnDeath then
            game.setOnDeath(function()
                _G.GameState.current = "lobby"
                modSystem.gameDeath()  -- Вызываем событие смерти для модов
            end)
        end

        local current = states[_G.GameState.current]
        if current and current.load then 
            current.load() 
        end
        lastState = _G.GameState.current
        
        -- Вызываем событие загрузки для модов
        modSystem.gameLoad()
        
    end, function(err)
        print("❌ Ошибка: " .. tostring(err))
        print(debug.traceback())
    end)
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
    
    -- Обновляем моды
    modSystem.gameUpdate(dt)
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then 
        current.draw() 
    end
    
    -- Рисуем моды (поверх всего)
    modSystem.gameDraw()
end

function love.touchpressed(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchpressed then 
        current.touchpressed(id, x, y) 
    end
end

function love.touchmoved(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchmoved then 
        current.touchmoved(id, x, y) 
    end
end

function love.touchreleased(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchreleased then 
        current.touchreleased(id, x, y) 
    end
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
        if s.resize then 
            s.resize(w, h) 
        end
    end
end

function love.keypressed(key)
    if key == "escape" then 
        love.event.quit() 
    end
end
