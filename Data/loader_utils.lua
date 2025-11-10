-- SHARED LOADER UTILITIES
-- Provides helpers for auto-loading collections of Lua modules from directories

local LoaderUtils = {}

local pathSeparator = package.config:sub(1, 1)

local function normalizePath(path)
    if not path then
        return nil
    end
    if pathSeparator == "\\" then
        return path:gsub("/", "\\")
    end
    return path:gsub("\\", "/")
end

local function buildCommand(directory)
    if pathSeparator == "\\" then
        return string.format('cmd /C dir /b "%s"', directory)
    end
    return string.format('ls -1 "%s"', directory)
end

local function parentDirectory(path)
    if not path then
        return nil
    end
    local directory = path:match("(.+)[/\\][^/\\]+$")
    if not directory then
        return nil
    end
    return normalizePath(directory)
end

local function searchModulePath(moduleName)
    if not moduleName then
        return nil
    end

    if package.searchpath then
        local found = package.searchpath(moduleName, package.path)
        if found then
            return normalizePath(found)
        end
    end

    local target = moduleName:gsub("%.", pathSeparator)
    for template in package.path:gmatch("[^;]+") do
        local candidate = template:gsub("%?", target)
        local file = io.open(candidate, "r")
        if file then
            file:close()
            return normalizePath(candidate)
        end
    end

    return nil
end

function LoaderUtils.getScriptDirectory(stackLevel)
    local level = (stackLevel or 2)
    while true do
        local info = debug.getinfo(level, "S")
        if not info then
            return "."
        end

        if info.source and info.source:sub(1, 1) == "@" then
            local source = info.source:sub(2)
            local directory = source:match("(.+)[/\\]")
            if directory then
                return normalizePath(directory)
            end
            return "."
        end

        level = level + 1
    end
end

function LoaderUtils.listLuaFiles(directory)
    local normalizedDir = normalizePath(directory)

    if not normalizedDir then
        return nil, "invalid directory"
    end
    if not io or not io.popen then
        return nil, "io.popen unavailable in this Lua build"
    end

    local command = buildCommand(normalizedDir)
    local handle = io.popen(command)
    if not handle then
        return nil, "could not enumerate directory: " .. normalizedDir
    end

    local files = {}
    for fileName in handle:lines() do
        if fileName:sub(-4) == ".lua" then
            table.insert(files, fileName:sub(1, -5))
        end
    end
    handle:close()

    table.sort(files)
    return files
end

local function resolveBaseDirectory(opts, stackLevel)
    if opts and opts.baseDirectory then
        local normalized = normalizePath(opts.baseDirectory)
        if normalized then
            return normalized
        end
    end

    if opts and opts.moduleName then
        local modulePath = searchModulePath(opts.moduleName)
        local directory = parentDirectory(modulePath)
        if directory then
            return directory
        end
    end

    return LoaderUtils.getScriptDirectory(stackLevel)
end

function LoaderUtils.loadModules(target, modulePrefix, subdirectory, opts)
    if type(target) ~= "table" then
        error("target table is required")
    end
    if type(modulePrefix) ~= "string" then
        error("modulePrefix must be a string")
    end

    opts = opts or {}
    local stackLevel = (opts.stackLevel or 3)

    local baseDir = resolveBaseDirectory(opts, stackLevel)
    local directory = subdirectory and (baseDir .. pathSeparator .. subdirectory) or baseDir

    local files, err = LoaderUtils.listLuaFiles(directory)
    if not files then
        error(("Failed to autoload modules from '%s': %s"):format(directory, err))
    end

    for _, fileName in ipairs(files) do
        local moduleName = modulePrefix .. "." .. fileName
        local ok, module = pcall(require, moduleName)
        if not ok then
            error(("Failed to load module '%s': %s"):format(moduleName, module))
        end

        if type(module) == "table" then
            for key, value in pairs(module) do
                target[key] = value
            end
        end
    end

    return target
end

return LoaderUtils
