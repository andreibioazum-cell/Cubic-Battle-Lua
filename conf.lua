function love.conf(t)
    t.identity = "cubicbattle"
    t.version = "11.5"
    t.window.title = "Cubic Battle"
    t.window.fullscreen = true
    t.window.borderless = true
    t.window.vsync = 1           -- vsync вкл = реальный FPS экрана (60)
    t.window.msaa = 4            -- сглаживание (анти-пиксели)
    t.window.resizable = true
    t.modules.physics = false
    t.modules.video = false
    t.modules.joystick = false
    t.modules.thread = false
    t.modules.audio = false
    t.modules.sound = false
end
