--[[

    Notes:

    Yes, I know this isn't obfuscated

]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local httpservice = game:GetService("HttpService")
local players = game:GetService("Players")
local userinputservice = game:GetService("UserInputService")

local player = players.LocalPlayer
local starttime = os.clock()

local repo = "https://raw.githubusercontent.com/sillyleo67/Twinkhook/main/"
local checkfile = "Twinkhook/Settings/Check.txt"
local executionsfile = "Twinkhook/Settings/Executions.txt"

local changelog = httpservice:JSONDecode(game:HttpGet(repo .. "changelog.json"))
local thisgame

for i, v in next, changelog.games do
    if table.find(v, game.GameId) then
        thisgame = i
    end
end

if not thisgame then
    return false
end

local funcs = { "readfile", "writefile", "isfile", "listfiles", "makefolder", "isfolder", "getcustomasset", "httprequest", "require", "getupvalue", "setupvalue", "filtergc", "newcclosure", "checkcaller", "hookfunction", "hookmetamethod", "getnamecallmethod", "getconnections", "firesignal", "setthreadidentity", "setclipboard", "Drawing", "firetouchinterest", "fireproximityprompt", "fireclickdetector", "mousemoverel", "isnetworkowner", "sethiddenproperty" }

local aliases = {
    httprequest = { "request", "http_request" },
    getupvalue = { "debug.getupvalue" },
    setupvalue = { "debug.setupvalue" },
    newcclosure = { "new_c_closure" },
    hookfunction = { "hookfunc", "replaceclosure" },
    getnamecallmethod = { "get_namecall_method" },
    setthreadidentity = { "setidentity", "set_thread_identity" },
    setclipboard = { "toclipboard" },
    mousemoverel = { "mouse_move_rel" },
    sethiddenproperty = { "set_hidden_property" }
}

local backups = {
    isfile = function(file)
        return (pcall(readfile, file))
    end,
    isfolder = function(folder)
        return (pcall(listfiles, folder))
    end,
    firesignal = function(signal, ...)
        for i, v in next, getconnections(signal) do
            task.spawn(v.Function, ...)
        end
    end
}

local function upvaluefunc(obj)
    return loadstring("local obj = ... return function() return obj end")(obj)
end

local tests = {
    readfile = function() return readfile(checkfile) == "twinkhook" end,
    writefile = function()
        writefile(checkfile, "twinkhook")
        return true
    end,
    isfile = function() return isfile(checkfile) end,
    listfiles = function() return #listfiles("Twinkhook/Settings") > 0 end,
    isfolder = function() return isfolder("Twinkhook") end,
    getcustomasset = function() return type(getcustomasset(checkfile)) == "string" end,
    require = function()
        return (pcall(require, player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)))
    end,
    getupvalue = function() return type(getupvalue(upvaluefunc({}), 1)) == "table" end,
    setupvalue = function()
        local func = upvaluefunc({})
        setupvalue(func, 1, true)
        return func() == true
    end,
    filtergc = function()
        local obj = {}
        local func = upvaluefunc(obj)
        return filtergc("function", { Upvalues = { obj }, IgnoreExecutor = false }, true) == func
    end,
    newcclosure = function()
        return newcclosure(function()
            return true
        end)()
    end,
    checkcaller = function() return checkcaller() end,
    hookfunction = function()
        local func = loadstring("return function() return false end")()
        hookfunction(func, function()
            return true
        end)
        return func()
    end,
    hookmetamethod = function()
        local proxy = newproxy(true)
        getmetatable(proxy).__index = function()
            return false
        end
        hookmetamethod(proxy, "__index", function()
            return true
        end)
        return proxy.anything
    end,
    getconnections = function()
        local event = Instance.new("BindableEvent")
        event.Event:Connect(function() end)
        return #getconnections(event.Event) == 1
    end,
    firesignal = function()
        local event = Instance.new("BindableEvent")
        local fired = false
        event.Event:Connect(function()
            fired = true
        end)
        firesignal(event.Event)
        task.wait()
        return fired
    end,
    setthreadidentity = function()
        return coroutine.wrap(function()
            setthreadidentity(2)
            return true
        end)()
    end,
    Drawing = function()
        Drawing.new("Line"):Remove()
        return true
    end
}

tests.makefolder = tests.isfolder

local executor = {
    name = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknown",
    functions = funcs,
    supported = {},
    bad = false
}

local modulepaths, scripts, cache = {}, {}, {}
local downloading = 0

local function getfunc(funcname)
    local env = getfenv()
    for i, v in next, funcname:split(".") do
        env = env and env[v]
    end
    return env
end

local function fixfunc(funcname)
    if getfunc(funcname) ~= nil then
        return
    end
    for i, v in next, aliases[funcname] or {} do
        if getfunc(v) ~= nil then
            getgenv()[funcname] = getfunc(v)
            return
        end
    end
    getgenv()[funcname] = backups[funcname]
end

local function checkfolders()
    for i, v in next, changelog.directories do
        if not isfolder(v) then
            makefolder(v)
        end
    end
end

local function import(modulename)
    if cache[modulename] == nil then
        cache[modulename] = loadstring(scripts[modulename] or game:HttpGet(repo .. modulepaths[modulename]), "=" .. modulename)()
    end
    return cache[modulename]
end

for i, v in next, changelog.modules do
    for i2, v2 in next, v do
        modulepaths[v2] = i .. "/" .. v2 .. ".luau"
        downloading += 1
        task.spawn(function()
            local succ, res = pcall(function()
                return game:HttpGet(repo .. modulepaths[v2])
            end)
            scripts[v2] = succ and res or nil
            downloading -= 1
        end)
    end
end

for i, v in next, funcs do
    fixfunc(v)
end

pcall(checkfolders)
pcall(writefile, checkfile, "twinkhook")

for i, v in next, funcs do
    local works = getfunc(v) ~= nil
    if works and tests[v] then
        local succ, res = pcall(tests[v])
        works = succ and res == true
    end
    executor.supported[v] = works
end

pcall(delfile, checkfile)
executor.bad = not executor.supported.require

repeat
    task.wait()
until downloading == 0

local executions = (tonumber(select(2, pcall(readfile, executionsfile))) or 0) + 1

pcall(writefile, executionsfile, tostring(executions))

getgenv().twinkhook = {
    game = thisgame,
    version = changelog.version,
    build = changelog.build,
    changelog = changelog.changelog,
    folder = "Twinkhook",
    icon = 110207432540220,
    discord = "https://discord.gg/kbtRmNb8BJ",
    mobile = userinputservice.TouchEnabled and not userinputservice.MouseEnabled,
    starttime = starttime,
    executions = executions,
    theme = {
        FontColor = "f4f2ff",
        AccentColor = "7a52ff",
        MainColor = "15131d",
        BackgroundColor = "0c0b12",
        OutlineColor = "2a2540"
    },
    executor = executor,
    utils = import("utils").new(),
    import = import
}

return true
