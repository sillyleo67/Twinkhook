local drawing = {}
drawing.__index = drawing

function drawing.new()
    return setmetatable({
        cache = {}
    }, drawing)
end

function drawing:add(drawtype, props)
    local item = Drawing.new(drawtype)
    for i, v in next, props do
        item[i] = v
    end
    table.insert(self.cache, item)
    return item
end

function drawing:remove(item)
    local idx = table.find(self.cache, item)
    if idx then
        table.remove(self.cache, idx)
    end
    pcall(item.Remove, item)
end

function drawing:clear()
    for i, v in next, self.cache do
        pcall(v.Remove, v)
    end
    table.clear(self.cache)
end

return drawing
