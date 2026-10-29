local utils = {}
utils.__index = utils

function utils.new()
    return setmetatable({}, utils)
end

function utils:formatmoney(amount) -- code too sexy ik
    local a, b, c = tostring(amount):match("^([^%d]*%d)(%d*)(.-)$")
    return string.format("$%s%s%s", a, b:reverse():gsub("(%d%d%d)", "%1,"):reverse(), c)
end

function utils:splitcamel(text)
    return (tostring(text):gsub("(%l)(%u)", "%1 %2"))
end

return utils
