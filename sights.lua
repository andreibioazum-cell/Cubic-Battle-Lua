local sights = {}

sights.x = 0
sights.y = 0
sights.size = 20
sights.visible = true

function sights.update(x, y)
    sights.x = x
    sights.y = y
end

function sights.draw()
    if not sights.visible then return end
    
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.setLineWidth(2)
    
    love.graphics.line(sights.x - sights.size, sights.y, sights.x - sights.size/2, sights.y)
    love.graphics.line(sights.x + sights.size/2, sights.y, sights.x + sights.size, sights.y)
    love.graphics.line(sights.x, sights.y - sights.size, sights.x, sights.y - sights.size/2)
    love.graphics.line(sights.x, sights.y + sights.size/2, sights.x, sights.y + sights.size)
    
    love.graphics.circle("fill", sights.x, sights.y, 2)
end

return sights
