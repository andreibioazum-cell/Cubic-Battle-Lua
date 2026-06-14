local joystick = {}

local touchId = nil
local centerX, centerY = 0, 0
local stickX, stickY = 0, 0
local radius = 90         -- средний размер
local stickRadius = 38

function joystick.load(cx, cy)
    centerX = cx
    centerY = cy
    stickX = cx
    stickY = cy
end

function joystick.draw()
    -- База
    love.graphics.setColor(0.6, 0.3, 0.9, 0.15)
    love.graphics.circle("fill", centerX, centerY, radius)

    -- Внутренний круг
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.circle("fill", centerX, centerY, radius * 0.7)

    -- Обводка
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", centerX, centerY, radius)

    -- Перекрестье
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.line(centerX - 12, centerY, centerX + 12, centerY)
    love.graphics.line(centerX, centerY - 12, centerX, centerY + 12)

    -- Стик с тенью
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle("fill", stickX + 2, stickY + 3, stickRadius)

    love.graphics.setColor(0.6, 0.3, 0.9, 0.95)
    love.graphics.circle("fill", stickX, stickY, stickRadius)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", stickX, stickY, stickRadius)
end

function joystick.touchpressed(id, x, y)
    local dx = x - centerX
    local dy = y - centerY
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < radius * 1.5 and touchId == nil then
        touchId = id
        joystick.touchmoved(id, x, y)
    end
end

function joystick.touchmoved(id, x, y)
    if id ~= touchId then return end

    local dx = x - centerX
    local dy = y - centerY
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist > radius then
        local angle = math.atan2(dy, dx)
        stickX = centerX + math.cos(angle) * radius
        stickY = centerY + math.sin(angle) * radius
    else
        stickX = x
        stickY = y
    end
end

function joystick.touchreleased(id, x, y)
    if id == touchId then
        touchId = nil
        stickX = centerX
        stickY = centerY
    end
end

function joystick.getDirection()
    local dx = (stickX - centerX) / radius
    local dy = (stickY - centerY) / radius
    return dx, dy
end

return joystick
