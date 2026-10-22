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

if gameyuh == "Jailbreak" then
  loadstring(game:HttpGet("https://raw.githubusercontent.com/sillyleo67/Twinkhook/refs/heads/main/Scripts/Jailbreak.lua"))()
end
  
if gameyuh == "Doors" then
  loadstring(game:HttpGet("https://raw.githubusercontent.com/sillyleo67/Twinkhook/refs/heads/main/Scripts/Doors.lua"))()
end
