local casino = {}
local component = require("component")
local unicode = require("unicode")
local shell = require("shell")
local filesystem = require("filesystem")
local gpu = component.gpu
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

casino.writeCenter = function(x, y, text, color)
    gpu.setForeground(color)
    x = x - unicode.len(text) / 2
    gpu.set(x, y, text)
end

casino.drawRectangle = function(x, y, width, height, color)
    gpu.setBackground(color)
    gpu.fill(x, y, width, height, " ")
end

casino.drawRectangleWithCenterText = function(x, y, width, height, text, bgcolor, fgcolor)
    casino.drawRectangle(x, y, width, height, bgcolor)
    casino.writeCenter(width / 2 + x, height / 2 + y, text, fgcolor)
end

casino.drawBigText = function(x, y, text)
    if not text then
        return
    end
    local lines = casino.splitString(text, "\n")
    for i = 0, #lines - 1 do
        gpu.set(x, y + i, lines[i + 1])
    end
end

casino.reward = function(money)
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

casino.setResolution = function(width, height)
    gpu.setResolution(width, height)
end

casino.downloadFile = function(url, saveTo, forceRewrite)
    if forceRewrite or not filesystem.exists(saveTo) then
        shell.execute("wget -fq " .. url .. " " .. saveTo)
    end
end

casino.setBackground = function(background)
    gpu.setBackground(background)
end

return casino