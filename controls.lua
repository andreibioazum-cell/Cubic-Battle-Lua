local controls = {}
local joy = { id = nil, cx = 90, cy = 0, sx = 90, sy = 0, r = 50, sr = 20 }
local atk = { id = nil, x = 0, y = 0, r = 55, hold = false }
local font = nil

-- Направление движения (для стрельбы)
local moveDir = { x = 0, y = -1 }

-- Клавиатурное управление
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
    joy.cy = h - 90
    joy.sy = joy.cy
    atk.x = w - 90
    atk.y = h - 90
end

function controls.update(dt) end

function controls.getMove()
    -- Сначала проверяем сенсор/мышь
    if joy.id then
        local dx, dy = joy.sx - joy.cx, joy.sy - joy.cy
        local len = math.sqrt(dx*dx + dy*dy)
        if len == 0 then return 0, 0 end
        moveDir.x = dx/len
        moveDir.y = dy/len
        return moveDir.x, moveDir.y
    end
    
    -- Потом клавиатуру
    local dx, dy = 0, 0
    if keys.left then dx = -1 end
    if keys.right then dx = 1 end
    if keys.up then dy = -1 end
    if keys.down then dy = 1 end
    
    -- Нормализация для диагонального движения
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
    -- Возвращаем направление движения
    return moveDir.x, moveDir.y
end

function controls.isAiming() 
    return atk.hold 
end

function controls.touchpressed(id, x, y)
    -- Joystick
    local dx, dy = x - joy.cx, y - joy.cy
    if dx*dx + dy*dy < joy.r*joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
        -- Обновляем направление при касании джойстика
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 5 then
            moveDir.x = dx / len
            moveDir.y = dy / len
        end
    end
    
    -- Attack button
    local ax, ay = x - atk.x, y - atk.y
    if ax*ax + ay*ay < atk.r*atk.r then
        atk.id = id
        atk.hold = true
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
        
        -- Обновляем направление движения
        if len > 5 then
            moveDir.x = dx / len
            moveDir.y = dy / len
        end
    end
    
    if id == atk.id then
        -- При удержании кнопки атаки ничего не делаем
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
        -- Стреляем в направлении движения
        dx, dy = moveDir.x, moveDir.y
        if dx == 0 and dy == 0 then
            dy = -1 -- По умолчанию вверх
        end
    end
    
    return shot, dx, dy
end

-- ============================================================
-- УПРАВЛЕНИЕ С КЛАВИАТУРЫ
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
            -- Стреляем в направлении движения
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
    
    -- Joystick
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)
    
    -- Attack button
    love.graphics.setColor(0.5, 0, 1, 0.6)
    love.graphics.circle("fill", atk.x, atk.y, atk.r)
    
    -- Показываем направление движения на кнопке атаки
    if atk.hold then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(3)
        local len = 35
        love.graphics.line(
            atk.x, atk.y,
            atk.x + moveDir.x * len,
            atk.y + moveDir.y * len
        )
        love.graphics.circle("fill", atk.x + moveDir.x * len, atk.y + moveDir.y * len, 4)
    end
    
    -- Button text
    love.graphics.setColor(1, 1, 1)
    if font then
        love.graphics.setFont(font)
        love.graphics.printf("SHOT", atk.x - atk.r, atk.y - 10, atk.r*2, "center")
    end
    
    -- Подсказка по клавиатуре
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(font or love.graphics.newFont(14))
    love.graphics.printf("WASD - Move | SPACE - Shot in direction", 10, 10, 400, "left")
end

return controls
