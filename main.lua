local lobby = require("lobby")
local game = require("game")
local keyboard = require("game_keyboard")
local shop = require("shop")
local sights = require("sights")

_G.GameState = { current = "lobby" }
_G.shop = shop
_G.sights = sights

local states = {
    lobby = lobby,
    game = game
}

local lastState = nil

function playSound(name)
    if _G.sounds and _G.sounds[name] then
        local source = _G.sounds[name]
        if source and source.play then
            source:play()
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.audio.setVolume(1.0)
    
    keyboard.init()
    
    _G.sounds = {}
    
    local function loadSound(name, file)
        local success, source = pcall(function()
            return love.audio.newSource(file, "static")
        end)
        if success and source then
            source:setVolume(0.5)
            source:setLooping(false)
            _G.sounds[name] = source
        end
    end
    
    loadSound("click", "cartoon-button-click-sound.mp3")
    loadSound("shot", "loud-pistol-shot.mp3")
    loadSound("success", "success.mp3")
    loadSound("error", "error.mp3")

    local g = require("game")
    if g.setOnDeath then
        g.setOnDeath(function()
            _G.GameState.current = "lobby"
        end)
    end
    
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
    
    if _G.GameState.current == "game" then
        sights.draw()
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

function love.resize(w, h)
    for _, s in pairs(states) do
        if s.resize then 
            s.resize(w, h) 
        end
    end
end

function love.textinput(text)
    if keyboard.isActive() then
        keyboard.handleTextInput(text)
    end
end
