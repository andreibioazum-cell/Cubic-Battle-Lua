function love.conf(t)
    t.identity = "cubicbattle"
    t.version = "11.5"
    
    -- Производительность
    t.window.title = "Cubic Battle"
    t.window.fullscreen = true
    t.window.borderless = true
    t.window.vsync = 1
    t.window.msaa = 2  -- уменьшаем до 2 для скорости
    t.window.resizable = true
    
    -- Отключаем ненужное
    t.modules.physics = false
    t.modules.video = false
    t.modules.joystick = false
    t.modules.thread = false
    t.modules.audio = false  -- можно включить для звуков
    t.modules.sound = false  -- можно включить для звуков
    
    -- Настройки графики
    t.graphics.gamma_correct = false
end
