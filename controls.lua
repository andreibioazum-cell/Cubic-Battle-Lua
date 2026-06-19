local controls = {}

local joy  = { id = nil, cx = 0, cy = 0, sx = 0, sy = 0, r = 50, sr = 20 }
local atk  = { id = nil, x = 0, y = 0, r = 55, hold = false, press = 0 }
local back = { x = 0, y = 0, w = 120, h = 44 }

local font, fontBack
local aimDx, aimDy = 0, -1
local onBackCallback = nil

local function place()
    local w, h = love.graphics.getDimensions()
    joy.cx = 90
    joy.cy = h - 90
    if not joy.id then
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    atk.x = w - 90
    atk.y = h - 90
    back.x = w/2 - back.w/2
    back.y = 16
end

local function drawSpacedText(text, x, y, w, align, font, spacing, alpha)
    alpha = alpha or 1
    spacing = spacing or 0
    love.graphics.setFont(font)

    local totalW = 0
    local widths = {}
    for i = 1, #text do
        local ch = text:sub(i, i)
        local cw = font:getWidth(ch)
        widths[i] = cw
        totalW = totalW + cw
    end
    totalW = totalW + spacing * (#text - 1)

    local startX
    if align == "center" then
        startX = x + (w - totalW) / 2
    else
        startX = x
    end

    local outline = 2
    love.graphics.setColor(0, 0, 0, alpha)
    local cx = startX
    for i = 1, #text do
        local ch = text:sub(i, i)
        for dx = -outline, outline, outline do
            for dy = -outline, outline, outline do
                if dx ~= 0 or dy ~= 0 then
                    love.graphics.print(ch, cx + dx, y + dy)
                end
            end
        end
        cx = cx + widths[i] + spacing
    end

    love.graphics.setColor(1, 1, 1, alpha)
    cx = startX
    for i = 1, #text do
        local ch = text:sub(i, i)
        love.graphics.print(ch, cx, y)
        cx = cx + widths[i] + spacing
    end
end

function controls.load()
    font = love.graphics.newFont("Fredoka-Bold.ttf", 22)
    fontBack = love.graphics.newFont("Fredoka-Bold.ttf", 18)
    place()
end

function controls.resize()
    place()
end

function controls.update(dt)
    local target = atk.hold and 1 or 0
    atk.press = atk.press + (target - atk.press) * math.min(dt * 12, 1)
end

function controls.getMove()
    if not joy.id then return 0, 0 end
    local dx = joy.sx - joy.cx
    local dy = joy.sy - joy.cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return 0, 0 end
    aimDx, aimDy = dx / len, dy / len
    return aimDx, aimDy
end

function controls.isAiming() return atk.hold end
function controls.getAim() return aimDx, aimDy end

function controls.setOnBack(fn)
    onBackCallback = fn
end

function controls.touchpressed(id, x, y)
    if x >= back.x and x <= back.x + back.w and y >= back.y and y <= back.y + back.h then
        if onBackCallback then
            onBackCallback()
        end
        return
    end

    local dx = x - joy.cx
    local dy = y - joy.cy
    if dx * dx + dy * dy <= joy.r * joy.r then
        joy.id = id
        joy.sx, joy.sy = x, y
        return
    end

    local ax = x - atk.x
    local ay = y - atk.y
    if ax * ax + ay * ay <= atk.r * atk.r then
        atk.id = id
        atk.hold = true
    end
end

function controls.touchmoved(id, x, y)
    if joy.id == id then
        local dx = x - joy.cx
        local dy = y - joy.cy
        local len = math.sqrt(dx * dx + dy * dy)
        if len > joy.r then
            dx = dx / len * joy.r
            dy = dy / len * joy.r
        end
        joy.sx = joy.cx + dx
        joy.sy = joy.cy + dy
    end
end

function controls.touchreleased(id)
    if joy.id == id then
        joy.id = nil
        joy.sx, joy.sy = joy.cx, joy.cy
    end
    if atk.id == id then
        atk.id = nil
        atk.hold = false
        return true, aimDx, aimDy
    end
    return false
end

function controls.draw()
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.circle("fill", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.setLineWidth(2.5)
    love.graphics.circle("line", joy.cx, joy.cy, joy.r)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.circle("fill", joy.sx, joy.sy, joy.sr)
    
    local scale = 1 - atk.press * 0.12
    local r = atk.r * scale
    local textScale = 1 - atk.press * 0.18
    local textAlpha = 1 - atk.press * 0.45

    love.graphics.setColor(0.55 - atk.press * 0.2, 0.20, 0.85 - atk.press * 0.3, 0.8)
    love.graphics.circle("fill", atk.x, atk.y, r)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", atk.x, atk.y, r)

    love.graphics.push()
    love.graphics.translate(atk.x, atk.y)
    love.graphics.scale(textScale, textScale)
    drawSpacedText("Shot", -atk.r, -12, atk.r * 2, "center", font, font:getWidth("A") * 0.05, textAlpha)
    love.graphics.pop()

    -- Back (ТОЧНО как кнопки в лобби: тень, заливка, блик, обводка)
    local bw, bh = back.w, back.h
    local bx, by = back.x, back.y
    
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", bx + 3, by + 3, bw, bh, 12, 12)
    
    love.graphics.setColor(0.45, 0.15, 0.75, 0.85)
    love.graphics.rectangle("fill", bx, by, bw, bh, 12, 12)
    
    love.graphics.setColor(0.6, 0.3, 0.9, 0.4)
    love.graphics.rectangle("fill", bx + 3, by + 2, bw - 6, bh/2, 12, 12)
    
    love.graphics.setColor(0.8, 0.7, 1, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, bw, bh, 12, 12)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fontBack)
    love.graphics.printf("Back", bx, by + bh/2 - 10, bw, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

return controls
