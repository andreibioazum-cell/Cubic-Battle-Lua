-- ============================================================
-- МОДУЛЬ: mod_system.lua
-- Система управления модами для Cubic Battle 3
-- Версия: 1.0
-- ============================================================

local modSystem = {}

-- ========== ПЕРЕМЕННЫЕ ==========
local mods = {}                  -- Загруженные моды
local modHooks = {
    onLoad = {},
    onUpdate = {},
    onDraw = {},
    onShoot = {},
    onHit = {},
    onDeath = {},
    onSpawn = {},
    onBulletHit = {}
}
local isInitialized = false
local modDirectory = "mods/"

-- ============================================================
-- 1. ИНИЦИАЛИЗАЦИЯ
-- ============================================================

function modSystem.init()
    if isInitialized then return true end
    
    print("🔧 Инициализация системы модов...")
    
    -- Создаём папку для модов
    if not love.filesystem.getInfo(modDirectory) then
        love.filesystem.createDirectory(modDirectory)
        print("📁 Создана папка: " .. modDirectory)
    end
    
    isInitialized = true
    print("✅ Система модов инициализирована!")
    return true
end

-- ============================================================
-- 2. ЗАГРУЗКА МОДОВ
-- ============================================================

function modSystem.loadMods()
    print("📦 Загрузка модов...")
    mods = {}
    
    -- Очищаем хуки
    for hook, _ in pairs(modHooks) do
        modHooks[hook] = {}
    end
    
    -- Получаем все файлы в папке mods
    local files = love.filesystem.getDirectoryItems(modDirectory)
    local loadedCount = 0
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local success, mod = pcall(function()
                return require(modDirectory .. file:sub(1, -5))
            end)
            
            if success and mod then
                table.insert(mods, mod)
                loadedCount = loadedCount + 1
                print("✅ Загружен мод: " .. (mod.title or file))
                
                -- Регистрируем хуки
                if mod.onLoad then
                    table.insert(modHooks.onLoad, mod.onLoad)
                end
                if mod.onUpdate then
                    table.insert(modHooks.onUpdate, mod.onUpdate)
                end
                if mod.onDraw then
                    table.insert(modHooks.onDraw, mod.onDraw)
                end
                if mod.onShoot then
                    table.insert(modHooks.onShoot, mod.onShoot)
                end
                if mod.onHit then
                    table.insert(modHooks.onHit, mod.onHit)
                end
                if mod.onDeath then
                    table.insert(modHooks.onDeath, mod.onDeath)
                end
                if mod.onSpawn then
                    table.insert(modHooks.onSpawn, mod.onSpawn)
                end
                if mod.onBulletHit then
                    table.insert(modHooks.onBulletHit, mod.onBulletHit)
                end
                
                -- Вызываем onLoad
                if mod.onLoad then
                    pcall(mod.onLoad)
                end
            else
                print("❌ Ошибка загрузки мода: " .. file)
                print(debug.traceback())
            end
        end
    end
    
    print("📦 Загружено модов: " .. loadedCount)
    return loadedCount
end

-- ============================================================
-- 3. АВТОМАТИЧЕСКАЯ ИНИЦИАЛИЗАЦИЯ
-- ============================================================

function modSystem.autoInit()
    modSystem.init()
    modSystem.loadMods()
end

-- ============================================================
-- 4. ВЫЗОВ ХУКОВ
-- ============================================================

function modSystem.trigger(hook, ...)
    if not modHooks[hook] then return end
    
    for _, callback in ipairs(modHooks[hook]) do
        pcall(callback, ...)
    end
end

-- ============================================================
-- 5. ОБЩИЕ ФУНКЦИИ ДЛЯ ИГРЫ
-- ============================================================

function modSystem.gameLoad()
    modSystem.trigger("onLoad")
end

function modSystem.gameUpdate(dt)
    modSystem.trigger("onUpdate", dt)
end

function modSystem.gameDraw()
    modSystem.trigger("onDraw")
end

function modSystem.gameShoot(x, y, dx, dy)
    local result = { x = x, y = y, dx = dx, dy = dy }
    
    for _, callback in ipairs(modHooks.onShoot) do
        local modified = pcall(callback, result.x, result.y, result.dx, result.dy)
        if modified and type(modified) == "table" then
            result.x = modified.x or result.x
            result.y = modified.y or result.y
            result.dx = modified.dx or result.dx
            result.dy = modified.dy or result.dy
        end
    end
    
    return result
end

function modSystem.gameHit(enemy, damage)
    modSystem.trigger("onHit", enemy, damage)
end

function modSystem.gameDeath()
    modSystem.trigger("onDeath")
end

function modSystem.gameSpawn(enemy)
    modSystem.trigger("onSpawn", enemy)
end

function modSystem.bulletHit(bullet, target)
    modSystem.trigger("onBulletHit", bullet, target)
end

-- ============================================================
-- 6. УПРАВЛЕНИЕ МОДАМИ
-- ============================================================

function modSystem.getMods()
    return mods
end

function modSystem.getModCount()
    return #mods
end

function modSystem.reloadMods()
    print("🔄 Перезагрузка модов...")
    mods = {}
    for hook, _ in pairs(modHooks) do
        modHooks[hook] = {}
    end
    modSystem.loadMods()
end

function modSystem.unloadMods()
    print("🗑️ Выгрузка всех модов...")
    mods = {}
    for hook, _ in pairs(modHooks) do
        modHooks[hook] = {}
    end
end

-- ============================================================
-- 7. ДОБАВЛЕНИЕ МОДА ИЗ ФАЙЛА
-- ============================================================

function modSystem.installMod(filename, content)
    if not filename or not content then
        print("❌ Ошибка: имя файла или содержимое отсутствует")
        return false
    end
    
    local path = modDirectory .. filename
    love.filesystem.write(path, content)
    
    print("✅ Мод установлен: " .. filename)
    modSystem.reloadMods()
    return true
end

function modSystem.removeMod(filename)
    if not filename then return false end
    
    local path = modDirectory .. filename
    local info = love.filesystem.getInfo(path)
    if info and info.type == "file" then
        love.filesystem.remove(path)
        print("🗑️ Мод удалён: " .. filename)
        modSystem.reloadMods()
        return true
    end
    
    print("❌ Мод не найден: " .. filename)
    return false
end

-- ============================================================
-- 8. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function modSystem.getModInfo(filename)
    local path = modDirectory .. filename
    local info = love.filesystem.getInfo(path)
    if info then
        return {
            name = filename,
            size = info.size,
            modified = info.modtime
        }
    end
    return nil
end

function modSystem.getInstalledModsList()
    local result = {}
    local files = love.filesystem.getDirectoryItems(modDirectory)
    
    for _, file in ip
