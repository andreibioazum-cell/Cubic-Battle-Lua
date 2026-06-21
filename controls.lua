local controls = {}

local joystick = {
    id = nil,
    cx = 90, cy = 0,
    sx = 90, sy = 0,
    radius = 55,
    stickRadius = 25,
    active = false
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

-- КЛАВИШИ ДЛЯ ПК
local keys = {
    up = false,
    down = false,
    left = false,
    right = false,
    space = false,
    e = false
}

function controls.load()
    font = love.graphics.newFont(20)
    controls.resize()
end

function controls.resize()
    local w, h = love.graphics.getDimensions()
    joystick.cy = h - 100
    joystick.sy = joystick.cy
    joystick.cx = 90
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
    -- Если джойстик активен - используем его
    if joystick.active and joystick.id then
        local dx = joystick.sx - joystick.cx
        local dy = joystick.sy - joystick.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len == 0 then return 0, 0 end
        moveDir.x = dx/len
        moveDir.y = dy/len
        return moveDir.x, moveDir.y
    end
    
    -- ИНАЧЕ ИСПОЛЬЗУЕМ КЛАВИАТУРУ (ПК)
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

function controls.isAttacking()
    return attack.holding or keys.space
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

-- ============================================================
-- ДЛЯ МЫШИ (ПК)
-- ============================================================
function controls.mousepressed(x, y, button)
    if button == 1 then
        -- ДЖОЙСТИК - проверяем попадание
        local dx = x - joystick.cx
        local dy = y - joystick.cy
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist < joystick.radius then
            joystick.id = 1
            joystick.active = true
            joystick.sx = x
            joystick.sy = y
            print("Joystick activated!")
            return
        end
        
        -- КНОПКА АТАКИ
        local ax = x - attack.x
        local ay = y - attack.y
        if ax*ax + ay*ay < attack.radius*attack.radius then
            attack.id = 1
            attack.holding = true
            print("Attack pressed!")
            return "attack"
        end
        
        -- КНОПКА СПОСОБНОСТИ
        local abx = x - ability.x
        local aby = y - ability.y
        if abx*abx + aby*aby < ability.radius*ability.radius then
            if ability.cooldown <= 0 then
                ability.id = 1
                ability.holding = true
                print("Ability pressed!")
                return "ability"
            end
        end
    end
end

function controls.mousemoved(x, y, dx, dy, button)
    -- ДВИЖЕНИЕ ДЖОЙСТИКА (если зажат)
    if joystick.active and joystick.id then
        local dx2 = x - joystick.cx
        local dy2 = y - joystick.cy
        local len = math.sqrt(dx2*dx2 + dy2*dy2)
        
        if len > joystick.radius then
            joystick.sx = joystick.cx + (dx2 / len) * joystick.radius
            joystick.sy = joystick.cy + (dy2 / len) * joystick.radius
        else
            joystick.sx = x
            joystick.sy = y
        end
        
        if len > 5 then
            moveDir.x = dx2 / len
            moveDir.y = dy2 / len
        end
    end
end

function controls.mousereleased(x, y, button)
    if button == 1 then
        local shot = false
        local abilityUsed = false
        local dx, dy = 0, 0
        
        -- ОТПУСКАЕМ ДЖОЙСТИК (возврат в центр)
        if joystick.id then
            joystick.id = nil
            joystick.active = false
            joystick.sx = joystick.cx
            joystick.sy = joystick.cy
            print("Joystick released!")
        end
        
        -- ОТПУСКАЕМ АТАКУ
        if attack.id then
            attack.id = nil
            attack.holding = false
            shot = true
            dx, dy = moveDir.x, moveDir.y
            if dx == 0 and dy == 0 then
                dy = -1
            end
            print("Attack released!")
        end
        
        -- ОТПУСКАЕМ СПОСОБНОСТЬ
        if ability.id then
            ability.id = nil
            ability.holding = false
            if ability.cooldown <= 0 then
                abilityUsed = true
                ability.cooldown = ability.maxCooldown
                print("Ability used!")
            end
        end
        
        return shot, dx, dy, abilityUsed
    end
end

-- ============================================================
-- ДЛЯ ТАЧА (МОБИЛЬНЫЕ)
-- ============================================================
function controls.touchpressed(id, x, y)
    return controls.mousepressed(x, y, 1)
end

function controls.touchmoved(id, x, y)
    controls.mousemoved(x, y, 0, 0, 1)
end

function controls.touchreleased(id, x, y)
    return controls.mousereleased(x, y, 1)
end

-- ============================================================
-- ДЛЯ КЛАВИАТУРЫ (ПК)
-- ============================================================
function controls.keypressed(key)
    if key == "w" or key == "up" then keys.up = true end
    if key == "s" or key == "down" then keys.down = true end
    if key == "a" or key == "left" then keys.left = true end
    if key == "d" or key == "right" then keys.right = true end
    
    if key == "space" then
        keys.space = true
        attack.holding = true
        return "attack"
    end
    
    if key == "e" or key == "q" then
        keys.e = true
        if ability.cooldown <= 0 then
            ability.holding = true
            return "ability"
        end
    end
end

function controls.keyreleased(key)
    if key == "w" or key == "up" then keys.up = false end
    if key == "s" or key == "down" then keys.down = false end
    if key == "a" or key == "left" then keys.left = false end
    if key == "d" or key == "right" then keys.right = false end
    
    if key == "space" then
        keys.space = false
        attack.holding = false
        local dx, dy = moveDir.x, moveDir.y
        if dx == 0 and dy == 0 then
            dy = -1
        end
        return "attack", dx, dy
    end
    
    if key == "e" or key == "q" then
        keys.e = false
        ability.holding = false
        if ability.cooldown <= 0 then
            ability.cooldown = ability.maxCooldown
            return "ability"
        end
    end
end

function controls.draw()
    if not font then
        controls.load()
    end
    
    -- ДЖОЙСТИК
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.circle("fill", joystick.cx + 3, joystick.cy + 3, joystick.radius)
    love.graphics.setColor(0.25, 0.25, 0.35, 0.3)
    love.graphics.circle("fill", joystick.cx, joystick.cy, joystick.radius)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joystick.cx, joystick.cy, joystick.radius)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", joystick.sx, joystick.sy, joystick.stickRadius)
    love.graphics.setColor(0.6, 0.6, 0.7, 0.3)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", joystick.sx, joystick.sy, joystick.stickRadius)
    
    -- КНОПКА АТАКИ
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
    
    -- КНОПКА СПОСОБНОСТИ
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
