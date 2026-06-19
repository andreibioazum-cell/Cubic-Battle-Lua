local lobby = require("lobby")
local game = require("game")
local modSystem = require("mod_system")
local gameInstaller = require("game_installer")

_G.GameState = { current = "lobby" }

local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

-- ============================================================
-- ФУНКЦИЯ playSound (ИСПРАВЛЕННАЯ)
-- ============================================================
function playSound(name)
    if _G.sounds and _G.sounds[name] then
        local source = _G.sounds[name]
        if source and source:clone then
            local clone = source:clone()
            if clone then
                clone:setVolume(source:getVolume() or 0.5)
                clone:setLooping(false)
                clone:play()
                love.timer.after(0.5, function()
                    if clone and clone:isPlaying then
                        clone:stop()
                    end
                end)
            end
        elseif source and source:play then
            source:play()
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    -- Инициализируем систему модов
    modSystem.autoInit()
    
    -- Инициализируем установщик модов
    gameInstaller.init()
    
    -- Проверяем безопасный режим
    if gameInstaller.checkSafeMode() then
        print("🔒 Безопасный режим активирован!")
        -- Восстанавливаем бэкап если есть
        gameInstaller.restoreBackup()
    end
    
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
            print("📦 Установлен мод: " .. installedMod.title)
            print("   Автор: " .. installedMod.author)
            print("   Версия: " .. installedMod.version)
        end
        
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
    
    modSystem.gameUpdate(dt)
end

function love.draw()
    local current = states[_G.GameState.current]
    if current and current.draw then 
        current.draw() 
    end
    
    modSystem.gameDraw()
    
    -- Показываем статус установки в углу
    local status = gameInstaller.getInstallStatus()
    if status.isInstalling then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.print("📦 Установка мода...", 10, love.graphics.getHeight() - 30)
    end
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
