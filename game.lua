function game.draw()
    love.graphics.setColor(1,1,1,1)

    love.graphics.push()
    love.graphics.translate(-cam.x, -cam.y)

    local w,h = love.graphics.getDimensions()
    if bg then
        local tw,th = bg:getWidth(), bg:getHeight()
        local sX = math.floor(cam.x/tw)*tw
        local sY = math.floor(cam.y/th)*th
        for x=sX, sX+w+tw, tw do
            for y=sY, sY+h+th, th do
                love.graphics.draw(bg, x, y)
            end
        end
    end

    -- ===== ПУЛИ ИГРОКА (СИНИЕ, ЯРКИЕ) =====
    for _, b in ipairs(bullets) do
        -- Свечение
        love.graphics.setColor(0.2, 0.4, 1, 0.3)
        love.graphics.circle("fill", b.x, b.y, 10)
        
        -- Основная пуля
        love.graphics.setColor(0.15, 0.35, 1, 1)
        love.graphics.circle("fill", b.x, b.y, 7)
        
        -- Белый блик
        love.graphics.setColor(0.6, 0.8, 1, 0.9)
        love.graphics.circle("fill", b.x - 1, b.y - 1, 3)
        
        -- Обводка
        love.graphics.setColor(0, 0, 0.3, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", b.x, b.y, 7)
    end

    -- Прицел
    if controls.isAiming() then
        local ax, ay = controls.getAim()
        love.graphics.setColor(0,0,0,0.55)
        love.graphics.setLineWidth(16)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + ax*180,
            cube.y + ay*180
        )
        love.graphics.setLineWidth(3)
        love.graphics.setColor(1,1,1,0.3)
        love.graphics.line(
            cube.x, cube.y,
            cube.x + ax*180,
            cube.y + ay*180
        )
    end

    -- Враг (теперь рисует свои пули сам)
    if not online.enabled then
        enemy.draw()
        local e_obj = enemy.get()
        if e_obj then
            drawHPBar(e_obj.x - 28, e_obj.y - 45, 56, 8, e_obj.hp, 5, {0.9,0.2,0.2})
        end
    end

    -- Игрок
    if playerImg then
        love.graphics.setColor(0,0,0,0.4)
        love.graphics.push()
        love.graphics.translate(cube.x + 6, cube.y + 8)
        love.graphics.rotate(cube.angle)
        love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(cube.x, cube.y)
        love.graphics.rotate(cube.angle)
        local t = cube.hit
        love.graphics.setColor(1, 1 - t*0.6, 1 - t*0.6, 1)
        love.graphics.draw(playerImg, -PLAYER_SIZE/2, -PLAYER_SIZE/2)
        love.graphics.pop()
    end

    love.graphics.pop()

    -- HUD
    love.graphics.setColor(1,1,1,1)
    if font then
        love.graphics.setFont(font)
    end

    local barW, barH = 200, 18
    local px = love.graphics.getWidth() - barW - 20
    local py = 20
    drawHPBar(px, py, barW, barH, cube.hp, PLAYER_HP_MAX, {0.3,0.85,0.35})

    love.graphics.setColor(1,1,1,1)
    if font then
        love.graphics.printf("HP " .. math.max(0,cube.hp) .. " / " .. PLAYER_HP_MAX,
            px, py + 22, barW, "right")
    end
    
    if online.enabled then
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.printf("ONLINE", px, py + 42, barW, "right")
        love.graphics.setColor(1,1,1,1)
    end

    controls.draw()
end
