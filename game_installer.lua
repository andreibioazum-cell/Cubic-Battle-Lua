-- ============================================================
-- МОДУЛЬ: game_installer.lua
-- Полная система замены игры через моды
-- Версия: 1.0
-- ============================================================

local gameInstaller = {}

-- ========== КОНФИГУРАЦИЯ ==========
local CONFIG = {
    gameFolder = "game/",
    backupFolder = "backup/",
    modsFolder = "mods/",
    tempFolder = "temp_install/",
    protectedFiles = {
        "conf.lua",
        "save.txt",
        "mods/",
        "backup/",
        "temp_install/",
        "installed_mod.json",
        "pending_install.json",
        "restart.flag",
        "safe_mode.flag",
        "install_log.txt"
    }
}

-- ========== ПЕРЕМЕННЫЕ ==========
local installQueue = {}
local isInstalling = false
local backupFiles = {}
local installLog = {}
local isInitialized = false

-- ============================================================
-- 1. ИНИЦИАЛИЗАЦИЯ
-- ============================================================

function gameInstaller.init()
    if isInitialized then return true end
    
    print("🔧 Инициализация системы установки модов...")
    
    -- Создаём необходимые папки
    local folders = {
        CONFIG.backupFolder,
        CONFIG.tempFolder,
        CONFIG.modsFolder
    }
    
    for _, folder in ipairs(folders) do
        if not love.filesystem.getInfo(folder) then
            love.filesystem.createDirectory(folder)
            print("📁 Создана папка: " .. folder)
        end
    end
    
    -- Проверяем очередь установки
    gameInstaller.checkInstallQueue()
    
    -- Проверяем флаг перезапуска
    if gameInstaller.checkForRestart() then
        print("🔄 Игра перезапущена с новым модом!")
        gameInstaller.log("Игра перезапущена", "INFO")
    end
    
    -- Проверяем безопасный режим
    if gameInstaller.checkSafeMode() then
        print("🔒 Безопасный режим активирован!")
        gameInstaller.log("Безопасный режим активирован", "WARNING")
    end
    
    isInitialized = true
    print("✅ Система установки модов инициализирована!")
    return true
end

-- ============================================================
-- 2. УСТАНОВКА МОДА ИЗ ZIP
-- ============================================================

function gameInstaller.installModFromZIP(zipData, zipName, modInfo)
    if isInstalling then
        print("⚠️ Уже идёт установка!")
        gameInstaller.log("Попытка установки во время другой установки", "WARNING")
        return false
    end
    
    isInstalling = true
    gameInstaller.log("Начало установки: " .. zipName, "INFO")
    print("📦 Начинаем установку мода: " .. zipName)
    
    -- Создаём временную папку
    local tempPath = CONFIG.tempFolder .. zipName
    love.filesystem.write(tempPath, zipData)
    print("💾 Временный файл создан: " .. tempPath)
    
    -- Распаковываем ZIP
    local success, files = pcall(function()
        return gameInstaller.unzip(tempPath)
    end)
    
    if not success or not files then
        print("❌ Ошибка распаковки ZIP")
        gameInstaller.log("Ошибка распаковки ZIP", "ERROR")
        isInstalling = false
        return false
    end
    
    print("📦 Распаковано файлов: " .. gameInstaller.tableLength(files))
    
    -- Проверяем наличие основных файлов игры
    local hasGame = false
    for filename, _ in pairs(files) do
        if filename:match("main%.lua$") or 
           filename:match("game%.lua$") or
           filename:match("conf%.lua$") then
            hasGame = true
            break
        end
    end
    
    if not hasGame then
        print("❌ В моде нет main.lua, game.lua или conf.lua!")
        gameInstaller.log("В моде нет основных файлов игры", "ERROR")
        isInstalling = false
        return false
    end
    
    -- Создаём резервную копию
    gameInstaller.createBackup()
    
    -- Устанавливаем новые файлы
    success = gameInstaller.installFiles(files, modInfo)
    
    if success then
        print("✅ Мод установлен! Перезапускаем игру...")
        gameInstaller.log("Мод установлен: " .. zipName, "SUCCESS")
        isInstalling = false
        
        -- Сохраняем информацию об установке
        gameInstaller.saveInstallInfo(zipName, modInfo)
        
        -- Перезапускаем игру
        gameInstaller.restartGame()
        return true
    else
        print("❌ Ошибка установки! Восстанавливаем...")
        gameInstaller.log("Ошибка установки, восстановление", "ERROR")
        gameInstaller.restoreBackup()
        isInstalling = false
        return false
    end
end

-- ============================================================
-- 3. РАБОТА С ФАЙЛАМИ
-- ============================================================

function gameInstaller.createBackup()
    print("📦 Создаём резервную копию...")
    backupFiles = {}
    
    -- Получаем все файлы в корневой папке
    local files = love.filesystem.getDirectoryItems(".")
    
    for _, file in ipairs(files) do
        local info = love.filesystem.getInfo(file)
        if info and info.type == "file" then
            local content = love.filesystem.read(file)
            if content then
                backupFiles[file] = content
            end
        end
    end
    
    -- Сохраняем бэкап в отдельный файл
    local backupData = love.data.encode("json", backupFiles)
    local backupName = "backup_" .. os.time() .. ".json"
    love.filesystem.write(CONFIG.backupFolder .. backupName, backupData)
    
    print("✅ Создано резервных файлов: " .. gameInstaller.tableLength(backupFiles))
    gameInstaller.log("Создана резервная копия: " .. gameInstaller.tableLength(backupFiles) .. " файлов", "INFO")
    return backupName
end

function gameInstaller.restoreBackup()
    print("🔄 Восстанавливаем из резервной копии...")
    gameInstaller.log("Начало восстановления из резервной копии", "INFO")
    
    -- Находим последний бэкап
    local backupFilesList = love.filesystem.getDirectoryItems(CONFIG.backupFolder)
    local latestBackup = nil
    local latestTime = 0
    
    for _, file in ipairs(backupFilesList) do
        if file:match("backup_%d+%.json") then
            local time = tonumber(file:match("backup_(%d+)%.json"))
            if time and time > latestTime then
                latestTime = time
                latestBackup = file
            end
        end
    end
    
    if latestBackup then
        local data = love.filesystem.read(CONFIG.backupFolder .. latestBackup)
        if data then
            backupFiles = love.data.decode("json", data)
            if backupFiles then
                print("📦 Найден бэкап: " .. latestBackup)
            end
        end
    end
    
    -- Удаляем все файлы игры (кроме защищённых)
    local files = love.filesystem.getDirectoryItems(".")
    local deleted = 0
    
    for _, file in ipairs(files) do
        local isProtected = false
        for _, p in ipairs(CONFIG.protectedFiles) do
            if file:match(p) or file:find(p) or file == p then
                isProtected = true
                break
            end
        end
        
        if not isProtected then
            local info = love.filesystem.getInfo(file)
            if info and info.type == "file" then
                love.filesystem.remove(file)
                deleted = deleted + 1
            elseif info and info.type == "directory" then
                -- Удаляем папки (рекурсивно)
                gameInstaller.removeDirectory(file)
                deleted = deleted + 1
            end
        end
    end
    
    print("🗑️ Удалено файлов: " .. deleted)
    
    -- Восстанавливаем из бэкапа
    local restored = 0
    for filename, content in pairs(backupFiles) do
        love.filesystem.write(filename, content)
        restored = restored + 1
    end
    
    print("✅ Восстановлено файлов: " .. restored)
    gameInstaller.log("Восстановлено файлов: " .. restored, "INFO")
end

function gameInstaller.removeDirectory(dir)
    local files = love.filesystem.getDirectoryItems(dir)
    for _, file in ipairs(files) do
        local path = dir .. "/" .. file
        local info = love.filesystem.getInfo(path)
        if info and info.type == "directory" then
            gameInstaller.removeDirectory(path)
        else
            love.filesystem.remove(path)
        end
    end
    love.filesystem.remove(dir)
end

function gameInstaller.installFiles(files, modInfo)
    print("📥 Устанавливаем новые файлы...")
    local installed = 0
    local skipped = 0
    
    -- Записываем новые файлы
    for filename, content in pairs(files) do
        -- Проверяем, не защищён ли файл
        local isProtected = false
        for _, p in ipairs(CONFIG.protectedFiles) do
            if filename:match(p) or filename:find(p) or filename == p then
                isProtected = true
                break
            end
        end
        
        if not isProtected then
            -- Создаём папки если нужно
            local pathParts = {}
            for part in filename:gmatch("[^/]+") do
                table.insert(pathParts, part)
            end
            
            if #pathParts > 1 then
                local currentPath = ""
                for i = 1, #pathParts - 1 do
                    currentPath = currentPath .. pathParts[i] .. "/"
                    if not love.filesystem.getInfo(currentPath) then
                        love.filesystem.createDirectory(currentPath)
                        print("📁 Создана папка: " .. currentPath)
                    end
                end
            end
            
            love.filesystem.write(filename, content)
            installed = installed + 1
        else
            skipped = skipped + 1
        end
    end
    
    print("✅ Установлено файлов: " .. installed .. ", пропущено: " .. skipped)
    gameInstaller.log("Установлено файлов: " .. installed .. ", пропущено: " .. skipped, "INFO")
    return true
end

-- ============================================================
-- 4. РАСПАКОВКА ZIP
-- ============================================================

function gameInstaller.unzip(zipPath)
    print("📦 Распаковка ZIP: " .. zipPath)
    local files = {}
    local content = love.filesystem.read(zipPath)
    
    if not content then
        print("❌ Не удалось прочитать ZIP файл")
        return false, nil
    end
    
    -- Упрощённый парсер ZIP
    -- В реальном проекте используйте библиотеку типа lua-zip
    local pos = 1
    local fileCount = 0
    local maxPos = #content
    
    while pos < maxPos and pos > 0 do
        local sig = content:sub(pos, pos+3)
        
        if sig == "PK\3\4" then
            -- Заголовок файла
            local nameLen = string.byte(content, pos+26) or 0
            local extraLen = string.byte(content, pos+28) or 0
            local fileName = content:sub(pos+30, pos+30+nameLen-1)
            
            local dataPos = pos + 30 + nameLen + extraLen
            local dataLen = string.byte(content, pos+18) or 0
            dataLen = dataLen + string.byte(content, pos+19) * 256
            
            if dataLen > 0 and fileName ~= "" and not fileName:match("/$") then
                local fileData = content:sub(dataPos, dataPos+dataLen-1)
                if fileData and #fileData > 0 then
                    files[fileName] = fileData
                    fileCount = fileCount + 1
                    if fileCount % 10 == 0 then
                        print("📄 Распаковано " .. fileCount .. " файлов...")
                    end
                end
            end
            
            pos = dataPos + dataLen
        else
            pos = pos + 1
        end
        
        -- Безопасность: не зацикливаемся
        if pos > maxPos then break end
        if pos < 1 then break end
    end
    
    -- Удаляем временный файл
    love.filesystem.remove(zipPath)
    
    print("📦 Распаковано файлов: " .. fileCount)
    return true, files
end

-- ============================================================
-- 5. ОЧЕРЕДЬ УСТАНОВКИ (СИНХРОНИЗАЦИЯ С HTML)
-- ============================================================

function gameInstaller.checkInstallQueue()
    local installFile = "pending_install.json"
    local data = love.filesystem.read(installFile)
    
    if data then
        print("📦 Найден файл установки!")
        local installData = love.data.decode("json", data)
        
        if installData and installData.modId then
            print("📦 Мод для установки: " .. (installData.title or "Без названия"))
            gameInstaller.log("Найден мод в очереди: " .. installData.title, "INFO")
            
            -- Устанавливаем мод
            local success = gameInstaller.installModFromZIP(
                installData.zipData,
                installData.zipName or "mod.zip",
                installData
            )
            
            if success then
                love.filesystem.remove(installFile)
                print("✅ Мод установлен!")
                gameInstaller.log("Мод успешно установлен из очереди", "SUCCESS")
            else
                print("❌ Ошибка установки мода!")
                gameInstaller.log("Ошибка установки из очереди", "ERROR")
            end
        else
            love.filesystem.remove(installFile)
            print("⚠️ Некорректный файл установки")
        end
    end
end

-- ============================================================
-- 6. ПЕРЕЗАПУСК ИГРЫ
-- ============================================================

function gameInstaller.restartGame()
    print("🔄 Перезапускаем игру...")
    gameInstaller.log("Перезапуск игры", "INFO")
    
    -- Сохраняем флаг перезапуска
    love.filesystem.write("restart.flag", "true")
    
    -- Выходим из игры
    love.event.quit("restart")
end

function gameInstaller.checkForRestart()
    local flag = love.filesystem.read("restart.flag")
    if flag == "true" then
        love.filesystem.remove("restart.flag")
        return true
    end
    return false
end

-- ============================================================
-- 7. УПРАВЛЕНИЕ МОДАМИ
-- ============================================================

function gameInstaller.saveInstallInfo(zipName, modInfo)
    local info = {
        modName = zipName,
        title = modInfo and modInfo.title or "Неизвестный мод",
        author = modInfo and modInfo.author or "Неизвестный",
        version = modInfo and modInfo.version or "1.0",
        installed = os.time(),
        date = os.date("%Y-%m-%d %H:%M:%S"),
        isGameReplacement = true
    }
    
    local json = love.data.encode("json", info)
    love.filesystem.write("installed_mod.json", json)
    
    print("💾 Информация о моде сохранена")
    gameInstaller.log("Сохранена информация о моде: " .. info.title, "INFO")
end

function gameInstaller.getInstalledMod()
    local data = love.filesystem.read("installed_mod.json")
    if data then
        local mod = love.data.decode("json", data)
        return mod
    end
    return nil
end

function gameInstaller.uninstallMod()
    local modInfo = gameInstaller.getInstalledMod()
    if not modInfo then
        print("❌ Нет установленного мода")
        gameInstaller.log("Попытка удалить мод, но его нет", "WARNING")
        return false
    end
    
    print("🗑️ Удаляем мод: " .. modInfo.title)
    gameInstaller.log("Удаление мода: " .. modInfo.title, "INFO")
    
    -- Восстанавливаем бэкап
    gameInstaller.restoreBackup()
    
    -- Удаляем файл информации
    love.filesystem.remove("installed_mod.json")
    
    print("✅ Мод удалён!")
    gameInstaller.log("Мод удалён", "INFO")
    return true
end

function gameInstaller.getInstalledMods()
    local mods = {}
    
    -- Проверяем наличие установленного мода
    local current = gameInstaller.getInstalledMod()
    if current then
        table.insert(mods, current)
    end
    
    -- Проверяем файлы бэкапов
    local files = love.filesystem.getDirectoryItems(CONFIG.backupFolder)
    for _, file in ipairs(files) do
        if file:match("backup_.*%.json") then
            local data = love.filesystem.read(CONFIG.backupFolder .. file)
            if data then
                local backupInfo = {
                    file = file,
                    date = file:match("backup_(%d+)%.json")
                }
                table.insert(mods, backupInfo)
            end
        end
    end
    
    return mods
end

-- ============================================================
-- 8. БЕЗОПАСНЫЙ РЕЖИМ
-- ============================================================

function gameInstaller.enterSafeMode()
    print("⚠️ Вход в безопасный режим...")
    gameInstaller.log("Вход в безопасный режим", "WARNING")
    
    -- Создаём бэкап
    gameInstaller.createBackup()
    
    -- Удаляем все моды
    local mods = love.filesystem.getDirectoryItems(CONFIG.modsFolder)
    for _, mod in ipairs(mods) do
        love.filesystem.remove(CONFIG.modsFolder .. mod)
        print("🗑️ Удалён мод: " .. mod)
    end
    
    -- Создаём файл безопасного режима
    love.filesystem.write("safe_mode.flag", "true")
    
    print("✅ Безопасный режим активирован!")
    gameInstaller.log("Безопасный режим активирован", "INFO")
    gameInstaller.restartGame()
end

function gameInstaller.checkSafeMode()
    local flag = love.filesystem.read("safe_mode.flag")
    if flag == "true" then
        love.filesystem.remove("safe_mode.flag")
        return true
    end
    return false
end

-- ============================================================
-- 9. ЛОГГИРОВАНИЕ
-- ============================================================

function gameInstaller.log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s\n", timestamp, level, message)
    
    -- Добавляем в лог
    table.insert(installLog, logEntry)
    
    -- Сохраняем в файл
    love.filesystem.append("install_log.txt", logEntry)
end

function gameInstaller.getLog()
    return installLog
end

function gameInstaller.clearLog()
    installLog = {}
    love.filesystem.remove("install_log.txt")
end

-- ============================================================
-- 10. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

function gameInstaller.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function gameInstaller.fileExists(filename)
    local info = love.filesystem.getInfo(filename)
    return info and info.type == "file"
end

function gameInstaller.directoryExists(dirname)
    local info = love.filesystem.getInfo(dirname)
    return info and info.type == "directory"
end

function gameInstaller.getFileSize(filename)
    local info = love.filesystem.getInfo(filename)
    if info then
        return info.size
    end
    return 0
end

-- ============================================================
-- 11. API ДЛЯ ВНЕШНЕГО ИСПОЛЬЗОВАНИЯ
-- ============================================================

function gameInstaller.installFromURL(url)
    print("📥 Скачиваем мод с: " .. url)
    gameInstaller.log("Скачивание мода: " .. url, "INFO")
    
    -- В реальности нужно использовать HTTP запросы
    -- Пока просто открываем в браузере
    love.system.openURL(url)
end

function gameInstaller.getInstallStatus()
    return {
        isInstalling = isInstalling,
        hasBackup = gameInstaller.tableLength(backupFiles) > 0,
        installedMod = gameInstaller.getInstalledMod(),
        logSize = #installLog,
        isInitialized = isInitialized
    }
end

function gameInstaller.exportBackup()
    if gameInstaller.tableLength(backupFiles) == 0 then
        print("❌ Нет резервной копии")
        return nil
    end
    
    local backupData = love.data.encode("json", backupFiles)
    local filename = "backup_export_" .. os.time() .. ".json"
    love.filesystem.write(filename, backupData)
    
    print("✅ Бэкап экспортирован: " .. filename)
    ga
