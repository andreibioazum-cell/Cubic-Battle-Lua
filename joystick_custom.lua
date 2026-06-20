local joystick_custom = {}

joystick_custom.x = 0
joystick_custom.y = 0
joystick_custom.radius = 50
joystick_custom.baseX = 0
joystick_custom.baseY = 0
joystick_custom.active = false
joystick_custom.sensitivity = 1.0

-- Movement state
joystick_custom.moveX = 0
joystick_custom.moveY = 0

function joystick_custom.load()
    local w, h = love.graphics.getDimensions()
    joystick_custom.baseX = w * 0.15
    joystick_custom.baseY = h * 0.85
    joystick_custom.x = joystick_custom.baseX
    joystick_custom.y = joystick_custom.baseY
end

function joystick_custom.update(dt)
    if joystick_custom.active then
        joystick_custom.moveX = (joystick_custom.x - joystick_custom.baseX) / joystick_custom.radius * joystick_custom.sensitivity
        joystick_custom.moveY = (joystick_custom.y - joystick_custom.baseY) / joystick_custom.radius * joystick_custom.sensitivity
        
        -- Clamp to unit circle
        local dist = math.sqrt(joystick_custom.moveX^2 + joystick_custom.moveY^2)
        if dist > 1 then
            joystick_custom.moveX = joystick_custom.moveX / dist
            joystick_custom.moveY = joystick_custom.moveY / dist
        end
    else
        joystick_custom.moveX = 0
        joystick_custom.moveY = 0
    end
end

function joystick_custom.draw()
    local w, h = love.graphics.getDimensions()
    
    -- Base circle
    love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
    love.graphics.circle("fill", joystick_custom.baseX, joystick_custom.baseY, joystick_custom.radius)
    
    -- Border
    love.graphics.setColor(0.4, 0.4, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joystick_custom.baseX, joystick_custom.baseY, joystick_custom.radius)
    
    -- Stick
    love.graphics.setColor(0.6, 0.3, 0.8, 0.8)
    love.graphics.circle("fill", joystick_custom.x, joystick_custom.y, 25)
    
    -- Stick border
    love.graphics.setColor(0.8, 0.5, 1.0, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joystick_custom.x, joystick_custom.y, 25)
end

function joystick_custom.touchpressed(id, x, y)
    local dist = math.sqrt((x - joystick_custom.baseX)^2 + (y - joystick_custom.baseY)^2)
    if dist <= joystick_custom.radius then
        joystick_custom.active = true
        joystick_custom_updatePosition(x, y)
    end
end

function joystick_custom.touchmoved(id, x, y)
    if joystick_custom.active then
        joystick_custom_updatePosition(x, y)
    end
end

function joystick_custom.touchreleased(id, x, y)
    joystick_custom.active = false
    joystick_custom.x = joystick_custom.baseX
    joystick_custom.y = joystick_custom.baseY
end

function joystick_custom_updatePosition(x, y)
    local dx = x - joystick_custom.baseX
    local dy = y - joystick_custom.baseY
    local dist = math.sqrt(dx^2 + dy^2)
    
    if dist > joystick_custom.radius then
        joystick_custom.x = joystick_custom.baseX + (dx / dist) * joystick_custom.radius
        joystick_custom.y = joystick_custom.baseY + (dy / dist) * joystick_custom.radius
    else
        joystick_custom.x = x
        joystick_custom.y = y
    end
end

function joystick_custom.getDirection()
    return joystick_custom.moveX, joystick_custom.moveY
end

return joystick_custom
