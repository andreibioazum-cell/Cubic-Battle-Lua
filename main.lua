-- Подключаем все модули
local lobby = require("lobby")
local game = require("game")
local keyboard = require("game_keyboard")
local shop = require("shop")
local sights = require("sights")

-- Глобальное состояние игры
_G.GameState = { current = "lobby" }
_G.shop = shop
_G.sights = sights

-- Таблица состояний
local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

-- ============================================================
-- ФУНКЦИЯ ВОСПРОИЗВЕДЕНИЯ ЗВУКА
-- ============================================================
function playSound(name)
    if _G.sounds and _G.sounds[name] then
        local source = _G.sounds[name]
        if source then
            -- Проверяем, есть ли метод clone (для статичных звуков)
            if source.clone then
                local clone = source:clone()
                if clone then
                    clone:setVolume(source:getVolume() or 0.5)
                    clone:setLooping(false)
                    clone:play()
                    -- Автоматически очищаем через 2 секунды
                    love.timer.after(2, function()
                        if clone then clone:stop() end
                    end)
                end
            elseif source.play then
                source:play()
            end
        end
    end
end

function love.load()
    -- Настройки графики
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    -- Инициализация клавиатуры
    keyboard.init()
    
    -- ============================================================
    -- ЗАГРУЗКА ЗВУКОВ
    -- ============================================================
    _G.sounds = {}
    
    -- Пробуем загрузить каждый звук отдельно
    local function loadSound(name, file, volume)
        local success, source = pcall(function()
            return love.audio.newSource(file, "static")
        end)
        if success and source then
            source:setVolume(volume or 0.5)
            source:setLooping(false)
            _G.sounds[name] = source
            print("Loaded sound: " .. name .. " from " .. file)
            return true
        else
            print("Warning: Could not load sound: " .. file)
            return false
        end
    end
    
    loadSound("click", "cartoon-button-click-sound.mp3", 0.5)
    loadSound("shot", "loud-pistol-shot.mp3", 0.3)
    loadSound("success", "success.mp3", 0.4)
    loadSound("error", "error.mp3", 0.4)

    -- Загрузка состояний
    local success, err = xpcall(function()
        -- Настраиваем колбэк смерти для игры
        local g = require("game")
        if g.setOnDeath then
            g.setOnDeath(function()
                _G.GameState.current = "lobby"
            end)
        end
        
        -- Загружаем текущее состояние
        local current = states[_G.GameState.current]
        if current and current.load then 
            current.load() 
        end
        lastState = _G.GameState.current
        
    end, function(err)
        print("Error in love.load: " .. tostring(err))
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
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then 
        current.draw() 
    end
    
    -- Отрисовываем прицел (только в игре)
    if _G.GameState.current == "game" then
        sights.draw()
    end
end

-- ============================================================
-- ПОДДЕРЖКА СЕНСОРНОГО УПРАВЛЕНИЯ (МОБИЛЬНЫЕ)
-- ============================================================
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

-- ============================================================
-- ПОДДЕРЖКА МЫШИ (ПК)
-- ============================================================
function love.mousepressed(x, y, button, istouch)
    local current = states[_G.GameState.current]
    if current and current.touchpressed then 
        current.touchpressed(-1, x, y) 
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    local current = states[_G.GameState.current]
    if current and current.touchmoved then 
        current.touchmoved(-1, x, y) 
    end
end

function love.mousereleased(x, y, button, istouch)
    local current = states[_G.GameState.current]
    if current and current.touchreleased then 
        current.touchreleased(-1, x, y) 
    end
end

-- ============================================================
-- ПОДДЕРЖКА КЛАВИАТУРЫ (ПК)
-- ============================================================
function love.keypressed(key)
    local current = states[_G.GameState.current]
    if current and current.keypressed then 
        current.keypressed(key) 
    end
    
    if key == "escape" then
        _G.GameState.current = "lobby"
    end
end

function love.keyreleased(key)
    local current = states[_G.GameState.current]
    if current and current.keyreleased then 
        current.keyreleased(key) 
    end
end

-- ============================================================
-- ИЗМЕНЕНИЕ РАЗМЕРА ОКНА
-- ============================================================
function love.resize(w, h)
    for _, s in pairs(states) do
        if s.resize then 
            s.resize(w, h) 
        end
    end
end

-- ============================================================
-- ОБРАБОТКА ТЕКСТОВОГО ВВОДА
-- ============================================================
function love.textinput(text)
    if keyboard.isActive() then
        keyboard.handleTextInput(text)
    end
end

-- ============================================================
-- ОБРАБОТКА ОШИБОК
-- ============================================================
function love.errhand(msg)
    print("Error: " .. tostring(msg))
    print(debug.traceback())
end
