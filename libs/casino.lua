local casino = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local chest = component.chest
local meInterface = component.me_interface

local MONEY_ITEM = { id = "customnpcs:npcMoney" }
local chestSize = chest.getInventorySize()

casino.splitString = function(inputStr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputStr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

casino.reward = function(money)
    money = math.floor(money)
    while money > 0 do
        local executed, g = pcall(function()
            return meInterface.exportItem(MONEY_ITEM, "UP", money < 64 and money or 64).size
        end)
        money = money - (money < 64 and money or 64)
    end
end

casino.takeMoney = function(money)
    local sum = 0
    for i = 1, chestSize do
        local item = chest.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == MONEY_ITEM.id then
            sum = sum + chest.pushItem('DOWN', i, money - sum)
        end
    end
    if sum < money then
        casino.reward(sum)
        return false
    end
    return true
end

casino.downloadFile = function(url, saveTo, forceRewrite)
    if forceRewrite or not filesystem.exists(saveTo) then
        shell.execute("wget -fq " .. url .. " " .. saveTo)
    end
end

return casino