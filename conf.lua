function love.conf(t)
    t.identity = "myfirstgame"
    t.version = "11.5"
    t.window.title = "My First Game"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.orientation = "portrait"
    t.modules.physics = false
end
