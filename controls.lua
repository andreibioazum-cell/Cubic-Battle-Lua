local controls = {}

local joystick = {
    id = nil,
    cx = 90, cy = 0,
    sx = 90, sy = 0,
    radius = 55,
    stickRadius = 25
}

local attack = {
    id = nil,
    x = 0, y = 0,
    radius = 55,
    holding = false
}

local ability = {
    id = nil,
    x = 0, y = 0,
    radius = 40,
    cooldown = 0,
    maxCooldown = 5,
    holding = false
}

local moveDir = { x = 0, y = -1 }
local font = nil

local keys = {
    up = false, down = false, left = false, right = false
}

function controls.load()
    font = love.graphics.newFont(20)
    controls.resize()
end

function controls.resize()
    local w, h = love.graphics.getDimensions()
    joystick.cy = h - 100
    joystick.sy = joystick.cy
    attack.x = w - 90
    attack.y = h - 90
    ability.x = w - 180
    ability.y = h - 90
end

function controls.update(dt)
    if ability.cooldown > 0 then
        ability.cooldown = ability.cooldown - dt
        if ability.cooldown < 0 then ability.cooldown = 0 end
    end
end

function controls.getMove()
    if joystick.id then
        local dx = joystick.sx - joystick.cx
        local dy = joystick.sy - joystick.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len == 0 then return 0, 0 end
        return dx/len, dy/len
    end
    
    local dx, dy = 0, 0
    if keys.left then dx = -1 end
    if keys.right then dx = 1 end
    if keys.up then dy = -1 end
    if keys.down then dy = 1 end
    
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(2)
        dx = dx / len
        dy = dy / len
    end
    
    if dx ~= 0 or dy ~= 0 then
        moveDir.x = dx
        moveDir.y = dy
    end
    
    return dx, dy
end

function controls.getAim()
    return moveDir.x, moveDir.y
end

function controls.canUseAbility()
    return ability.cooldown <= 0
end

function controls.useAbility()
    if ability.cooldown <= 0 then
        ability.cooldown = ability.maxCooldown
        return true
    end
    return false
end

function controls.mousepressed(x, y, button)
    if button == 1 then
        local dx = x - joystick.cx
        local dy = y - joystick.cy
        if dx*dx + dy*dy < joystick.radius*joystick.radius then
            joystick.id = 1
            joystick.sx = x
            joystick.sy = y
            local len = math.sqrt(dx*dx + dy*dy)
            if len > 5 then
                moveDir.x = dx / len
                moveDir.y = dy / len
            end
        end
        
        local ax = x - attack.x
        local ay = y - attack.y
        if ax*ax + ay*ay < attack.radius*attack.radius then
            attack.id = 1
            attack.holding = true
        end
        
        local abx = x - ability.x
        local aby = y - ability.y
        if abx*abx + aby*aby < ability.radius*ability.radius then
            if ability.cooldown <= 0 then
                ability.id = 1
                ability.holding = true
                return "ability"
            end
        end
    end
end

function controls.mousereleased(x, y, button)
    if button == 1 then
        local shot = false
        local abilityUsed = false
        local dx, dy = 0, 0
        
        if joystick.id then
            joystick.id = nil
            joystick.sx = joystick.cx
            joystick.sy = joystick.cy
        end
        
        if attack.id then
            attack.id = nil
            attack.holding = false
            shot = true
            dx, dy = moveDir.x, moveDir.y
            if dx == 0 and dy == 0 then
                dy = -1
            end
        end
        
        if ability.id then
            ability.id = nil
            ability.holding = false
            if ability.cooldown <= 0 then
                abilityUsed = true
                ability.cooldown = ability.maxCooldown
            end
        end
        
        return shot, dx, dy, abilityUsed
    end
end

function controls.draw()
    if not font then
        controls.load()
    end
    
    -- Joystick
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.circle("fill", joystick.cx + 3, joystick.cy + 3, joystick.radius)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.25)
    love.graphics.circle("fill", joystick.cx, joystick.cy, joystick.radius)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.25)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joystick.cx, joystick.cy, joystick.radius)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", joystick.sx, joystick.sy, joystick.stickRadius)
    love.graphics.setColor(0.6, 0.6, 0.7, 0.3)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", joystick.sx, joystick.sy, joystick.stickRadius)
    
    -- Attack button
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", attack.x + 3, attack.y + 3, attack.radius)
    love.graphics.setColor(0.8, 0.15, 0.15, 0.9)
    love.graphics.circle("fill", attack.x, attack.y, attack.radius)
    love.graphics.setColor(0.9, 0.2, 0.2, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", attack.x, attack.y, attack.radius)
    
    if attack.holding then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.circle("fill", attack.x, attack.y, attack.radius + 8)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("A", attack.x - attack.radius, attack.y - 14, attack.radius*2, "center")
    
    -- Ability button
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", ability.x + 3, ability.y + 3, ability.radius)
    
    if ability.cooldown > 0 then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
        love.graphics.circle("fill", ability.x, ability.y, ability.radius)
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.arc("fill", ability.x, ability.y, ability.radius, 
            -math.pi/2, -math.pi/2 + (1 - ability.cooldown / ability.maxCooldown) * 2 * math.pi)
    else
        love.graphics.setColor(0.6, 0.2, 0.9, 0.9)
        love.graphics.circle("fill", ability.x, ability.y, ability.radius)
        love.graphics.setColor(0.7, 0.3, 1, 0.4)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", ability.x, ability.y, ability.radius)
        local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 2)
        love.graphics.setColor(0.8, 0.4, 1, pulse * 0.15)
        love.graphics.circle("fill", ability.x, ability.y, ability.radius + 6)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("S", ability.x - ability.radius, ability.y - 14, ability.radius*2, "center")
end

return controls
