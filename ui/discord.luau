local httpservice = game:GetService("HttpService")

local discord = {}

function discord.new(library, invite)
    local code = invite:match("[^/]+$")
    local server = { invite = invite, code = code }
    function server.copy()
        pcall(setclipboard, invite)
        library:Notify({ Title = "Discord", Description = "The invite is on your clipboard.", Icon = "clipboard", Time = 3 })
    end
    function server.join()
        pcall(setclipboard, invite)
        for i = 6463, 6472 do -- https://discord.com/developers/docs/topics/rpc#rpc-server-ports
            local succ, res = pcall(request, {
                Url = string.format("http://127.0.0.1:%d/rpc?v=1", i),
                Method = "POST",
                Headers = {
                    Origin = "https://discord.com",
                    ["Content-Type"] = "application/json"
                },
                Body = httpservice:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    nonce = httpservice:GenerateGUID(false),
                    args = {
                        code = code
                    }
                })
            })
            if succ and res.Success then
                return library:Notify({ Title = "Discord", Description = "Opened the invite in Discord, it's on your clipboard too.", Icon = "message-circle", Time = 5 })
            end
        end
        library:Notify({ Title = "Discord", Description = "Couldn't find Discord open, the invite is on your clipboard.", Icon = "message-circle", Time = 5 })
    end
    function server.members()
        local succ, res = pcall(function()
            return httpservice:JSONDecode(request({ Url = "https://discord.com/api/v10/invites/" .. code .. "?with_counts=true", Method = "GET" }).Body)
        end)
        if succ and res.guild then
            return res.approximate_member_count or 0, res.approximate_presence_count or 0
        end
    end
    return server
end

return discord
