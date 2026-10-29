local httpservice = game:GetService("HttpService")

-- lazy way
local listurl ="https://clients5.google.com/translate_a/l?client=dict-chrome-ex&hl=en"
local translateurl = "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=en&tl=%s&q=%s"

local translator = {}
translator.__index = translator

function translator.new(folder)
    local inst = setmetatable({
        folder = folder,
        language = "English",
        loaded = "English",
        languages = { English = "en" },
        list = {},
        english = {},
        cache = {},
        queue = {},
        done = false,
        failed = false
    }, translator)
    local succ, res = pcall(function()
        return httpservice:JSONDecode(game:HttpGet(listurl))
    end)
    if succ then
        for i, v in next, res.tl do
            inst.languages[v] = i
        end
    end
    for i in next, inst.languages do
        table.insert(inst.list, i)
    end
    table.sort(inst.list)
    local saved = select(2, pcall(readfile, folder .. "/Settings/Language.txt"))
    if inst.languages[saved] then
        inst.language = saved
    end
    return inst
end

function translator:translate(obj)
    local text = self.english[obj]
    if self.cache[text] or self.loaded == "English" then
        obj.Text = self.cache[text] or text
        return
    end
    if text:find("%a") and not text:find("[%d<\n]") and #text < 200 then
        self.queue[text] = true
        self.done = false
    end
end

function translator:watch(obj)
    if self.english[obj] or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
        return
    end
    self.english[obj] = obj.Text
    self:translate(obj)
    obj:GetPropertyChangedSignal("Text"):Connect(function()
        if obj.Text ~= self.cache[self.english[obj]] then
            self.english[obj] = obj.Text
            self:translate(obj)
        end
    end)
    obj.Destroying:Once(function()
        self.english[obj] = nil
    end)
end

function translator:fetch()
    local file = string.format("%s/Languages/%s.json", self.folder, self.language)
    if self.loaded ~= self.language then
        local succ, res = pcall(function()
            return httpservice:JSONDecode(readfile(file))
        end)
        self.loaded = self.language
        self.cache = succ and res or {}
        self.failed = false
        table.clear(self.queue)
        for i in next, self.english do
            self:translate(i)
        end
    end
    self.done = next(self.queue) == nil
    if self.done or self.failed then
        return
    end
    local batch, size = {}, 0
    for i in next, self.queue do
        if size + #i > 1500 then
            break
        end
        table.insert(batch, i)
        size += #i + 1
    end
    local succ, res = pcall(function()
        local body = game:HttpGet(string.format(translateurl, self.languages[self.loaded], httpservice:UrlEncode(table.concat(batch, "\n"))))
        return httpservice:JSONDecode(body)[1]:split("\n")
    end)
    if not succ then
        self.failed = true
        return
    end
    if self.loaded ~= self.language then
        return
    end
    for i, v in next, batch do
        self.queue[v] = nil
        self.cache[v] = #res == #batch and res[i]:match("^%s*(.-)%s*$") or v
    end
    for i, v in next, self.english do
        if table.find(batch, v) then
            self:translate(i)
        end
    end
    pcall(writefile, file, httpservice:JSONEncode(self.cache))
end

function translator:start(library)
    for i, v in next, library.ScreenGui:GetDescendants() do
        self:watch(v)
    end
    library:GiveSignal(library.ScreenGui.DescendantAdded:Connect(function(obj)
        self:watch(obj)
    end))
    task.spawn(function()
        while not library.Unloaded and task.wait(0.2) do
            self:fetch()
        end
    end)
end

return translator
