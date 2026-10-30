local twinkhook = getgenv().twinkhook

local httpservice = game:GetService("HttpService")
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local soundservice = game:GetService("SoundService")
local stats = game:GetService("Stats")
local textchatservice = game:GetService("TextChatService")

local repo = "https://raw.githubusercontent.com/sillyleo67/ObsidianUltra/main/"

local library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local thememanager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local savemanager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local toggles, options = library.Toggles, library.Options
local player = players.LocalPlayer
local executor = twinkhook.executor
local supported = executor.supported

local accent = "<font color='#" .. twinkhook.theme.AccentColor .. "'>%s</font>"
local faded = "<font transparency='0.5'>%s</font>"
local dot = "<font color='%s'>●</font>  <b>%s</b>  " .. faded
local versiontext = string.format(accent, "v" .. twinkhook.version) .. "  " .. string.format(faded, twinkhook.build)

local translator = twinkhook.modules.translator.new(twinkhook.folder)
local discord = twinkhook.modules.discord.new(library, twinkhook.discord)

local function notify(title, desc, icon, force, chat)
    if library.Unloaded or not force and not toggles.EnableNotifications.Value then
        return
    end
    if toggles.PlaySound.Value then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. options.NotificationSound.Value
        sound.Volume = options.SoundVolume.Value
        sound.PlayOnRemove = true
        sound.Parent = soundservice
        sound:Destroy()
    end
    library:Notify({ Title = title, Description = desc, Icon = icon, Time = options.NotificationTime.Value })
    local channels = chat and textchatservice:FindFirstChild("TextChannels")
    local general = channels and channels:FindFirstChild("RBXGeneral")
    if general then
        pcall(general.SendAsync, general, chat)
    end
end

local function additems(parent, items, prefix)
    for i, v in next, items do
        local args = v.Name and { prefix .. v.Name, v.Arguments } or { v.Arguments }
        if v.Arguments and v.Arguments[1] ~= nil then
            args = v.Arguments
        end
        local item = parent["Add" .. v.Type:gsub("^Add", "")](parent, unpack(args))
        if v.Dependencies then
            for i2, v2 in next, v.Dependencies do
                v2[1] = toggles[prefix .. v2[1]] or options[prefix .. v2[1]]
            end
            item:SetupDependencies(v.Dependencies)
        end
        if v.Elements then
            additems(item, v.Elements, prefix)
        end
    end
end

local themeupdate = thememanager.ThemeUpdate

thememanager:SetLibrary(library)
thememanager:SetFolder(twinkhook.folder)
thememanager.BuiltInThemes.Twinkhook = { 1, twinkhook.theme }
thememanager.BuiltInThemes.Halloween = { 2, { FontColor = "ffe8d1", AccentColor = "ff7a1a", MainColor = "1f1410", BackgroundColor = "140d0a", OutlineColor = "4a2a14" } }

function thememanager:ThemeUpdate()
    library.Scheme.BlueColor = options.AccentColor and options.AccentColor.Value or library.Scheme.AccentColor
    themeupdate(self)
end

thememanager:SetDefaultTheme(twinkhook.theme)
library.Scheme.BlueColor = library.Scheme.AccentColor

local theme, saved = thememanager:GetDefaultTheme()

if saved then
    thememanager:ApplyTheme(theme)
end

savemanager:SetLibrary(library)
savemanager:SetFolder(twinkhook.folder .. "/" .. twinkhook.game)
savemanager:IgnoreThemeSettings()
savemanager:SetIgnoreIndexes({ "Language" })

library.window = library:CreateWindow({
    Title = "Twinkhook",
    Footer = string.format("Game: %s  |  Executor: %s  |  Build: %s  |  Version: %s", twinkhook.game, executor.name, twinkhook.build, twinkhook.version),
    Icon = twinkhook.icon,
    Size = UDim2.fromOffset(1220, 720),
    Center = true,
    NotifySide = "Left"
})

library.loading = library:CreateLoading({
    Title = "Twinkhook",
    Icon = twinkhook.icon,
    TotalSteps = 5,
    AutoResizeHeight = true
})

local effects = twinkhook.modules.effects.new(library, twinkhook.folder)

translator:start(library)
effects:start()

library.savemanager = savemanager
library.discord = discord
library.notify = notify

twinkhook.library = library
twinkhook.translator = translator
twinkhook.accent = accent

for i, v in next, twinkhook.changelog do
    twinkhook.changelog[i] = "<font color='#5cff5c'>" .. v .. "</font>"
end

table.insert(twinkhook.changelog, 1, "[" .. twinkhook.game .. "]  " .. versiontext)

function library:addhome(tab, addgame)
    local banner = tab:AddPlayerInfo("Changelog", { Title = "Latest Changelog", Description = twinkhook.changelog })
    for i, v in next, banner.Holder:FindFirstChildOfClass("Frame"):GetChildren() do
        if v:FindFirstChildOfClass("ImageLabel") then
            v.Visible = false
        end
        if v:FindFirstChildOfClass("TextLabel") then
            v.Position = UDim2.new()
            v.Size = UDim2.fromScale(1, 1)
        end
    end
    local lines = {
        "@" .. player.Name .. "  " .. string.format(faded, player.UserId),
        { Divider = true },
        "Executor:  " .. string.format(accent, executor.name),
        "Executions:  " .. string.format(accent, twinkhook.executions),
        "Twinkhook:  " .. versiontext
    }
    local profile = tab:AddLeftGroupbox("Profile", "user")
    profile:AddPlayerInfo("Profile", { Player = player, ThumbnailType = "Bust", Title = player.DisplayName, Description = lines })
    profile:AddLabel("<b>" .. player.DisplayName .. "</b>", true)
    for i, v in next, lines do
        if v.Divider then
            profile:AddDivider()
        else
            profile:AddLabel(v, true)
        end
    end
    local tabbox = tab:AddRightTabbox()
    local gameinfo = tabbox:AddTab("Game", "gamepad-2")
    gameinfo:AddLabel("Game:  <b>" .. twinkhook.game .. "</b>", true)
    addgame(gameinfo)
    local gamelist = tabbox:AddTab("Games", "list-checks")
    gamelist:AddLabel(string.format(dot, "#7ee787", "DOORS", twinkhook.game == "Doors" and "this game" or "supported"), true)
    gamelist:AddLabel(string.format(dot, "#7ee787", "Jailbreak", twinkhook.game == "Jailbreak" and "this game" or "supported"), true)
    gamelist:AddLabel(string.format(dot, "#d29922", "Murder Mystery 2", "coming soon"), true)
    gamelist:AddDivider()
    gamelist:AddLabel("Supported:  <b>2</b>  " .. string.format(faded, "1 coming soon"), true)
    gamelist:AddLabel("Want a game added? Ask in the Discord.", true)
    local information = tabbox:AddTab("Information", "info")
    information:AddLabel("Version:  <b>v" .. twinkhook.version .. "</b>  " .. string.format(faded, twinkhook.build), true)
    information:AddLabel("Executor:  <b>" .. executor.name .. "</b>", true)
    information:AddLabel("Functions:  <b>" .. #executor.functions - #executor.notsupported .. " / " .. #executor.functions .. "</b>  " .. string.format(faded, "supported"), true)
    information:AddLabel("Executions:  <b>" .. twinkhook.executions .. "</b>", true)
    information:AddLabel(string.format("Loaded In:  <b>%.1fs</b>", os.clock() - twinkhook.starttime), true)
    local server = tab:AddRightGroupbox("Discord", "message-circle")
    server:AddLabel("Discord:  <b>" .. twinkhook.discord:gsub("https://", "") .. "</b>", true)
    local members = server:AddLabel("Members:  <b>" .. string.format(faded, "checking...") .. "</b>", true)
    server:AddDivider()
    server:AddButton({ Text = "Join Discord", Callback = discord.join }):AddButton({ Text = "Copy Link", Callback = discord.copy })
    task.spawn(function()
        local total, online = discord.members()
        if total then
            members:SetText("Members:  <b>" .. total .. "</b>  " .. string.format(faded, online .. " online"))
        else
            members:SetText("Members:  <b>" .. string.format(faded, "unknown") .. "</b>")
        end
    end)
end

function library:addsettings(tab, segment, unload)
    local menu = tab:AddLeftGroupbox("Menu", "sliders-horizontal")
    menu:AddToggle("KeybindMenu", { Text = "Keybind Menu", Callback = function(state)
        library.KeybindFrame.Visible = state
    end })
    menu:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(state)
        library.ShowCustomCursor = state
    end })
    menu:AddToggle("ShowWatermark", { Text = "Show Watermark", Default = true, Callback = function(state)
        library:SetWatermarkVisibility(state)
    end })
    menu:AddDropdown("Language", { Values = translator.list, Default = translator.language, Searchable = true, Text = "Language", Callback = function(value)
        translator.language = value
        pcall(writefile, twinkhook.folder .. "/Settings/Language.txt", value)
    end })
    menu:AddDivider()
    menu:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu Keybind" })
    library.Watermark:SetSegments({
        { Player = player },
        { Icon = twinkhook.icon, Text = "Twinkhook", Accent = true },
        segment,
        { Icon = "gauge", Text = function()
            return math.floor(1 / runservice.RenderStepped:Wait()) .. " fps"
        end },
        { Icon = "wifi", Text = function()
            return math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms"
        end }
    })
    library:SetWatermarkVisibility(true)
    local notifs = tab:AddLeftGroupbox("Notifications", "bell")
    notifs:AddToggle("EnableNotifications", { Text = "Enable Notifications" })
    notifs:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = 1, Text = "Notification Side", Callback = function(value)
        library:SetNotifySide(value)
    end })
    notifs:AddSlider("NotificationTime", { Text = "Notification Time", Default = 5, Min = 1, Max = 20, Rounding = 0 })
    notifs:AddDivider()
    notifs:AddToggle("PlaySound", { Text = "Play Sound" })
    notifs:AddInput("NotificationSound", { Default = "3318713980", Numeric = true, Finished = true, ClearTextOnFocus = false, Text = "Notification Sound", Placeholder = "3318713980" })
    notifs:AddSlider("SoundVolume", { Text = "Sound Volume", Default = 2, Min = 1, Max = 10, Rounding = 1 })
    notifs:AddDivider()
    notifs:AddButton({ Text = "Test Notification", Callback = function()
        notify("Test Notification", "Notifications are working.", "bell", true)
    end })
    local fx = tab:AddRightGroupbox("Menu Effects", "sparkles")
    fx:AddDropdown("MenuBackground", { Values = { "None", "Snow", "Rain", "Stars", "Confetti", "Bubbles", "Fireflies", "Embers", "Sparkles" }, Default = 1, Text = "Menu Background" })
    fx:AddSlider("EffectAmount", { Text = "Effect Amount", Default = 90, Min = 10, Max = 150, Rounding = 0, Callback = function()
        effects.current = nil
    end })
    fx:AddSlider("EffectSpeed", { Text = "Effect Speed", Default = 1, Min = 0.1, Max = 3, Rounding = 1, Suffix = "x" })
    fx:AddToggle("DimBackground", { Text = "Dim Background", Default = true })
    fx:AddToggle("AlwaysShowEffects", { Text = "Always Show Effects" })
    fx:AddDivider()
    fx:AddLabel("Put .mp3 or .ogg files in <b>" .. twinkhook.folder .. "/Music</b> and execute again to see them.", true)
    fx:AddToggle("MenuMusic", { Text = "Menu Music", Disabled = not supported.getcustomasset })
    fx:AddDropdown("MusicFile", { Values = effects.songs, Default = 1, Searchable = true, Text = "Music File", Callback = function()
        effects.music:Stop()
        effects.music.SoundId = ""
    end })
    fx:AddSlider("MusicVolume", { Text = "Music Volume", Default = 1, Min = 0, Max = 5, Rounding = 1, Callback = function(value)
        effects.music.Volume = value
    end })
    fx:AddToggle("AlwaysPlayMusic", { Text = "Always Play Music" })
    local scr = tab:AddRightGroupbox("Script", "file-code")
    scr:AddButton({ Text = "Panic", DoubleClick = true, Tooltip = "Turns every toggle in the script off.", Callback = function()
        for i, v in next, toggles do
            v:SetValue(false)
        end
        notify("Panic", "Turned off every toggle.", "siren", true)
    end })
    scr:AddButton({ Text = "Unload", DoubleClick = true, Callback = function()
        for i, v in next, toggles do
            v:SetValue(false)
        end
        task.wait(0.3)
        unload()
        getgenv().twinkhook = nil
        library:Unload()
    end })
end

function library:addaddons(tab, config)
    local folder = twinkhook.folder .. "/Addons"
    local api = config.api
    local loaded, side = {}, "Right"
    api.Library = library
    api.Window = library.window
    api.Toggles = toggles
    api.Options = options
    api.Tabs = config.tabs
    api.Script = twinkhook
    api.Notify = api.Notify or notify
    function api.GetPlayers()
        local plrs = {}
        for i, v in next, players:GetPlayers() do
            if v ~= player then
                table.insert(plrs, v)
            end
        end
        return plrs
    end
    function api.IsEnabled(flag)
        return toggles[flag] ~= nil and toggles[flag].Value
    end
    function api.IsActive(flag)
        local key = options[flag .. "Key"]
        return api.IsEnabled(flag) and (key == nil or key:GetState())
    end
    function api.GetValue(flag)
        local item = toggles[flag] or options[flag]
        return item and item.Value
    end
    function api.GetFeatures()
        local features = {}
        for i, v in next, toggles do
            features[i] = v.Value
        end
        return features
    end
    function api.OnFeatureChanged(flag, func)
        local item = toggles[flag] or options[flag]
        local oldchanged = item.Changed or function() end
        item.Changed = function(...)
            oldchanged(...)
            func(item.Value)
        end
    end
    pcall(makefolder, folder)
    local box = tab:AddLeftGroupbox("Addons", "puzzle")
    box:AddLabel("Put addon files in <b>" .. folder .. "</b> and execute again to load them.", true)
    box:AddLabel("<font color='#d29922'>Addons are made by other people, only run ones you trust.</font>", true)
    box:AddDivider()
    local label = box:AddLabel("Loaded:  <b>none</b>", true)
    box:AddButton({ Text = "Copy Example Addon", Callback = function()
        setclipboard(config.example)
        notify("Example Copied", "Save it as a .lua file in " .. folder .. ".", "clipboard", true)
    end })
    box:AddButton({ Text = "Save Example Addon", Callback = function()
        pcall(writefile, folder .. "/JoinAlert.lua", config.example)
        notify("Example Saved", "It's in " .. folder .. "/JoinAlert.lua, execute Twinkhook again to load it.", "save", true)
    end })
    for i, v in next, supported.listfiles and listfiles(folder) or {} do
        if v:find(".lua", 1, true) then
            local succ, res = pcall(function()
                local addon = loadstring(readfile(v))(library, api)
                local games = httpservice:JSONEncode(addon.Game or "*"):lower()
                if not games:find('"*"', 1, true) and not games:find('"' .. config.game .. '"', 1, true) then
                    return
                end
                local parent = config.tabs[addon.Tab] or tab
                local title = addon.Title or addon.Name
                local group = (addon.Side or side) == "Right" and parent:AddRightGroupbox(title, addon.Icon or "puzzle") or parent:AddLeftGroupbox(title, addon.Icon or "puzzle")
                side = side == "Right" and "Left" or "Right"
                if addon.Description then
                    group:AddLabel(addon.Description, true)
                    group:AddDivider()
                end
                if addon.Elements then
                    additems(group, addon.Elements, addon.Name:gsub("%s+", "") .. "_")
                end
                if addon.Init then
                    addon.Init(group, api)
                end
                table.insert(loaded, title)
            end)
            if not succ then
                notify("Addon Failed", v:match("[^/\\]+$") .. " couldn't be loaded: " .. tostring(res), "puzzle", true)
            end
        end
    end
    if #loaded > 0 then
        label:SetText("Loaded:  <b>" .. table.concat(loaded, ", ") .. "</b>")
    end
end

function library:finish(settingstab, requirements)
    local notsupported, disabled = {}, {}
    for i, v in next, requirements do
        if not supported[i] then
            table.insert(notsupported, i)
            for i2, v2 in next, v do
                if not disabled[v2] then
                    disabled[v2] = {}
                end
                table.insert(disabled[v2], i)
            end
        end
    end
    for i, v in next, disabled do
        local toggle = toggles[i]
        if toggle.TooltipTable then
            toggle.TooltipTable:Destroy()
        end
        toggle.TooltipTable = library:AddTooltip(toggle.Tooltip, "Your executor doesn't have " .. table.concat(v, ", ") .. ".", toggle.Holder)
        toggle.Unsupported = true
        toggle:SetDisabled(true)
    end
    if #notsupported > 0 then
        table.sort(notsupported)
        notify("Missing Functions", executor.name .. " doesn't support " .. table.concat(notsupported, ", ") .. " so some features wont work.", "triangle-alert", true)
    end
    library.ToggleKeybind = options.MenuKeybind
    savemanager:BuildConfigSection(settingstab)
    thememanager:ApplyToTab(settingstab)
end

function library:finishloading()
    local loading = self.loading
    local started = os.clock()
    loading:SetMessage("Translating the menu")
    loading:SetCurrentStep(loading.TotalSteps)
    task.wait(1)
    repeat
        task.wait(0.1)
    until translator.done or translator.failed or os.clock() - started > 30
    if translator.failed then
        loading:SetMessage("Failed to translate the menu")
        task.wait(2)
    end
    loading:Destroy()
    twinkhook.loadtime = string.format("%.1f", os.clock() - twinkhook.starttime)
    library:Notify({ Title = "Twinkhook Loaded", Description = twinkhook.game .. " loaded in " .. twinkhook.loadtime .. "s on " .. executor.name .. ".", Icon = twinkhook.icon, Time = 8 })
    library:Notify({ Title = "Menu", Description = twinkhook.mobile and "Use the toggle button to open and close the menu." or "Press " .. options.MenuKeybind.Value .. " to open and close the menu.", Icon = "keyboard", Time = 20 })
end

return library
