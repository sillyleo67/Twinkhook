local tweenservice = game:GetService("TweenService")

local twinkhook = getgenv().twinkhook
local library = twinkhook.library
local toggles, options = library.Toggles, library.Options
local drawing = twinkhook.modules.drawing.new()

local abs = math.abs
local clamp = math.clamp
local cos = math.cos
local sin = math.sin
local pi = math.pi

local inf = math.huge

local white, black = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local corners = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }

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

local function tween(instance, duration, properties)
    local t = tweenservice:Create(instance, TweenInfo.new(duration), properties)
    t:Play()
    return t
end

local esp = {
    objects = {},
    players = {},
    labels = {},
    lowpriority = {},
    gui = create("ScreenGui", { Name = "_Esp", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10 }),
    visible = false,
    disabled = false
}

local function newtext(parent, order, content)
    local text = create("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Size = UDim2.fromScale(1, 0),
        Text = content,
        TextTransparency = 1,
        Parent = parent
    })
    create("UIStroke", { LineJoinMode = Enum.LineJoinMode.Round, Thickness = 1.5, Transparency = 1, Parent = text })
    return text
end

local function newlabel(parent, rich)
    return create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        RichText = rich,
        Size = UDim2.fromOffset(100, 20),
        TextColor3 = white,
        TextStrokeColor3 = black,
        ZIndex = 3,
        Parent = parent
    })
end

local function newframe(parent, colour, zindex)
    return create("Frame", { BackgroundColor3 = colour, BorderSizePixel = 0, ZIndex = zindex, Parent = parent })
end

local function getpart(obj, category, childname)
    local part = childname and obj:FindFirstChild(childname) or obj
    if part:IsA("Model") then
        local head = category == "Entities" and part:FindFirstChild("Head", true)
        if head and head:IsA("BasePart") then
            return head
        end
        part = part:FindFirstChild("HumanoidRootPart") or part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart", true)
    end
    if part and part:IsA("BasePart") then
        return part
    end
end

local function getbounds(model) -- very good trust
    local minx, miny, minz = inf, inf, inf
    local maxx, maxy, maxz = -inf, -inf, -inf
    for i, v in next, model:GetChildren() do
        if v:IsA("BasePart") and v.Transparency < 1 then
            local size = v.Size
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v.CFrame:GetComponents()
            local wx = (abs(r00) * size.X + abs(r01) * size.Y + abs(r02) * size.Z) / 2
            local wy = (abs(r10) * size.X + abs(r11) * size.Y + abs(r12) * size.Z) / 2
            local wz = (abs(r20) * size.X + abs(r21) * size.Y + abs(r22) * size.Z) / 2
            minx, miny, minz = math.min(minx, x - wx), math.min(miny, y - wy), math.min(minz, z - wz)
            maxx, maxy, maxz = math.max(maxx, x + wx), math.max(maxy, y + wy), math.max(maxz, z + wz)
        end
    end
    local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
    return (omax + omin) / 2, omax - omin
end

local function worldtoviewport(pos)
    local spos, vis = workspace.CurrentCamera:WorldToViewportPoint(pos)
    return Vector2.new(spos.X, spos.Y), vis
end

local function removevisuals(inst)
    if inst.billboard then
        inst.billboard:Destroy()
        inst.center:Destroy()
    end
    if inst.tracer then
        drawing:remove(inst.tracer)
    end
    inst.billboard, inst.center, inst.title, inst.dist = nil, nil, nil, nil
    inst.shape, inst.tracer, inst.colour = nil, nil, nil
    inst.shown, inst.highlighted = nil, nil
end

local function newbillboard(inst, floorname)
    local obj, part = inst.object, inst.part
    local kind = options.HighlightType.Value
    local offset = Vector3.zero
    if inst.category ~= "Entities" and not inst.childname and obj:IsA("Model") then
        offset = part.CFrame:PointToObjectSpace(obj:GetBoundingBox().Position)
    end
    if offset.Magnitude >= 25 then
        offset = Vector3.zero
    end
    if inst.category == "Doors" and obj:IsA("BasePart") and floorname ~= "Outdoor" then
        kind = "Box"
    end
    if inst.category == "NodePaths" or inst.category == "Doors" and obj:IsA("BasePart") and floorname == "Stairwell" and obj.Transparency == 1 then
        kind = "Billboard"
    end
    local center = create("Attachment", { Name = "_Center", Position = offset })
    local billboard = create("BillboardGui", {
        Name = "_Billboard",
        Adornee = center,
        AlwaysOnTop = true,
        Enabled = false,
        LightInfluence = 0,
        MaxDistance = options.RenderDistance.Value,
        Size = UDim2.fromOffset(240, 60)
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = billboard
    })
    local shape
    if kind == "Selection Box" then
        shape = create("SelectionBox", { Adornee = obj, LineThickness = 0.05, SurfaceTransparency = 1, Transparency = 1 })
    end
    if kind == "Box" or kind == "Sphere" or kind == "Cylinder" then
        shape = create(kind .. "HandleAdornment", { Adornee = part, AlwaysOnTop = true, Transparency = 1, ZIndex = 5 })
    end
    if kind == "Box" then
        shape.Size = part.Size
        if obj:IsA("Model") and not inst.childname then
            local box, size = obj:GetBoundingBox()
            shape.CFrame = part.CFrame:ToObjectSpace(box)
            shape.Size = size
        end
    end
    if kind == "Sphere" then
        shape.Radius = part.Size.Magnitude / 2
    end
    if kind == "Cylinder" then
        shape.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        shape.Height = part.Size.Y
        shape.Radius = math.max(part.Size.X, part.Size.Z) / 2
    end
    if shape then
        shape.Parent = billboard
    end
    inst.center, inst.billboard, inst.shape = center, billboard, shape
    inst.title = newtext(billboard, 1, inst.text)
    inst.dist = newtext(billboard, 2, "")
    inst.kind = kind
    inst.fixed = kind ~= options.HighlightType.Value
    inst.colour = nil
    center.Parent = part
    billboard.Parent = esp.gui
end

local function fade(inst, shown, highlighted)
    local fadetime = options.FadeTime.Value
    local billboard = inst.billboard
    local fill, outline = 1, 1
    local text, stroke = 1, 1
    if highlighted then
        fill, outline = options.FillTransparency.Value, options.OutlineTransparency.Value
    end
    if shown then
        text, stroke = options.BillboardTransparency.Value, options.BillboardOutlineTransparency.Value
    end
    inst.shown, inst.highlighted = shown, highlighted
    if shown or highlighted then
        billboard.Enabled = true
    end
    if inst.kind == "Highlight" and highlighted then
        if not inst.shape then
            local piston = inst.object:FindFirstChild("Piston", true)
            inst.shape = create("Highlight", { Adornee = inst.object, FillTransparency = 1, OutlineTransparency = 1, Parent = billboard })
            if piston then
                create("Highlight", { Adornee = piston, FillTransparency = 1, OutlineTransparency = 1, Parent = inst.shape })
            end
        end
        inst.shape.Enabled = true
    end
    for i, v in next, { inst.title, inst.dist } do
        tween(v, fadetime, { TextTransparency = text })
        tween(v.UIStroke, fadetime, { Transparency = stroke })
    end
    if inst.shape then
        local goal = { Transparency = fill }
        if inst.kind == "Highlight" then
            goal = { FillTransparency = fill, OutlineTransparency = outline }
        end
        if inst.kind == "Selection Box" then
            goal = { SurfaceTransparency = fill, Transparency = outline }
        end
        tween(inst.shape, fadetime, goal)
    end
    task.delay(fadetime, function()
        if inst.billboard == billboard then
            if not inst.shown and not inst.highlighted then
                billboard.Enabled = false
            end
            if inst.kind == "Highlight" and inst.shape and not inst.highlighted then
                inst.shape.Enabled = false
            end
        end
    end)
end

local function restyle(inst, font, colour, textcolour)
    local outline = options.BillboardOutlineColour.Value
    local height = options.BillboardHeight.Value
    local size = options.BillboardSize.Value
    if inst.colour == colour and inst.textcolour == textcolour and inst.outline == outline and inst.height == height and inst.font == font and inst.size == size and inst.painted == inst.shape then
        return
    end
    inst.colour, inst.textcolour, inst.outline = colour, textcolour, outline
    inst.height, inst.font, inst.size = height, font, size
    inst.painted = inst.shape
    inst.billboard.MaxDistance = options.RenderDistance.Value
    inst.billboard.StudsOffset = Vector3.new(0, height, 0)
    for i, v in next, { inst.title, inst.dist } do
        v.Font = font
        v.TextSize = size - (i - 1)
        v.TextColor3 = textcolour
        v.UIStroke.Color = outline
    end
    if inst.shape then
        if inst.kind == "Highlight" then
            inst.shape.FillColor = colour
            inst.shape.OutlineColor = colour
        else
            inst.shape.Color3 = colour
            if inst.kind == "Selection Box" then
                inst.shape.SurfaceColor3 = colour
            end
        end
    end
end

local function newplayer(plr)
    local folder = create("Folder", { Name = plr.Name, Parent = esp.gui })
    local inst = {
        folder = folder,
        box = newframe(folder, white, 1),
        behind = newframe(folder, black, 1),
        bar = newframe(folder, white, 2),
        labels = {},
        lines = {},
        outlines = {}
    }
    inst.boxgradient = create("UIGradient", { Parent = inst.box })
    inst.bargradient = create("UIGradient", { Rotation = -90, Parent = inst.bar })
    inst.highlight = create("Highlight", { Parent = folder })
    for i, v in next, { "name", "dist", "weapon", "bounty", "healthtext" } do
        inst[v] = newlabel(folder, true)
        table.insert(inst.labels, inst[v])
    end
    for i, v in next, corners do
        inst.lines[i] = { newframe(folder, white, 3), newframe(folder, white, 3) }
        inst.outlines[i] = { newframe(folder, black, 2), newframe(folder, black, 2) }
        for i2 = 1, 2 do
            inst.lines[i][i2].AnchorPoint = v
            inst.outlines[i][i2].AnchorPoint = v
        end
    end
    esp.players[plr] = inst
    return inst
end

function esp:add(obj, room, category, text, childname, filter)
    if self.disabled or self.objects[obj] or not obj.Parent then
        return
    end
    local parent = obj.Parent
    while parent and parent ~= workspace do
        local inst = self.objects[parent]
        if inst and inst.category == category then
            return
        end
        parent = parent.Parent
    end
    for i, v in next, self.objects do
        if v.category == category and i:IsDescendantOf(obj) then
            return
        end
    end
    local part = getpart(obj, category, childname)
    if not part then
        obj.DescendantAdded:Once(function()
            self:add(obj, room, category, text, childname, filter)
        end)
        return
    end
    local inst = { object = obj, part = part, room = room, category = category, text = text, childname = childname, filter = filter }
    self.objects[obj] = inst
    return inst
end

function esp:remove(obj)
    local inst = self.objects[obj]
    if inst then
        self.objects[obj] = nil
        removevisuals(inst)
    end
end

function esp:settext(obj, text)
    local inst = self.objects[obj]
    if inst then
        inst.text = text
    end
end

function esp:refresh()
    for i, v in next, self.objects do
        v.shown = nil
    end
end

function esp:update(room, floorname, dead)
    local cam = workspace.CurrentCamera
    local campos = cam.CFrame.Position
    local font = Enum.Font[options.BillboardFont.Value]
    local sorted = {}
    local currentdoor, visible = false, false
    local highlights = 0
    for i, v in next, self.objects do
        if not i:IsDescendantOf(workspace) or self.ignore and i:IsDescendantOf(self.ignore) then
            self:remove(i)
            continue
        end
        if not v.part or v.part ~= i and not v.part:IsDescendantOf(i) then
            removevisuals(v)
            v.part = getpart(i, v.category, v.childname)
        end
        if v.part then
            v.range = (campos - v.part.Position).Magnitude
            v.priority = not table.find(self.lowpriority, v.category)
            v.onscreen = select(2, cam:WorldToViewportPoint(v.part.Position))
            table.insert(sorted, v)
            if v.category == "Doors" and v.room == room and i.Name == "Door" then
                currentdoor = true
            end
        end
    end
    table.sort(sorted, function(a, b)
        if a.priority ~= b.priority then
            return a.priority
        end
        if a.onscreen ~= b.onscreen then
            return a.onscreen
        end
        return a.range < b.range
    end)
    for i, v in next, sorted do
        local category = v.category
        local colour = options[category .. "Colour"].Value
        local shown = toggles.EnableESP.Value and toggles[category].Value and v.range <= options.RenderDistance.Value or false
        local highlighted = false
        if shown and v.filter and not options[v.filter].Value[v.text] then
            shown = false
        end
        if shown and v.room and not dead and v.room ~= room and not (category == "Doors" and v.room == room + 1 and not currentdoor) then
            shown = false
        end
        if toggles.RainbowESP.Value then
            colour = Color3.fromHSV(workspace.DistributedGameTime % 5 / 5, 0.8, 1)
        end
        local textcolour = toggles.CustomBillboardColour.Value and options.BillboardColour.Value or colour
        local highlightcolour = toggles.CustomHighlightColour.Value and options.HighlightColour.Value or colour
        local tracercolour = toggles.CustomTracerColour.Value and options.TracerColour.Value or colour
        if v.billboard and not v.fixed and v.kind ~= options.HighlightType.Value then
            removevisuals(v)
        end
        if shown and not v.billboard then
            newbillboard(v, floorname)
        end
        if shown and toggles.ShowHighlights.Value then
            highlighted = v.kind ~= "Highlight" or highlights < 31 -- around 6 or 7
        end
        if highlighted and v.kind == "Highlight" then
            highlights += 1
        end
        if v.billboard and (shown ~= v.shown or highlighted ~= v.highlighted) then
            fade(v, shown, highlighted)
        end
        if shown and toggles.ShowTracers.Value and not v.tracer then
            v.tracer = drawing:add("Line", {})
        end
        if v.tracer and not (shown and toggles.ShowTracers.Value) then
            drawing:remove(v.tracer)
            v.tracer = nil
        end
        if v.shown or v.highlighted then
            visible = true
        end
        if shown and v.billboard then
            if self.detail then
                v.detail = self.detail(v)
            end
            v.title.Text = v.detail and v.text .. " (" .. v.detail .. ")" or v.text
            v.title.Visible = toggles.ShowBillboards.Value and toggles.ShowNames.Value
            v.dist.Text = "[ " .. math.floor(v.range) .. "m ]"
            v.dist.Visible = toggles.ShowBillboards.Value and toggles.ShowDistances.Value
            if v.tracer then
                v.tracer.Color = tracercolour
                v.tracer.Thickness = options.TracerThickness.Value
            end
            restyle(v, font, highlightcolour, textcolour)
        end
    end
    self.visible = visible
end

function esp:drawtracers(origin)
    for i, v in next, self.objects do
        if v.tracer and v.part then
            local spos, vis = worldtoviewport(v.part.Position)
            v.tracer.Visible = vis
            v.tracer.From = origin
            v.tracer.To = spos
        end
    end
end

function esp:drawplayer(plr, plrdata)
    local inst = self.players[plr] or newplayer(plr)
    local cam = workspace.CurrentCamera
    local pos, size = getbounds(plrdata.character)
    if size.X < 0 then
        pos, size = plrdata.root.Position, plrdata.root.Size
    end
    local cf = CFrame.new(pos, cam.CFrame.Position)
    local radius = size * 0.5
    local spos, vis = worldtoviewport(pos)
    local minx, miny, maxx, maxy = inf, inf, 0, 0
    local vertexes = {
        (cf * CFrame.new(radius.X, radius.Y, 0)).Position,
        (cf * CFrame.new(radius.X, -radius.Y, 0)).Position,
        (cf * CFrame.new(-radius.X, radius.Y, 0)).Position,
        (cf * CFrame.new(-radius.X, -radius.Y, 0)).Position
    }
    for i, v in next, vertexes do
        local vpos = worldtoviewport(v)
        minx, maxx = math.min(minx, vpos.X), math.max(maxx, vpos.X)
        miny, maxy = math.min(miny, vpos.Y), math.max(maxy, vpos.Y)
    end
    local width, height = maxx - minx, maxy - miny
    local health = clamp(plrdata.hum.Health / math.max(plrdata.hum.MaxHealth, 1), 0, 1)
    local healthy = miny + height * (1 - health)
    local font = Enum.Font[options.ESPFont.Value]
    local boxlength = options.BoxStyle.Value == "Full" and 0.5 or 0.2
    local alpha, accent = plrdata.alpha, plrdata.accent
    local rotation = -45
    local filltransparency, outlinetransparency = options.FillTransparency.Value, options.OutlineTransparency.Value
    local sizes = { Vector2.new(width * boxlength + 1, 1), Vector2.new(1, height * boxlength + 1) }
    if toggles.AnimateBoxes.Value then
        rotation = -45 - 1200 / pi * cos(pi / 4 * os.clock())
    end
    if toggles.ThermalHighlights.Value then
        local breathe = math.atan(sin(os.clock() * 2)) * 2 / pi
        filltransparency = clamp(filltransparency + breathe * 0.3, 0, 1)
        outlinetransparency = clamp(outlinetransparency + breathe * 0.3, 0, 1)
    end
    inst.box.Visible = vis and toggles.ShowBoxes.Value and toggles.FillBoxes.Value
    inst.box.Position = UDim2.fromOffset(minx, miny)
    inst.box.Size = UDim2.fromOffset(width, height)
    inst.box.BackgroundTransparency = 1 - 0.25 * alpha
    inst.boxgradient.Color = ColorSequence.new(accent, black)
    inst.boxgradient.Rotation = rotation
    for i, v in next, corners do
        local x, y = minx + width * v.X, miny + height * v.Y
        local offset = v * 2 - Vector2.one
        for i2, v2 in next, sizes do
            local line, outline = inst.lines[i][i2], inst.outlines[i][i2]
            line.Visible = vis and toggles.ShowBoxes.Value
            line.Position = UDim2.fromOffset(x, y)
            line.Size = UDim2.fromOffset(v2.X, v2.Y)
            line.BackgroundColor3 = options.BoxColour.Value
            line.BackgroundTransparency = 1 - alpha
            outline.Visible = line.Visible and toggles.OutlineBoxes.Value
            outline.Position = UDim2.fromOffset(x + offset.X, y + offset.Y)
            outline.Size = UDim2.fromOffset(v2.X + 2, v2.Y + 2)
            outline.BackgroundTransparency = 1 - alpha
        end
    end
    inst.bar.Visible = vis and toggles.ShowHealthBars.Value
    inst.bar.Position = UDim2.fromOffset(minx - 6, healthy)
    inst.bar.Size = UDim2.fromOffset(2.5, height * health)
    inst.bar.BackgroundTransparency = 1 - alpha
    inst.bargradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 125)),
        ColorSequenceKeypoint.new(1, accent)
    })
    inst.behind.Visible = inst.bar.Visible
    inst.behind.Position = UDim2.fromOffset(minx - 7, miny - 1)
    inst.behind.Size = UDim2.fromOffset(4.5, height + 2)
    inst.behind.BackgroundTransparency = 1 - alpha
    inst.healthtext.Visible = inst.bar.Visible and toggles.ShowHealthText.Value and health < 1
    inst.healthtext.Position = UDim2.fromOffset(minx - 6, healthy + 3)
    inst.healthtext.Text = tostring(math.floor(health * 100))
    inst.healthtext.TextColor3 = accent
    inst.name.Visible = vis and toggles.ShowNames.Value
    inst.name.Position = UDim2.fromOffset(spos.X, miny - 9)
    inst.name.Text = plrdata.name
    inst.dist.Visible = vis and toggles.ShowDistances.Value and options.DistancePosition.Value == "Bottom"
    inst.dist.Position = UDim2.fromOffset(spos.X, maxy + 7)
    inst.dist.Text = plrdata.meters .. " meters"
    local below = maxy + (inst.dist.Visible and 18 or 8)
    inst.weapon.Visible = vis and toggles.ShowWeapons.Value
    inst.weapon.Position = UDim2.fromOffset(spos.X, below)
    inst.weapon.Text = plrdata.weapon
    inst.bounty.Visible = vis and toggles.ShowBounties.Value and plrdata.bounty > 0
    inst.bounty.Position = UDim2.fromOffset(spos.X, below + (inst.weapon.Visible and 11 or 0))
    inst.bounty.Text = "$" .. plrdata.bounty .. " bounty"
    for i, v in next, inst.labels do
        v.Font = font
        v.TextSize = options.TextSize.Value
        v.TextTransparency = 1 - alpha
        v.TextStrokeTransparency = toggles.TextOutline.Value and 1 - alpha or 1
    end
    inst.highlight.Enabled = toggles.ShowHighlights.Value
    inst.highlight.Adornee = plrdata.character
    inst.highlight.DepthMode = toggles.VisibleCheck.Value and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    inst.highlight.FillColor = accent
    inst.highlight.OutlineColor = accent
    inst.highlight.FillTransparency = 1 - (1 - filltransparency) * alpha
    inst.highlight.OutlineTransparency = 1 - (1 - outlinetransparency) * alpha
end

function esp:removeplayer(plr)
    local inst = self.players[plr]
    if inst then
        self.players[plr] = nil
        inst.folder:Destroy()
    end
end

function esp:drawlabels(objects)
    local campos = workspace.CurrentCamera.CFrame.Position
    local font = Enum.Font[options.ESPFont.Value]
    for i, v in next, self.labels do
        if not objects[i] or not i:IsDescendantOf(workspace) then
            self.labels[i] = nil
            v:Destroy()
        end
    end
    for i, v in next, objects do
        local pos = (i:FindFirstChild("HumanoidRootPart") or i):GetPivot().Position
        local spos, vis = worldtoviewport(pos)
        local label = self.labels[i] or newlabel(self.gui, false)
        self.labels[i] = label
        label.Visible = vis
        label.Position = UDim2.fromOffset(spos.X, spos.Y)
        label.Text = v.text .. " [" .. math.floor((pos - campos).Magnitude / 3.5714285714) .. "]"
        label.TextColor3 = v.colour
        label.Font = font
        label.TextSize = options.TextSize.Value
        label.TextStrokeTransparency = toggles.TextOutline.Value and 0 or 1
    end
end

function esp:clear(fadetime)
    self.disabled = true
    for i in next, self.objects do
        self:remove(i)
    end
    for i in next, self.players do
        self:removeplayer(i)
    end
    drawing:clear()
    task.delay(fadetime or 0, self.gui.Destroy, self.gui)
end

return esp
