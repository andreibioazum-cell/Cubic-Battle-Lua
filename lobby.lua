local lobby = {}

local playBtn = { w = 180, h = 50, x = 0, y = 0 }
local onlineBtn = { w = 180, h = 50, x = 0, y = 0 }
local time = 0
local mesh
local lastW, lastH = 0, 0
local fontTitle, fontSub, fontBtn

local function makeMesh(w, h)
    return love.graphics.newMesh({
        { 0, 0, 0, 0, 0.55, 0.20, 0.85, 1 },
        { w, 0, 1, 0, 0.85, 0.25, 0.65, 1 },
        { w, h, 1, 1, 0.10, 0.02, 0.25, 1 },
        { 0, h, 0, 1, 0.18, 0.05, 0.35, 1 },
    }, "fan", "static")
end

local function placeBtns()
    local w, h = love.graphics.getDimensions()
    playBtn.x = w / 2 - playBtn.w / 2
    playBtn.y = h / 2
    onlineBtn.x = w / 2 - onlineBtn.w / 2
    onlineBtn.y = h / 2 + 70
end

function lobby.load()
    fontTitle = fontTitle or love.graphics.newFont(48)
    fontSub = fontSub or love.graphics.newFont(18)
    fontBtn = fontBtn or love.graphics.newFont(22)
    placeBtns()
end

function lobby.resize()
    mesh = nil
    placeBtns()
end

function lobby.update(dt)
    time = time + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()

    if not mesh or w ~= lastW or h ~= lastH then
        mesh = makeMesh(w, h)
        lastW, lastH = w, h
        placeBtns()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh, 0, 0)

    love.graphics.setFont(fontTitle)
    local title = "Cubic Battle"
    local tw = fontTitle:getWidth(title)
    local float = math.sin(time * 1.2) * 3

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(title, w / 2 - tw / 2 + 3, h / 4 - 40 + float + 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, w / 2 - tw / 2, h / 4 - 40 + float)

    love.graphics.setFont(fontSub)
    love.graphics.setColor(1, 1, 1, 0.6)
    local sub = "Touch & dodge"
    love.graphics.print(sub, w / 2 - fontSub:getWidth(sub) / 2, h / 4 + 20)

    -- Play
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", playBtn.x + 3, playBtn.y + 4, playBtn.w, playBtn.h, 14, 14)
    love.graphics.setColor(0.5, 0.15, 0.7, 0.95)
    love.graphics.rectangle("fill", playBtn.x, playBtn.y, playBtn.w, playBtn.h, 14, 14)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", playBtn.x, playBtn.y, playBtn.w, playBtn.h, 14, 14)
    
    love.graphics.setFont(fontBtn)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print("Play", playBtn.x + 72, playBtn.y + 16)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Play", playBtn.x + 71, playBtn.y + 15)

    -- Online
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", onlineBtn.x + 3, onlineBtn.y + 4, onlineBtn.w, onlineBtn.h, 14, 14)
    love.graphics.setColor(0.2, 0.5, 0.9, 0.95)
    love.graphics.rectangle("fill", onlineBtn.x, onlineBtn.y, onlineBtn.w, onlineBtn.h, 14, 14)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", onlineBtn.x, onlineBtn.y, onlineBtn.w, onlineBtn.h, 14, 14)
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print("Online", onlineBtn.x + 62, onlineBtn.y + 16)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Online", onlineBtn.x + 61, onlineBtn.y + 15)
end

function lobby.touchpressed(id, x, y)
    if x >= playBtn.x and x <= playBtn.x + playBtn.w and
       y >= playBtn.y and y <= playBtn.y + playBtn.h then
        game.setMode("normal")
        GameState.current = "game"
    end
    
    if x >= onlineBtn.x and x <= onlineBtn.x + onlineBtn.w and
       y >= onlineBtn.y and y <= onlineBtn.y + onlineBtn.h then
        game.setMode("online")
        GameState.current = "game"
    end
end

return lobby
