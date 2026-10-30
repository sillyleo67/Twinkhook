local runservice = game:GetService("RunService")
local soundservice = game:GetService("SoundService")

local udim = UDim2.fromOffset

local function create(classname, properties)
    local inst = Instance.new(classname)
    for i, v in next, properties do
        if i ~= "Parent" then
            inst[i] = v
        end
    end
    inst.Parent = properties.Parent
    return inst
end

local styles = {
    Snow = function(p)
        p.speed = 0.03 + p.depth * 0.09
        p.fade = 0.7 - p.depth * 0.6
        p.inst.Size = udim(2 + p.depth * 6, 2 + p.depth * 6)
    end,
    Rain = function(p, background)
        local size = background.AbsoluteSize
        p.speed = 0.9 + p.depth * 0.9
        p.drift = -p.speed * math.tan(math.rad(12)) * size.Y / math.max(size.X, 1)
        p.sway = 0
        p.fade = 0.8 - p.depth * 0.5
        p.inst.Size = udim(p.depth > 0.6 and 2 or 1, 14 + p.depth * 30)
        p.inst.Rotation = 12
    end,
    Stars = function(p)
        p.pulse = 0.5
    end,
    Confetti = function(p)
        p.speed = 0.08 + p.depth * 0.12
        p.sway = 0.01 + p.depth * 0.02
        p.spin = math.random(-360, 360)
        p.fade = 0.3 - p.depth * 0.25
        p.inst.Size = udim(4 + p.depth * 4, 7 + p.depth * 6)
        p.inst.Rotation = math.random(0, 360)
    end,
    Bubbles = function(p)
        p.speed = -0.03 - p.depth * 0.06
        p.sway = 0.01 + p.depth * 0.02
        p.fade = 0.9
        p.stroke.Transparency = 0.6 - p.depth * 0.4
        p.inst.Size = udim(6 + p.depth * 18, 6 + p.depth * 18)
    end,
    Fireflies = function(p)
        p.y = 0.25 + math.random() * 0.75
        p.speed, p.sway = 0, 0
        p.wander = 0.06 + p.depth * 0.08
        p.pulse = 1
        p.rate = 0.8 + math.random() * 1.6
        p.fade = 0.15
        p.stroke.Thickness = 2 + p.depth * 4
        p.inst.Size = udim(2 + p.depth * 4, 2 + p.depth * 4)
    end,
    Embers = function(p)
        p.speed = -0.05 - p.depth * 0.1
        p.sway = 0.01 + p.depth * 0.02
        p.pulse = 0.6
        p.fade = 0.3 - p.depth * 0.2
        p.inst.Size = udim(2 + p.depth * 4, 2 + p.depth * 4)
    end,
    Sparkles = function(p)
        p.speed, p.sway = 0.005, 0
        p.pulse = 1
        p.fade = 0.1
        p.inst.Size = udim(8 + p.depth * 14, 8 + p.depth * 14)
        p.inst.Rotation = math.random(0, 90)
    end
}

local effects = {}
effects.__index = effects

function effects.new(library, folder)
    local background = create("ScreenGui", {
        Name = "_Background",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Enabled = false,
        DisplayOrder = library.ScreenGui.DisplayOrder - 1,
        Parent = library.ScreenGui.Parent
    })
    local inst = setmetatable({
        library = library,
        folder = folder,
        music = create("Sound", { Name = "_MenuMusic", Looped = true, Parent = soundservice }),
        background = background,
        tint = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = background }),
        glow = create("Frame", { Size = UDim2.fromScale(1, 0.45), Position = UDim2.fromScale(0, 0.55), BorderSizePixel = 0, Parent = background }),
        time = 0,
        songs = {},
        particles = {}
    }, effects)
    pcall(function()
        for i, v in next, listfiles(folder .. "/Music") do
            table.insert(inst.songs, v:match("[^/\\]+$"))
        end
    end)
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.8, 0.35), Parent = inst.tint })
    create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.82), Parent = inst.glow })
    library:AddToRegistry(inst.tint, { BackgroundColor3 = "BackgroundColor" })
    library:AddToRegistry(inst.glow, { BackgroundColor3 = "AccentColor" })
    for i = 1, 150 do
        local depth = math.random()
        local main, second = "AccentColor", "FontColor"
        if i % 3 == 0 then -- wow
            main, second = "FontColor", "AccentColor"
        end
        local particle = create("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2 + math.floor(depth * 3), Parent = background })
        local stroke = create("UIStroke", { Enabled = false, Parent = particle })
        library:AddToRegistry(particle, { ImageColor3 = main, BackgroundColor3 = second })
        library:AddToRegistry(stroke, { Color = second })
        table.insert(inst.particles, {
            inst = particle,
            corner = create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = particle }),
            stroke = stroke,
            gradient = create("UIGradient", { Enabled = false, Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = particle }),
            depth = depth,
            phase = math.random() * 6,
            x = math.random(),
            y = math.random()
        })
    end
    library:UpdateColorsUsingRegistry()
    library:OnUnload(function()
        inst.music:Destroy()
        background:Destroy()
    end)
    return inst
end

function effects:setstyle(style, amount)
    local image = style == "Stars" or style == "Sparkles"
    local icon = self.library:GetIcon(style == "Stars" and "star" or "sparkle") or {}
    self.current = style
    for i, v in next, self.particles do
        v.speed = 0.03 + v.depth * 0.08
        v.drift, v.wander, v.spin, v.pulse = 0, 0, 0, 0
        v.sway = 0.005 + v.depth * 0.015
        v.rate = 2
        v.fade = 0.6 - v.depth * 0.5
        v.stroke.Thickness = 1
        v.inst.Size = udim(10 + v.depth * 12, 10 + v.depth * 12)
        v.inst.Rotation = 0
        if styles[style] then
            styles[style](v, self.background)
        end
        v.property = image and "ImageTransparency" or "BackgroundTransparency"
        v.corner.CornerRadius = style == "Confetti" and UDim.new(0, 1) or UDim.new(1, 0)
        v.stroke.Enabled = style == "Bubbles" or style == "Fireflies"
        v.gradient.Enabled = style == "Rain"
        v.inst.Visible = i <= amount
        v.inst.Image = image and icon.Url or ""
        v.inst.ImageRectOffset = icon.ImageRectOffset or Vector2.zero
        v.inst.ImageRectSize = icon.ImageRectSize or Vector2.zero
        v.inst.ImageTransparency = image and v.fade or 1
        v.inst.BackgroundTransparency = image and 1 or v.fade
    end
end

function effects:step(dt, amount)
    self.time += dt
    for i = 1, amount do
        local v = self.particles[i]
        v.x += v.drift * dt
        v.y += v.speed * dt
        if v.wander ~= 0 then
            v.x += math.noise(v.phase, self.time * 0.3) * v.wander * dt
            v.y += math.noise(v.phase + 10, self.time * 0.3) * v.wander * dt
        end
        v.x %= 1
        if v.y > 1.05 then
            v.x, v.y = math.random(), -0.05
        end
        if v.y < -0.05 then
            v.x, v.y = math.random(), 1.05
        end
        if v.spin ~= 0 then
            v.inst.Rotation += v.spin * dt
        end
        if v.pulse ~= 0 then
            local alpha = v.fade + (1 - v.fade) * v.pulse * (0.5 + math.sin(self.time * v.rate + v.phase) * 0.5)
            v.inst[v.property] = alpha
            v.stroke.Transparency = math.min(alpha + 0.6, 1)
        end
        v.inst.Position = UDim2.fromScale(v.x + math.sin(self.time * 2 + v.phase) * v.sway, v.y)
    end
end

function effects:start()
    local library = self.library
    local toggles, options = library.Toggles, library.Options
    library:GiveSignal(runservice.RenderStepped:Connect(function(dt)
        if not toggles.AlwaysPlayMusic then
            return
        end
        local open = library.Toggled or toggles.AlwaysShowEffects.Value
        local playing = (library.Toggled or toggles.AlwaysPlayMusic.Value) and toggles.MenuMusic.Value
        if playing and options.MusicFile.Value and not self.music.Playing then
            if self.music.SoundId == "" then
                self.music.SoundId = getcustomasset(self.folder .. "/Music/" .. options.MusicFile.Value)
            end
            self.music.Volume = options.MusicVolume.Value
            self.music:Resume()
        end
        if not playing and self.music.Playing then
            self.music:Pause()
        end
        self.background.Enabled = open and options.MenuBackground.Value ~= "None"
        if not self.background.Enabled then
            return
        end
        self.tint.Visible = library.Toggled and toggles.DimBackground.Value
        self.glow.Visible = self.tint.Visible
        if self.current ~= options.MenuBackground.Value then
            self:setstyle(options.MenuBackground.Value, options.EffectAmount.Value)
        end
        self:step(dt * options.EffectSpeed.Value, options.EffectAmount.Value)
    end))
end

return effects
