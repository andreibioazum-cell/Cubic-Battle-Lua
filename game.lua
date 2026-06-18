local lobby = require("lobby")
local game = require("game")

GameState = { current = "lobby" }

local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
local lastTap = 0
local lastState = nil

-- Сетевая часть для main
local network = {
    is_server = false,
    server_thread = nil,
    socket = nil
}

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    
    -- Проверка аргументов командной строки
    local args = {...}
    for i, arg in ipairs(args) do
        if arg == "--server" then
            network.is_server = true
            print("Starting in SERVER mode...")
            start_server()
        end
    end
end

-- Запуск сервера
function start_server()
    local server = require("server")
    love.thread.getChannel("server"):push(server)
    
    network.server_thread = love.thread.newThread([[
        local channel = love.thread.getChannel("server")
        local server = channel:pop()
        if server then
            server:start()
        end
    ]])
    network.server_thread:start()
    
    print("Server started on port 4080")
    print("Press ESC to stop server")
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end

    if GameState.current ~= lastState then
        if GameState.current == "lobby" and lobby.load then lobby.load() end
        if GameState.current == "game"  and game.load  then game.load()  end
        lastState = GameState.current
    end

    if GameState.current == "lobby" then
        lobby.update(dt)
    elseif GameState.current == "game" then
        game.update(dt)
    end
end

function love.draw()
    if GameState.current == "lobby" then
        lobby.draw()
    elseif GameState.current == "game" then
        game.draw()
    end
    
    -- Отображение информации о сервере
    if network.is_server and GameState.current == "lobby" then
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print("SERVER RUNNING ON PORT 4080", 10, love.graphics.getHeight() - 30)
        love.graphics.print("Players online: " .. get_players_count(), 10, love.graphics.getHeight() - 50)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Получение количества игроков
function get_players_count()
    local server = require("server")
    if server and server.clients then
        return #server.clients
    end
    return 0
end

function love.resize(w, h)
    if lobby.resize then lobby.resize(w, h) end
    if game.resize  then game.resize(w, h)  end
end

local function dispatch(fn, id, x, y)
    local s = GameState.current
    if s == "lobby" and lobby[fn] then lobby[fn](id, x, y)
    elseif s == "game" and game[fn] then game[fn](id, x, y) end
end

function love.touchpressed(id, x, y)
    local now = love.timer.getTime()
    if now - lastTap < 0.05 then return end
    lastTap = now
    dispatch("touchpressed", id, x, y)
end

function love.touchmoved(id, x, y)
    dispatch("touchmoved", id, x, y)
end

function love.touchreleased(id, x, y)
    dispatch("touchreleased", id, x, y)
end

function love.mousepressed(x, y)
    if isMobile then return end
    love.touchpressed(1, x, y)
end

function love.mousemoved(x, y)
    if isMobile then return end
    if love.mouse.isDown(1) then love.touchmoved(1, x, y) end
end

function love.mousereleased(x, y)
    if isMobile then return end
    love.touchreleased(1, x, y)
end

function love.keypressed(key)
    if key == "escape" then
        if network.is_server then
            print("Stopping server...")
            if network.server_thread then
                network.server_thread:terminate()
            end
            love.event.quit()
        end
    end
    
    -- Переключение режима сервера по F1
    if key == "f1" and not network.is_server then
        print("Starting server...")
        start_server()
        network.is_server = true
    end
    
    -- Чат по Enter
    if key == "return" or key == "enter" then
        if GameState.current == "game" and game.chat_input then
            game.chat_input = true
        end
    end
end

function love.textinput(text)
    if GameState.current == "game" and game.chat_input then
        if not game.chat_message then game.chat_message = "" end
        game.chat_message = game.chat_message .. text
    end
end

function love.quit()
    if network.is_server then
        print("Shutting down server...")
        if network.server_thread then
            network.server_thread:terminate()
        end
    end
    print("Goodbye!")
end

return {
    isServer = network.is_server,
    startServer = start_server
}
