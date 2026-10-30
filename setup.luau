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
        break
    end
end

if not thisgame then
    return false
end

local cache = {
    paths = {},
    sources = {}
}

for i, v in next, changelog.modules do
    for i2, v2 in next, v do
        cache.paths[v2] = i .. "/" .. v2 .. ".luau"
        task.spawn(function()
            local succ, res = pcall(function()
                return game:HttpGet(repo .. cache.paths[v2])
            end)
            cache.sources[v2] = succ and res or false
        end)
    end
end

local modules = setmetatable({}, {
    __index = function(self, modulename)
        local path = cache.paths[modulename]
        if not path then
            error("couldn't find " .. modulename .. " in changelog.json", 2)
        end
        while cache.sources[modulename] == nil do
            task.wait()
        end
        rawset(self, modulename, assert(loadstring(cache.sources[modulename] or game:HttpGet(repo .. path), "=" .. modulename))())
        return rawget(self, modulename)
    end
})

local funcs = { "readfile", "writefile", "isfile", "listfiles", "makefolder", "isfolder", "getcustomasset", "request", "require", "getupvalue", "setupvalue", "filtergc", "newcclosure", "checkcaller", "hookfunction", "hookmetamethod", "getnamecallmethod", "getconnections", "firesignal", "setthreadidentity", "setclipboard", "Drawing", "firetouchinterest", "fireproximityprompt", "fireclickdetector", "mousemoverel", "isnetworkowner", "sethiddenproperty" }

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

local function checkfolders()
    for i, v in next, changelog.directories do
        if not isfolder(v) then
            makefolder(v)
        end
    end
end

pcall(checkfolders)

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
    executor = {
        name = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknown",
        functions = funcs,
        supported = {},
        notsupported = {}
    },
    utils = modules.utils.new(),
    modules = modules
}

local executor = getgenv().twinkhook.executor
local env = getfenv()

pcall(writefile, checkfile, "twinkhook")

for i, v in next, funcs do
    executor.supported[v] = env[v] ~= nil
    if executor.supported[v] and tests[v] then
        local succ, res = pcall(tests[v])
        executor.supported[v] = succ and res == true
    end
    if not executor.supported[v] then
        table.insert(executor.notsupported, v)
    end
end

pcall(delfile, checkfile)

return true
