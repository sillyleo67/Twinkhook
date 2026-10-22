local gameyuh = nil
local repyep = game:GetService("ReplicatedStorage")

do -- ik not a very good way too lazy to do placeids
    if repyep:FindFirstChild("Iris") then
        gameyuh = "Jailbreak"
    end

    if repyep:FindFirstChild("GameData") and repyep.GameData:FindFirstChild("Floor") then
        gameyuh = "Doors"
    end
end

if gameyuh ~= nil then
  loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/d445dbd7af63eed8c418de7640f3ea0832b5636ee23f80211ca68a6a6df25294/download"))()
end
  
