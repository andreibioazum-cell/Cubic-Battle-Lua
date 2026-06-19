local enemy = {}
local img, e
local enemyBullets = {}

function enemy.load() img = love.graphics.newImage("player.png") end
function enemy.reset() e = nil; enemyBullets = {} end

function enemy.update(dt, px, py, pBullets, onHit)
    if not e then e = { x = px+400, y = py+400, hp = 5, maxHp = 5, angle = 0, shootT = 0 } end

    local dx, dy = px - e.x, py - e.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local nx, ny = dx/(dist+0.1), dy/(dist+0.1)

    -- Полный интеллект: держит дистанцию
    if dist > 250 then
        e.x, e.y = e.x + nx*130*dt, e.y + ny*130*dt
    elseif dist < 150 then
        e.x, e.y = e.x - nx*130*dt, e.y - ny*130*dt
    end
    e.angle = math.atan2(dy, dx) + math.pi/2

    e.shootT = e.shootT + dt
    if e.shootT > 1.5 then
        table.insert(enemyBullets, {x=e.x, y=e.y, vx=nx*250, vy=ny*250, life=3})
        e.shootT = 0
    end

    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.x, b.y = b.x + b.vx*dt, b.y + b.vy*dt
        if math.sqrt((b.x-px)^2+(b.y-py)^2) < 30 then onHit(1); table.remove(enemyBullets, i) end
    end

    for i = #pBullets, 1, -1 do
        local b = pBullets[i]
        if math.sqrt((b.x-e.x)^2+(b.y-e.y)^2) < 30 then e.hp = e.hp-1; table.remove(pBullets, i) end
    end
    if e.hp <= 0 then e = nil end
end

function enemy.draw()
    if not e then return end
    -- Пули врага (ЧЁРНЫЕ)
    love.graphics.setColor(0, 0, 0)
    for _, b in ipairs(enemyBullets) do love.graphics.circle("fill", b.x, b.y, 8) end

    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.angle)
    -- Тень ВРАГА (КРУТИТСЯ)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.draw(img, -27.5+5, -27.5+5)
    -- Враг
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.draw(img, -27.5, -27.5)
    love.graphics.pop()
    
    -- ХП Врага
    love.graphics.setColor(0.8, 0, 0)
    love.graphics.rectangle("fill", e.x-25, e.y-40, 50 * (e.hp/e.maxHp), 5)
end

return enemy
