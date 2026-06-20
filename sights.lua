local sights = {}

sights.x = 0
sights.y = 0
sights.size = 20
sights.opacity = 0.8
sights.visible = true

function sights.update(playerX, playerY)
    sights.x = playerX
    sights.y = playerY
end

function sights.draw()
    if not sights.visible then return end
    
    love.graphics.setColor(0.2, 0.8, 0.2, sights.opacity)
    love.graphics.setLineWidth(2)
    
    -- Horizontal line
    love.graphics.line(sights.x - sights.size, sights.y, sights.x - sights.size/2, sights.y)
    love.graphics.line(sights.x + sights.size/2, sights.y, sights.x + sights.size, sights.y)
    
    -- Vertical line
    love.graphics.line(sights.x, sights.y - sights.size, sights.x, sights.y - sights.size/2)
    love.graphics.line(sights.x, sights.y + sights.size/2, sights.x, sights.y + sights.size)
    
    -- Center dot
    love.graphics.setColor(0.2, 0.8, 0.2, sights.opacity)
    love.graphics.circle("fill", sights.x, sights.y, 3)
    
    -- Corner marks
    love.graphics.setLineWidth(1.5)
    local cornerSize = 8
    love.graphics.line(sights.x - cornerSize, sights.y - cornerSize, sights.x - cornerSize + 4, sights.y - cornerSize)
    love.graphics.line(sights.x - cornerSize, sights.y - cornerSize, sights.x - cornerSize, sights.y - cornerSize + 4)
    
    love.graphics.line(sights.x + cornerSize, sights.y - cornerSize, sights.x + cornerSize - 4, sights.y - cornerSize)
    love.graphics.line(sights.x + cornerSize, sights.y - cornerSize, sights.x + cornerSize, sights.y - cornerSize + 4)
    
    love.graphics.line(sights.x - cornerSize, sights.y + cornerSize, sights.x - cornerSize + 4, sights.y + cornerSize)
    love.graphics.line(sights.x - cornerSize, sights.y + cornerSize, sights.x - cornerSize, sights.y + cornerSize - 4)
    
    love.graphics.line(sights.x + cornerSize, sights.y + cornerSize, sights.x + cornerSize - 4, sights.y + cornerSize)
    love.graphics.line(sights.x + cornerSize, sights.y + cornerSize, sights.x + cornerSize, sights.y + cornerSize - 4)
end

function sights.toggle()
    sights.visible = not sights.visible
end

return sights
