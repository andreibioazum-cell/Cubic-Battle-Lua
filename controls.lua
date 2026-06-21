local controls = {}
local joy = { id = nil, cx = 90, cy = 0, sx = 90, sy = 0, r = 55, sr = 25 }
local atk = { id = nil, x = 0, y = 0, r = 55, hold = false }
local ability = { id = nil, x = 0, y = 0, r = 40, hold = false, cooldown = 0, maxCooldown = 5 }
local font = nil

local keys = {
    up = false,
    down = false,
    left = false,
    right = false,
    space = false,
    ability = false
}

function controls.load()
    local success, err = pcall(function()
        font = love.graphics.newFont(20)
    end)
    if not success then
        font = love.graphics.newFont(20)
    end
    controls.resize()
end

function controls.resize()
    local w, h = love.graphics.getDimensions()
    joy.cy = h - 100
    joy.sy = joy.cy
    atk.x = w - 90
    atk.y = h - 90
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
    -- ЕСЛИ ДЖОЙСТИК АКТИВЕН
    if joy.id then
        local dx = joy.sx - joy.cx
        local dy = joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 10 then
            return dx/len, dy/len
        else
            return 0, 0
        end
    end
    
    -- КЛАВИАТУРА
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
    
    return dx, dy
end

function controls.getAim()
    if joy.id then
        local dx = joy.sx - joy.cx
        local dy = joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 10 then
            return dx/len, dy/len
        end
    end
    return 0, -1
end

function controls.isAiming() 
    return atk.hold 
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
-- ТАЧ
-- ============================================================
function controls.touchpressed(id, x, y)
    -- ДЖОЙСТИК - проверяем попадание ВНУТРЬ КРУГА
    local dx = x - joy.cx
    local dy = y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r then
        joy.id = id
        joy.sx = x
        joy.sy = y
        print("Joystick pressed: " .. id)
    end
    
    -- КНОПКА АТАКИ (A)
    local ax = x - atk.x
    local ay = y - atk.y
    if ax*ax + ay*ay < atk.r*atk.r then
        atk.id = id
        atk.hold = true
        print("Attack pressed: " .. id)
    end
    
    -- КНОПКА СПОСОБНОСТИ (S)
    local abx = x - ability.x
    local aby = y - ability.y
    if abx*abx + aby*aby < ability.r*ability.r then
        if ability.cooldown <= 0 then
            ability.id = id
            ability.hold = true
            print("Ability pressed: " .. id)
        end
    end
end

function controls.touchmoved(id, x, y)
    if id == joy.id then
        local dx = x - joy.cx
        local dy = y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        
        if len > joy.r then
            joy.sx = joy.cx + (dx / len) * joy.r
            joy.sy = joy.cy + (dy / len) * joy.r
        else
            joy.sx = x
            joy.sy = y
        end
    end
end

function controls.touchreleased(id)
    local shot = false
    local abilityUsed = false
    local dx, dy = 0, 0
    
    print("Released: " .. id)
    
    -- ОТПУСКАЕМ ДЖОЙСТИК
    if id == joy.id then
        joy.id = nil
        joy.sx = joy.cx
        joy.sy = joy.cy
        print("Joystick released - CENTER")
    end
    
    -- ОТПУСКАЕМ АТАКУ
    if id == atk.id then
        atk.id = nil
        atk.hold = false
        shot = true
        dx, dy = controls.getMove()
        if dx == 0 and dy == 0 then
            dy = -1
        end
        print("Attack released")
    end
    
    -- ОТПУСКАЕМ СПОСОБНОСТЬ
    if id == ability.id then
        ability.id = nil
        ability.hold = false
        if ability.cooldown <= 0 then
            abilityUsed = true
            ability.cooldown = ability.maxCooldown
        end
        print("Ability released")
    end
    
    return shot, dx, dy, abilityUsed
end

-- ============================================================
-- КЛАВИАТУРА (ПК)
-- ============================================================
function controls.keypressed(key)
    if key == "w" or key == "up" then keys.up = true end
    if key == "s" or key == "down" then keys.down = true end
    if key == "a" or key == "left" then keys.left = true end
    if key == "d" or key == "right" then keys.right = true end
    
    if key == "space" then
        keys.space = true
        atk.id = -1
        atk.hold = true
    end
    
    if key == "e" or key == "q" then
        keys.ability = true
        if ability.cooldown <= 0 then
            ability.id = -1
            ability.hold = true
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
        if atk.id == -1 then
            atk.id = nil
            atk.hold = false
            local dx, dy = controls.getMove()
            if dx == 0 and dy == 0 then
                dy = -1
            end
            return "attack", dx, dy
        end
    end
    
    if key == "e" or key == "q" then
        keys.ability = false
        if ability.id == -1 then
            ability.id = nil
            ability.hold = false
            if ability.cooldown <= 0 then
                ability.cooldown = ability.maxCooldown
                return "ability"
            end
        end
    end
end

-- ============================================================
-- MOUSE (ПК)
-- ============================================================
function controls.mousepressed(x, y, button)
    if button == 1 then
        local dx = x - joy.cx
        local dy = y - joy.cy
        if dx*dx + dy*dy < joy.r*joy.r then
            joy.id = 1
            joy.sx = x
            joy.sy = y
        end
        
        local ax = x - atk.x
        local ay = y - atk.y
        if ax*ax + ay*ay < atk.r*atk.r then
            atk.id = 1
            atk.hold = true
        end
        
        local abx = x - ability.x
        local aby = y - ability.y
        if abx*abx + aby*aby < ability.r*ability.r then
            if ability.cooldown <= 0 then
                ability.id = 1
                ability.hold = true
            end
        end
    end
end

function controls.mousemoved(x, y, dx, dy, button)
    if joy.id then
        local dx2 = x - joy.cx
        local dy2 = y - joy.cy
        local len = math.sqrt(dx2*dx2 + dy2*dy2)
        
        if len > joy.r then
            joy.sx = joy.cx + (dx2 / len) * joy.r
            joy.sy = joy.cy + (dy2 / len) * joy.r
        else
            joy.sx = x
            joy.sy = y
        end
    end
end

function controls.mousereleased(x, y, button)
    if button == 1 then
        local shot = false
        local abilityUsed = false
        local dx, dy = 0, 0
        
        if joy.id then
            joy.id = nil
            joy.sx = joy.cx
            joy.sy = joy.cy
        end
        
        if atk.id then
            atk.id = nil
            atk.hold = false
            shot = true
            dx, dy = controls.getMove()
            if dx == 0 and dy == 0 then
                dy = -1
            end
        end
        
        if ability.id then
            ability.id = nil
            ability.hold = false
            if ability.cooldown <= 0 then
                abilityUsed = true
                ability.cooldown = ability.maxCooldown
            end
        end
        
        return shot, dx, dy, abilityUsed
    end
end

-- ============================================================
-- РИСОВАНИЕ
-- ============================================================
function controls.draw()
    if not font then
        controls.load()
    end
    
    -- ДЖОЙСТИК
    love.graphics.setColor(0.15, 0.15, 0.25, 0.25)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joy.cx, joy.cy, joy.r)
    
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("fill", joy.sx - 7, joy.sy - 8, joy.sr * 0.35)
    
    -- КНОПКА АТАКИ (A)
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.circle("fill", atk.x + 3, atk.y + 3, atk.r)
    love.graphics.setColor(0.2, 0.6, 0.9, 0.9)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    love.graphics.setColor(0.3, 0.7, 1, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", atk.x, atk.y, atk.r)
    
    if atk.hold then
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.circle("fill", atk.x, atk.y, atk.r + 8)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("A", atk.x - atk.r, atk.y - 14, atk.r*2, "center")
    
    -- КНОПКА СПОСОБНОСТИ (S)
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.circle("fill", ability.x + 3, ability.y + 3, ability.r)
    
    if ability.cooldown > 0 then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
        love.graphics.circle("fill", ability.x, ability.y, ability.r)
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.arc("fill", ability.x, ability.y, ability.r, 
            -math.pi/2, -math.pi/2 + (1 - ability.cooldown / ability.maxCooldown) * 2 * math.pi)
    else
        love.graphics.setColor(0.6, 0.2, 0.9, 0.9)
        love.graphics.circle("fill", ability.x, ability.y, ability.r)
        love.graphics.setColor(0.7, 0.3, 1, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", ability.x, ability.y, ability.r)
        
        local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 2)
        love.graphics.setColor(0.8, 0.4, 1, pulse * 0.15)
        love.graphics.circle("fill", ability.x, ability.y, ability.r + 6)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf("S", ability.x - ability.r, ability.y - 14, ability.r*2, "center")
end

return controls
