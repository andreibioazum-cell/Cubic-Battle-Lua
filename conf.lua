function love.conf(t)
    t.identity = "cubicbattle"
    t.version = "11.5"
    t.window.title = "Cubic Battle"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.fullscreen = true
    t.window.borderless = true
    t.window.vsync = 0          -- ОТКЛЮЧАЕМ vsync (FPS не ограничен)
    t.window.orientation = "portrait"
    t.modules.physics = false
    t.modules.video = false      -- отключаем неиспользуемые модули
    t.modules.joystick = false
    t.modules.thread = false
    t.modules.audio = false
    t.modules.sound = false
end
