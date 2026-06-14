local lobby = {}

local buttonX, buttonY, buttonW, buttonH
local titleY = 0
local gradientMesh = nil
local lastW, lastH = 0, 0

local function createGradient(w, h)
    local vertices = {
        {0, 0,    0, 0, 0.55, 0.20, 0.85, 1},
        {w, 0,    1, 0, 0.85, 0.25, 0.65, 1},
        {w, h,    1, 1, 0.10, 0.02, 0.25, 1},
        {0, h,    0, 1, 0.18, 0.05, 0.35, 1},
    }
    return love.graphics.newMesh(vertices, "fan", "static")
end

local function recalcButton()
    local w, h = love.graphics.getDimensions()
    buttonW = 180
    buttonH = 65
    buttonX = w/2 - buttonW/2
    buttonY = h/2 + 40
end

function lobby.load()
    recalcButton()   -- инициализируем сразу (фикс nil ошибки)
end

function lobby.update(dt)
    titleY = titleY + dt
end

function lobby.draw()
    local w, h = love.graphics.getDimensions()

    if not gradientMesh or w ~= lastW or h ~= lastH then
        gradientMesh = createGradient(w, h)
        lastW, lastH = w, h
        recalcButton()
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gradientMesh, 0, 0)

    local titleFont = love.graphics.newFont(56)
    love.graphics.setFont(titleFont)
    local title = "CUBIC BATTLE"
    local tw = titleFont:getWidth(title)
    local offsetY = math.sin(titleY * 1.2) * 3

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(title, w/2 - tw/2 + 4, h/4 + offsetY + 4)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, w/2 - tw/2, h/4 + offsetY)

    local subFont = love.graphics.newFont(18)
    love.graphics.setFont(subFont)
    love.graphics.setColor(1, 1, 1, 0.6)
    local sub = "Touch & dodge"
    local sw = subFont:getWidth(sub)
    love.graphics.print(sub, w/2 - sw/2, h/4 + 75)

    -- Кнопка
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", buttonX + 3, buttonY + 4, buttonW, buttonH, 14, 14)

    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 14, 14)

    love.graphics.setColor(0.3, 0.1, 0.5, 1)
    local btnFont = love.graphics.newFont(26)
    love.graphics.setFont(btnFont)
    local btnText = "PLAY"
    local btw = btnFont:getWidth(btnText)
    local bth = btnFont:getHeight()
    love.graphics.print(btnText, buttonX + buttonW/2 - btw/2, buttonY + buttonH/2 - bth/2)
end

function lobby.touchpressed(id, x, y)
    if not buttonX then recalcButton() end   -- двойная защита
    if x >= buttonX and x <= buttonX + buttonW and
       y >= buttonY and y <= buttonY + buttonH then
        GameState.current = "game"
    end
end

function lobby.resize(w, h)
    gradientMesh = nil
    recalcButton()
end

return lobby
