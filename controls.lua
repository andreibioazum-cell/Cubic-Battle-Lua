local controls = {}
local joy = { id = nil, cx = 90, cy = 0, sx = 90, sy = 0, r = 55, sr = 25 }
local atk = { id = nil, x = 0, y = 0, r = 55, hold = false }
local font = nil

local moveDir = { x = 0, y = -1 }

local keys = {
    up = false,
    down = false,
    left = false,
    right = false,
    space = false
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
end

function controls.update(dt) end

function controls.getMove()
    if joy.id then
        local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len == 0 then return 0, 0 end
        moveDir.x = dx/len
        moveDir.y = dy/len
        return moveDir.x, moveDir.y
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

function controls.isAiming() 
    return atk.hold 
end

function controls.touchpressed(id, x, y)
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 5 then
            moveDir.x = dx / len
            moveDir.y = dy / len
        end
    end
    
    local ax, ay = x - atk.x, y - atk.y
    if ax*ax + ay*ay < atk.r*atk.r then
        atk.id = id
        atk.hold = true
        local len = math.sqrt(ax*ax + ay*ay)
        if len > 5 then
            moveDir.x = ax / len
            moveDir.y = ay / len
        end
    end
end

function controls.touchmoved(id, x, y)
    if id == joy.id then
        local dx, dy = x - joy.cx, y - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > joy.r then
            dx, dy = dx/len*joy.r, dy/len*joy.r
        end
        joy.sx, joy.sy = joy.cx + dx, joy.cy + dy
        
        if len > 5 then
            moveDir.x = dx / len
            moveDir.y = dy / len
        end
    end
end

function controls.touchreleased(id)
    local shot = false
    local dx, dy = 0, 0
    
    if id == joy.id then
        joy.id = nil
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    
    if id == atk.id then
        atk.id = nil
        atk.hold = false
        shot = true
        dx, dy = moveDir.x, moveDir.y
        if dx == 0 and dy == 0 then
            dy = -1
        end
    end
    
    return shot, dx, dy
end

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
            local dx, dy = moveDir.x, moveDir.y
            if dx == 0 and dy == 0 then
                dy = -1
            end
            return true, dx, dy
        end
    end
end

function controls.draw()
    if not font then
        controls.load()
    end
    
    -- ============================================================
    -- КРАСИВЫЙ БЕЛЫЙ ДЖОЙСТИК
    -- ============================================================
    
    -- 1. Внешняя тень
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", joy.cx + 3, joy.cy + 3, joy.r)
    
    -- 2. Внешнее кольцо с градиентом (полупрозрачное)
    love.graphics.setColor(0.3, 0.3, 0.4, 0.3)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    
    -- 3. Обводка внешнего кольца
    love.graphics.setColor(0.6, 0.6, 0.7, 0.3)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", joy.cx, joy.cy, joy.r)
    
    -- 4. Декоративная пунктирная обводка
    love.graphics.setColor(0.8, 0.8, 1, 0.15)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", joy.cx, joy.cy, joy.r - 8)
    
    -- 5. Крестик-прицел в центре джойстика (декоративный)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.15)
    love.graphics.setLineWidth(1)
    local crossSize = 12
    love.graphics.line(joy.cx - crossSize, joy.cy, joy.cx + crossSize, joy.cy)
    love.graphics.line(joy.cx, joy.cy - crossSize, joy.cx, joy.cy + crossSize)
    
    -- 6. Основной круг джойстика (БЕЛЫЙ С ГРАДИЕНТОМ)
    -- Градиент: белый -> светло-серый
    for i = 0, joy.sr do
        local alpha = 0.95 - (i / joy.sr) * 0.3
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", joy.sx, joy.sy, joy.sr - i * 0.3)
    end
    
    -- 7. Блик на джойстике (сверху-слева)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", joy.sx - 8, joy.sy - 10, joy.sr * 0.35)
    
    -- 8. Маленький блик
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.circle("fill", joy.sx - 12, joy.sy - 14, joy.sr * 0.15)
    
    -- 9. Обводка джойстика
    love.graphics.setColor(0.7, 0.7, 0.8, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", joy.sx, joy.sy, joy.sr)
    
    -- 10. Внутренняя обводка для объема
    love.graphics.setColor(0.9, 0.9, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", joy.sx, joy.sy, joy.sr - 5)
    
    -- ============================================================
    -- КРАСИВАЯ КНОПКА SHOT
    -- ============================================================
    
    -- 1. Тень кнопки
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.circle("fill", atk.x + 3, atk.y + 3, atk.r)
    
    -- 2. Основной круг кнопки (красный с градиентом)
    for i = 0, atk.r do
        local alpha = 0.9 - (i / atk.r) * 0.3
        local r = 0.9 - (i / atk.r) * 0.2
        love.graphics.setColor(r, 0.1, 0.1, alpha)
        love.graphics.circle("fill", atk.x, atk.y, atk.r - i * 0.3)
    end
    
    -- 3. Блик на кнопке
    love.graphics.setColor(1, 0.4, 0.4, 0.25)
    love.graphics.circle("fill", atk.x - 15, atk.y - 15, atk.r * 0.5)
    
    -- 4. Обводка кнопки
    love.graphics.setColor(0.9, 0.2, 0.2, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", atk.x, atk.y, atk.r)
    
    -- 5. Пульсирующий эффект при удержании
    if atk.hold then
        local pulse = 0.2 + 0.2 * math.sin(love.timer.getTime() * 8)
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.circle("fill", atk.x, atk.y, atk.r + 10)
        
        -- Линия направления
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setLineWidth(3)
        local len = 40
        love.graphics.line(
            atk.x, atk.y,
            atk.x + moveDir.x * len,
            atk.y + moveDir.y * len
        )
        
        -- Конечная точка линии (кружок)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", atk.x + moveDir.x * len, atk.y + moveDir.y * len, 6)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.circle("fill", atk.x + moveDir.x * len, atk.y + moveDir.y * len, 10)
    end
    
    -- 6. Текст на кнопке (⚡)
    love.graphics.setColor(1, 1, 1)
    if font then
        love.graphics.setFont(font)
        love.graphics.printf("⚡", atk.x - atk.r, atk.y - 14, atk.r*2, "center")
    end
    
    -- 7. Подпись под кнопкой
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.printf("FIRE", atk.x - 20, atk.y + atk.r + 8, 40, "center")
end

return controls
