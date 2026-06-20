-- Подключаем все модули
local lobby = require("lobby")
local game = require("game")
local modSystem = require("mod_system")
local gameInstaller = require("game_installer")
local keyboard = require("game_keyboard")

-- Глобальное состояние игры
_G.GameState = { current = "lobby" }

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
    
    -- Инициализация системы модов
    modSystem.autoInit()
    
    -- Инициализация установщика модов
    gameInstaller.init()
    
    -- Инициализация клавиатуры
    keyboard.init()
    
    -- Проверка безопасного режима
    if gameInstaller.checkSafeMode() then
        gameInstaller.restoreBackup()
    end
    
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
        if game.setOnDeath then
            game.setOnDeath(function()
                _G.GameState.current = "lobby"
                modSystem.gameDeath()
            end)
        end

        local current = states[_G.GameState.current]
        if current and current.load then 
            current.load() 
        end
        lastState = _G.GameState.current
        
        modSystem.gameLoad()
        
        -- Показываем информацию об установленном моде
        local installedMod = gameInstaller.getInstalledMod()
        if installedMod then
            -- Без вывода в консоль
        end
        
    end, function(err)
        -- Обработка ошибок без вывода в консоль
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
    
    modSystem.gameUpdate(dt)
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then 
        current.draw() 
    end
    
    modSystem.gameDraw()
    
    local status = gameInstaller.getInstallStatus()
    if status.isInstalling then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.print("Installing mod...", 10, love.graphics.getHeight() - 30)
    end
end

-- ТОЛЬКО СЕНСОРНОЕ УПРАВЛЕНИЕ (МОБИЛЬНЫЕ)
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

-- Изменение размера окна
function love.resize(w, h)
    for _, s in pairs(states) do
        if s.resize then 
            s.resize(w, h) 
        end
    end
end

-- Обработка текстового ввода (для экранной клавиатуры)
function love.textinput(text)
    if keyboard.isActive() then
        keyboard.handleTextInput(text)
    end
end
