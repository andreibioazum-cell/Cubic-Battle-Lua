-- json.lua
-- Простой парсер JSON

local json = {}

function json.encode(tbl)
    local function encode_value(val)
        local t = type(val)
        
        if t == "string" then
            return '"' .. val:gsub('"', '\\"') .. '"'
        elseif t == "number" then
            return tostring(val)
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "table" then
            return json.encode(val)
        elseif t == "nil" then
            return "null"
        else
            return "null"
        end
    end
    
    if type(tbl) == "table" then
        local is_array = true
        local count = 0
        
        for k, v in pairs(tbl) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
            count = count + 1
        end
        
        if is_array then
            local result = {}
            for i, v in ipairs(tbl) do
                table.insert(result, encode_value(v))
            end
            return "[" .. table.concat(result, ",") .. "]"
        else
            local result = {}
            for k, v in pairs(tbl) do
                if type(k) == "string" then
                    table.insert(result, '"' .. k .. '":' .. encode_value(v))
                end
            end
            return "{" .. table.concat(result, ",") .. "}"
        end
    else
        return encode_value(tbl)
    end
end

function json.decode(str)
    local function parse_string(s)
        return s:sub(2, -2)
    end
    
    local function parse_number(s)
        return tonumber(s) or 0
    end
    
    local function parse_value(s)
        s = s:match("^%s*(.-)%s*$")
        
        if s == "null" then return nil end
        if s == "true" then return true end
        if s == "false" then return false end
        
        if s:sub(1,1) == '"' then
            return parse_string(s)
        end
        
        if s:sub(1,1) == '{' then
            return json.decode(s)
        end
        
        if s:sub(1,1) == '[' then
            local items = {}
            local current = ""
            local depth = 0
            
            for i = 2, #s - 1 do
                local c = s:sub(i, i)
                if c == "{" or c == "[" then
                    depth = depth + 1
                    current = current .. c
                elseif c == "}" or c == "]" then
                    depth = depth - 1
                    current = current .. c
                elseif c == "," and depth == 0 then
                    if current ~= "" then
                        table.insert(items, parse_value(current))
                        current = ""
                    end
                else
                    current = current .. c
                end
            end
            
            if current ~= "" then
                table.insert(items, parse_value(current))
            end
            
            return items
        end
        
        return parse_number(s)
    end
    
    if type(str) ~= "string" then
        return str
    end
    
    str = str:match("^%s*(.-)%s*$")
    
    if str == "" then return {} end
    
    if str:sub(1,1) == '{' then
        local result = {}
        local current_key = nil
        local current_value = ""
        local in_string = false
        local depth = 0
        
        for i = 2, #str - 1 do
            local c = str:sub(i, i)
            
            if c == '"' and str:sub(i-1, i-1) ~= '\\' then
                in_string = not in_string
            end
            
            if not in_string and c == ":" and current_key == nil then
                current_key = parse_value(current_value)
                current_value = ""
            elseif not in_string and c == "," and depth == 0 then
                if current_key then
                    result[current_key] = parse_value(current_value)
                    current_key = nil
                    current_value = ""
                end
            elseif not in_string and (c == "{" or c == "[") then
                depth = depth + 1
                current_value = current_value .. c
            elseif not in_string and (c == "}" or c == "]") then
                depth = depth - 1
                current_value = current_value .. c
            else
                current_value = current_value .. c
            end
        end
        
        if current_key then
            result[current_key] = parse_value(current_value)
        end
        
        return result
    end
    
    return parse_value(str)
end

return json
