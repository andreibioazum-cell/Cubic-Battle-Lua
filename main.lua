-- Подключаем все модули
local lobby = require("lobby")
local game = require("game")
local keyboard = require("game_keyboard")
local shop = require("shop")
local sights = require("sights")
local joystick_custom = require("joystick_custom")

-- Глобальное состояние игры
_G.GameState = { current = "lobby" }
_G.shop = shop
_G.sights = sights
_G.joystick = joystick_custom

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
        if source and source.clone then
            local clone = source:clone()
            if clone then
                clone:setVolume(source:getVolume() or 0.5)
                clone:setLooping(false)
                clone:play()
                love.timer.after(0.5, function()
                    if clone then clone:stop() end
                end)
            end
        elseif source and source.play then
            source:play()
        end
    end
end

function love.load()
    -- Настройки графики
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    -- Инициализация клавиатуры
    keyboard.init()
    
    -- Загрузка звуков
    local soundSuccess, soundErr = pcall(function()
        _G.sounds = {
            click = love.audio.newSource("cartoon-button-click-sound.mp3", "static"),
            shot = love.audio.newSource("loud-pistol-shot.mp3", "static"),
            success = love.audio.newSource("success.mp3", "static"),
            error = love.audio.newSource("error.mp3", "static")
        }
        if _G.sounds.click then 
            _G.sounds.click:setVolume(0.5)
            _G.sounds.click:setLooping(false)
        end
        if _G.sounds.shot then 
            _G.sounds.shot:setVolume(0.3)
            _G.sounds.shot:setLooping(false)
        end
        if _G.sounds.success then 
            _G.sounds.success:setVolume(0.4)
            _G.sounds.success:setLooping(false)
        end
        if _G.sounds.error then 
            _G.sounds.error:setVolume(0.4)
            _G.sounds.error:setLooping(false)
        end
    end)
    if not soundSuccess then
        _G.sounds = {}
    end

    -- Загрузка состояний
    local success, err = xpcall(function()
        -- Настраиваем колбэк смерти для игры
        local g = require("game")
        if g.setOnDeath then
            g.setOnDeath(function()
                _G.GameState.current = "lobby"
            end)
        end
        
        -- Инициализация новых компонентов
        joystick_custom.load()

        -- Загружаем текущее состояние
        local current = states[_G.GameState.current]
        if current and current.load then 
            current.load() 
        end
        lastState = _G.GameState.current
        
    end, function(err)
        -- Обработка ошибок
        print("Error in love.load: " .. tostring(err))
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
    
    -- Обновляем компоненты
    joystick_custom.update(dt)
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then 
        current.draw() 
    end
    
    -- Отрисовываем компоненты (если в режиме игры)
    if _G.GameState.current == "game" then
        sights.draw()
        joystick_custom.draw()
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
    
    -- Пробросим событие к joystick
    if _G.GameState.current == "game" and joystick_custom.touchpressed then
        joystick_custom.touchpressed(id, x, y)
    end
end

function love.touchmoved(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchmoved then 
        current.touchmoved(id, x, y) 
    end
    
    -- Пробросим событие к joystick
    if _G.GameState.current == "game" and joystick_custom.touchmoved then
        joystick_custom.touchmoved(id, x, y)
    end
end

function love.touchreleased(id, x, y)
    local current = states[_G.GameState.current]
    if current and current.touchreleased then 
        current.touchreleased(id, x, y) 
    end
    
    -- Пробросим событие к joystick
    if _G.GameState.current == "game" and joystick_custom.touchreleased then
        joystick_custom.touchreleased(id, x, y)
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
-- ОБРАБОТКА ТЕКСТОВОГО ВВОДА (ДЛЯ ЭКРАННОЙ КЛАВИАТУРЫ)
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
    -- Показываем ошибку на экране
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Error: " .. tostring(msg), 10, 10)
end
