-- ============================================================
-- MODULE: game_installer.lua
-- Full game replacement system through mods
-- Version: 1.0
-- ============================================================

local gameInstaller = {}

-- ========== CONFIGURATION ==========
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

-- ========== VARIABLES ==========
local installQueue = {}
local isInstalling = false
local backupFiles = {}
local installLog = {}
local isInitialized = false

-- ============================================================
-- 1. INITIALIZATION
-- ============================================================

function gameInstaller.init()
    if isInitialized then return true end
    
    print("Initializing mod installation system...")
    
    -- Create folders
    local folders = {
        CONFIG.backupFolder,
        CONFIG.tempFolder,
        CONFIG.modsFolder
    }
    
    for _, folder in ipairs(folders) do
        if not love.filesystem.getInfo(folder) then
            love.filesystem.createDirectory(folder)
            print("Created folder: " .. folder)
        end
    end
    
    -- Check install queue
    gameInstaller.checkInstallQueue()
    
    -- Check restart flag
    if gameInstaller.checkForRestart() then
        print("Game restarted with new mod!")
        gameInstaller.log("Game restarted", "INFO")
    end
    
    -- Check safe mode
    if gameInstaller.checkSafeMode() then
        print("Safe mode activated!")
        gameInstaller.log("Safe mode activated", "WARNING")
    end
    
    isInitialized = true
    print("Mod installation system initialized!")
    return true
end

-- ============================================================
-- 2. INSTALL MOD FROM ZIP
-- ============================================================

function gameInstaller.installModFromZIP(zipData, zipName, modInfo)
    if isInstalling then
        print("Already installing!")
        gameInstaller.log("Attempted install during another install", "WARNING")
        return false
    end
    
    isInstalling = true
    gameInstaller.log("Starting install: " .. zipName, "INFO")
    print("Installing mod: " .. zipName)
    
    -- Create temp file
    local tempPath = CONFIG.tempFolder .. zipName
    love.filesystem.write(tempPath, zipData)
    print("Temp file created: " .. tempPath)
    
    -- Unzip
    local success, files = pcall(function()
        return gameInstaller.unzip(tempPath)
    end)
    
    if not success or not files then
        print("Failed to unzip")
        gameInstaller.log("Failed to unzip", "ERROR")
        isInstalling = false
        return false
    end
    
    print("Unzipped files: " .. gameInstaller.tableLength(files))
    
    -- Check for main game files
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
        print("Mod missing main.lua, game.lua or conf.lua!")
        gameInstaller.log("Mod missing main game files", "ERROR")
        isInstalling = false
        return false
    end
    
    -- Create backup
    gameInstaller.createBackup()
    
    -- Install files
    success = gameInstaller.installFiles(files, modInfo)
    
    if success then
        print("Mod installed! Restarting game...")
        gameInstaller.log("Mod installed: " .. zipName, "SUCCESS")
        isInstalling = false
        
        -- Save install info
        gameInstaller.saveInstallInfo(zipName, modInfo)
        
        -- Restart game
        gameInstaller.restartGame()
        return true
    else
        print("Install failed! Restoring...")
        gameInstaller.log("Install failed, restoring", "ERROR")
        gameInstaller.restoreBackup()
        isInstalling = false
        return false
    end
end

-- ============================================================
-- 3. FILE OPERATIONS
-- ============================================================

function gameInstaller.createBackup()
    print("Creating backup...")
    backupFiles = {}
    
    -- Get all files in root
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
    
    -- Save backup to file
    local backupData = love.data.encode("json", backupFiles)
    local backupName = "backup_" .. os.time() .. ".json"
    love.filesystem.write(CONFIG.backupFolder .. backupName, backupData)
    
    print("Backup created: " .. gameInstaller.tableLength(backupFiles) .. " files")
    gameInstaller.log("Backup created: " .. gameInstaller.tableLength(backupFiles) .. " files", "INFO")
    return backupName
end

function gameInstaller.restoreBackup()
    print("Restoring from backup...")
    gameInstaller.log("Starting restore from backup", "INFO")
    
    -- Find latest backup
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
                print("Found backup: " .. latestBackup)
            end
        end
    end
    
    -- Delete all files (except protected)
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
                gameInstaller.removeDirectory(file)
                deleted = deleted + 1
            end
        end
    end
    
    print("Deleted files: " .. deleted)
    
    -- Restore from backup
    local restored = 0
    for filename, content in pairs(backupFiles) do
        love.filesystem.write(filename, content)
        restored = restored + 1
    end
    
    print("Restored files: " .. restored)
    gameInstaller.log("Restored files: " .. restored, "INFO")
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
    print("Installing new files...")
    local installed = 0
    local skipped = 0
    
    -- Write new files
    for filename, content in pairs(files) do
        -- Check if protected
        local isProtected = false
        for _, p in ipairs(CONFIG.protectedFiles) do
            if filename:match(p) or filename:find(p) or filename == p then
                isProtected = true
                break
            end
        end
        
        if not isProtected then
            -- Create folders if needed
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
                        print("Created folder: " .. currentPath)
                    end
                end
            end
            
            love.filesystem.write(filename, content)
            installed = installed + 1
        else
            skipped = skipped + 1
        end
    end
    
    print("Installed: " .. installed .. ", skipped: " .. skipped)
    gameInstaller.log("Installed: " .. installed .. ", skipped: " .. skipped, "INFO")
    return true
end

-- ============================================================
-- 4. UNZIP
-- ============================================================

function gameInstaller.unzip(zipPath)
    print("Unzipping: " .. zipPath)
    local files = {}
    local content = love.filesystem.read(zipPath)
    
    if not content then
        print("Failed to read ZIP")
        return false, nil
    end
    
    -- Simple ZIP parser
    local pos = 1
    local fileCount = 0
    local maxPos = #content
    
    while pos < maxPos and pos > 0 do
        local sig = content:sub(pos, pos+3)
        
        if sig == "PK\3\4" then
            -- File header
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
                        print("Unzipped " .. fileCount .. " files...")
                    end
                end
            end
            
            pos = dataPos + dataLen
        else
            pos = pos + 1
        end
        
        -- Safety
        if pos > maxPos then break end
        if pos < 1 then break end
    end
    
    -- Remove temp file
    love.filesystem.remove(zipPath)
    
    print("Unzipped files: " .. fileCount)
    return true, files
end

-- ============================================================
-- 5. INSTALL QUEUE
-- ============================================================

function gameInstaller.checkInstallQueue()
    local installFile = "pending_install.json"
    local data = love.filesystem.read(installFile)
    
    if data then
        print("Found install file!")
        local installData = love.data.decode("json", data)
        
        if installData and installData.modId then
            print("Mod to install: " .. (installData.title or "No title"))
            gameInstaller.log("Found mod in queue: " .. installData.title, "INFO")
            
            local success = gameInstaller.installModFromZIP(
                installData.zipData,
                installData.zipName or "mod.zip",
                installData
            )
            
            if success then
                love.filesystem.remove(installFile)
                print("Mod installed from queue!")
                gameInstaller.log("Mod installed from queue", "SUCCESS")
            else
                print("Failed to install from queue!")
                gameInstaller.log("Failed to install from queue", "ERROR")
            end
        else
            love.filesystem.remove(installFile)
            print("Invalid install file")
        end
    end
end

-- ============================================================
-- 6. RESTART GAME
-- ============================================================

function gameInstaller.restartGame()
    print("Restarting game...")
    gameInstaller.log("Restarting game", "INFO")
    
    -- Save restart flag
    love.filesystem.write("restart.flag", "true")
    
    -- Quit game
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
-- 7. MOD MANAGEMENT
-- ============================================================

function gameInstaller.saveInstallInfo(zipName, modInfo)
    local info = {
        modName = zipName,
        title = modInfo and modInfo.title or "Unknown mod",
        author = modInfo and modInfo.author or "Unknown",
        version = modInfo and modInfo.version or "1.0",
        installed = os.time(),
        date = os.date("%Y-%m-%d %H:%M:%S"),
        isGameReplacement = true
    }
    
    local json = love.data.encode("json", info)
    love.filesystem.write("installed_mod.json", json)
    
    print("Mod info saved: " .. info.title)
    gameInstaller.log("Saved mod info: " .. info.title, "INFO")
end

function gameInstaller.getInstalledMod()
    local data = love.filesystem.read("installed_mod.json")
    if data then
        return love.data.decode("json", data)
    end
    return nil
end

function gameInstaller.uninstallMod()
    local modInfo = gameInstaller.getInstalledMod()
    if not modInfo then
        print("No mod installed")
        gameInstaller.log("Attempted uninstall but no mod", "WARNING")
        return false
    end
    
    print("Uninstalling mod: " .. modInfo.title)
    gameInstaller.log("Uninstalling mod: " .. modInfo.title, "INFO")
    
    -- Restore backup
    gameInstaller.restoreBackup()
    
    -- Remove info file
    love.filesystem.remove("installed_mod.json")
    
    print("Mod uninstalled!")
    gameInstaller.log("Mod uninstalled", "INFO")
    return true
end

function gameInstaller.getInstalledMods()
    local mods = {}
    
    local current = gameInstaller.getInstalledMod()
    if current then
        table.insert(mods, current)
    end
    
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
-- 8. SAFE MODE
-- ============================================================

function gameInstaller.enterSafeMode()
    print("Entering safe mode...")
    gameInstaller.log("Entering safe mode", "WARNING")
    
    -- Create backup
    gameInstaller.createBackup()
    
    -- Delete all mods
    local mods = love.filesystem.getDirectoryItems(CONFIG.modsFolder)
    for _, mod in ipairs(mods) do
        love.filesystem.remove(CONFIG.modsFolder .. mod)
        print("Deleted mod: " .. mod)
    end
    
    -- Create safe mode flag
    love.filesystem.write("safe_mode.flag", "true")
    
    print("Safe mode activated!")
    gameInstaller.log("Safe mode activated", "INFO")
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
-- 9. LOGGING
-- ============================================================

function gameInstaller.log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s\n", timestamp, level, message)
    
    table.insert(installLog, logEntry)
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
-- 10. HELPER FUNCTIONS
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
-- 11. API
-- ============================================================

function gameInstaller.installFromURL(url)
    print("Downloading mod from: " .. url)
    gameInstaller.log("Downloading mod: " .. url, "INFO")
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
        print("No backup")
        return nil
    end
    
    local backupData = love.data.encode("json", backupFiles)
    local filename = "backup_export_" .. os.time() .. ".json"
    love.filesystem.write(filename, backupData)
    
    print("Backup exported: " .. filename)
    gameInstaller.log("Backup exported: " .. filename, "INFO")
    return filename
end

function gameInstaller.importBackup(filename)
    local data = love.filesystem.read(filename)
    if not data then
        print("File not found")
        return false
    end
    
    local backupData = love.data.decode("json", data)
    if not backupData then
        print("Failed to read backup")
        return false
    end
    
    backupFiles = backupData
    print("Backup imported: " .. gameInstaller.tableLength(backupFiles) .. " files")
    gameInstaller.log("Backup imported: " .. gameInstaller.tableLength(backupFiles) .. " files", "INFO")
    return true
end

-- ============================================================
-- 12. DIAGNOSTICS
-- ============================================================

function gameInstaller.diagnose()
    print("========== INSTALLER DIAGNOSTICS ==========")
    print("Initialized: " .. tostring(isInitialized))
    print("Installing: " .. tostring(isInstalling))
    print("Backup count: " .. gameInstaller.tableLength(backupFiles))
    print("Log size: " .. #installLog)
    
    local installed = gameInstaller.getInstalledMod()
    if installed then
        print("Installed mod: " .. installed.title)
        print("  Author: " .. installed.author)
        print("  Version: " .. installed.version)
        print("  Date: " .. installed.date)
    else
        print("No mod installed")
    end
    
    print("Folders:")
    local folders = {"", CONFIG.modsFolder, CONFIG.backupFolder, CONFIG.tempFolder}
    for _, folder in ipairs(folders) do
        local exists = love.filesystem.getInfo(folder)
        print("  " .. folder .. ": " .. (exists and "OK" or "MISSING"))
    end
    
    print("============================================")
end

-- ============================================================
-- 13. AUTO INIT
-- ============================================================

gameInstaller.init()

-- ============================================================
-- RETURN MODULE
-- ============================================================
return gameInstaller
