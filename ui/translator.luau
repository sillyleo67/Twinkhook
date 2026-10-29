local runservice = game:GetService("RunService")
local soundservice = game:GetService("SoundService")

local udim = UDim2.fromOffset

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
    local inst = setmetatable({
        library = library,
        folder = folder,
        music = Instance.new("Sound"),
        background = Instance.new("ScreenGui"),
        tint = Instance.new("Frame"),
        glow = Instance.new("Frame"),
        time = 0,
        songs = {},
        particles = {}
    }, effects)
    pcall(function()
        for i, v in next, listfiles(folder .. "/Music") do
            table.insert(inst.songs, v:match("[^/\\]+$"))
        end
    end)
    inst.music.Name = "_MenuMusic"
    inst.music.Looped = true
    inst.music.Parent = soundservice
    inst.background.Name = "_Background"
    inst.background.IgnoreGuiInset = true
    inst.background.ResetOnSpawn = false
    inst.background.Enabled = false
    inst.background.DisplayOrder = library.ScreenGui.DisplayOrder - 1
    inst.background.Parent = library.ScreenGui.Parent
    inst.tint.Size = UDim2.fromScale(1, 1)
    inst.tint.BorderSizePixel = 0
    inst.tint.Parent = inst.background
    inst.glow.Size = UDim2.fromScale(1, 0.45)
    inst.glow.Position = UDim2.fromScale(0, 0.55)
    inst.glow.BorderSizePixel = 0
    inst.glow.Parent = inst.background
    for i, v in next, { { inst.tint, 0.8, 0.35 }, { inst.glow, 1, 0.82 } } do
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 90
        gradient.Transparency = NumberSequence.new(v[2], v[3])
        gradient.Parent = v[1]
    end
    library:AddToRegistry(inst.tint, { BackgroundColor3 = "BackgroundColor" })
    library:AddToRegistry(inst.glow, { BackgroundColor3 = "AccentColor" })
    for i = 1, 150 do
        local depth = math.random()
        local main, second = "AccentColor", "FontColor"
        if i % 3 == 0 then -- wow
            main, second = "FontColor", "AccentColor"
        end
        local particle = Instance.new("ImageLabel")
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.BorderSizePixel = 0
        particle.ZIndex = 2 + math.floor(depth * 3)
        particle.Parent = inst.background
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        local stroke = Instance.new("UIStroke")
        stroke.Enabled = false
        stroke.Parent = particle
        local gradient = Instance.new("UIGradient")
        gradient.Enabled = false
        gradient.Rotation = 90
        gradient.Transparency = NumberSequence.new(1, 0)
        gradient.Parent = particle
        library:AddToRegistry(particle, { ImageColor3 = main, BackgroundColor3 = second })
        library:AddToRegistry(stroke, { Color = second })
        table.insert(inst.particles, { inst = particle, corner = corner, stroke = stroke, gradient = gradient, depth = depth, phase = math.random() * 6, x = math.random(), y = math.random() })
    end
    library:UpdateColorsUsingRegistry()
    library:OnUnload(function()
        inst.music:Destroy()
        inst.background:Destroy()
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
            local fade = v.fade + (1 - v.fade) * v.pulse * (0.5 + math.sin(self.time * v.rate + v.phase) * 0.5)
            v.inst[v.property] = fade
            v.stroke.Transparency = math.min(fade + 0.6, 1)
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
