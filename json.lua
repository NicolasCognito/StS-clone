-- Simple JSON encoder/decoder for Lua
-- Handles the basic data structures needed for deck serialization

local JSON = {}

-- Escape string for JSON
local function escape(str)
    local replacements = {
        ["\\"] = "\\\\",
        ["\""] = "\\\"",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t",
    }
    return (str:gsub(".", replacements))
end

-- Encode a value to JSON
local function encode_value(val, indent)
    local t = type(val)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    local next_spacing = string.rep("  ", indent + 1)

    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "number" then
        return tostring(val)
    elseif t == "string" then
        return '"' .. escape(val) .. '"'
    elseif t == "table" then
        -- Check if it's an array or object
        local is_array = true
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                is_array = false
                break
            end
        end

        if is_array and count > 0 then
            -- Array
            local parts = {}
            for i, v in ipairs(val) do
                table.insert(parts, next_spacing .. encode_value(v, indent + 1))
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. spacing .. "]"
        else
            -- Object
            local parts = {}
            for k, v in pairs(val) do
                if type(k) == "string" then
                    table.insert(parts, next_spacing .. '"' .. escape(k) .. '": ' .. encode_value(v, indent + 1))
                end
            end
            table.sort(parts)  -- Sort for consistent output
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. spacing .. "}"
        end
    else
        error("Cannot encode type: " .. t)
    end
end

function JSON.encode(val)
    return encode_value(val, 0)
end

-- Decode JSON to Lua value
local function skip_whitespace(str, pos)
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then
            break
        end
        pos = pos + 1
    end
    return pos
end

local function decode_value(str, pos)
    pos = skip_whitespace(str, pos)
    local c = str:sub(pos, pos)

    -- null
    if str:sub(pos, pos + 3) == "null" then
        return nil, pos + 4
    end

    -- true
    if str:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    end

    -- false
    if str:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    end

    -- string
    if c == '"' then
        local start = pos + 1
        local i = start
        local result = {}
        while i <= #str do
            local ch = str:sub(i, i)
            if ch == '"' then
                return table.concat(result), i + 1
            elseif ch == "\\" then
                i = i + 1
                local escape_char = str:sub(i, i)
                if escape_char == "n" then
                    table.insert(result, "\n")
                elseif escape_char == "r" then
                    table.insert(result, "\r")
                elseif escape_char == "t" then
                    table.insert(result, "\t")
                elseif escape_char == "\\" then
                    table.insert(result, "\\")
                elseif escape_char == '"' then
                    table.insert(result, '"')
                else
                    table.insert(result, escape_char)
                end
                i = i + 1
            else
                table.insert(result, ch)
                i = i + 1
            end
        end
        error("Unterminated string")
    end

    -- number
    if c == "-" or (c >= "0" and c <= "9") then
        local start = pos
        local has_dot = false
        while pos <= #str do
            local ch = str:sub(pos, pos)
            if (ch >= "0" and ch <= "9") or ch == "-" or ch == "+" or ch == "e" or ch == "E" then
                pos = pos + 1
            elseif ch == "." then
                has_dot = true
                pos = pos + 1
            else
                break
            end
        end
        local num_str = str:sub(start, pos - 1)
        return tonumber(num_str), pos
    end

    -- array
    if c == "[" then
        local result = {}
        pos = pos + 1
        pos = skip_whitespace(str, pos)

        if str:sub(pos, pos) == "]" then
            return result, pos + 1
        end

        while true do
            local val, new_pos = decode_value(str, pos)
            table.insert(result, val)
            pos = skip_whitespace(str, new_pos)

            local next_char = str:sub(pos, pos)
            if next_char == "]" then
                return result, pos + 1
            elseif next_char == "," then
                pos = pos + 1
            else
                error("Expected ',' or ']' in array")
            end
        end
    end

    -- object
    if c == "{" then
        local result = {}
        pos = pos + 1
        pos = skip_whitespace(str, pos)

        if str:sub(pos, pos) == "}" then
            return result, pos + 1
        end

        while true do
            pos = skip_whitespace(str, pos)

            -- Parse key
            local key, new_pos = decode_value(str, pos)
            if type(key) ~= "string" then
                error("Object key must be string")
            end
            pos = skip_whitespace(str, new_pos)

            -- Expect colon
            if str:sub(pos, pos) ~= ":" then
                error("Expected ':' after object key")
            end
            pos = pos + 1

            -- Parse value
            local val, new_pos2 = decode_value(str, pos)
            result[key] = val
            pos = skip_whitespace(str, new_pos2)

            local next_char = str:sub(pos, pos)
            if next_char == "}" then
                return result, pos + 1
            elseif next_char == "," then
                pos = pos + 1
            else
                error("Expected ',' or '}' in object")
            end
        end
    end

    error("Unexpected character: " .. c)
end

function JSON.decode(str)
    local val, pos = decode_value(str, 1)
    return val
end

return JSON
