local casino = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local chest = component.chest
local meInterface = component.me_interface
local io = require("io")
local serialization = require("serialization")
local CURRENCY = {
    name = nil,
    max = nil,
    image = nil,
    id = nil,
    dmg = nil
}

local currentBetSize = 0

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
    if not CURRENCY.id then
        return true
    end

    money = math.floor(money + 0.5)
    while money > 0 do
        local executed, g = pcall(function()
            return meInterface.exportItem(CURRENCY, "UP", money < 64 and money or 64).size
        end)
        money = money - (money < 64 and money or 64)
    end
end

casino.takeMoney = function(money)
    if not CURRENCY.id then
        return true
    end 

    if CURRENCY.max and currentBetSize + money > CURRENCY.max then
        return false, "Превышен максимум"
    end

    local sum = 0
    for i = 1, chestSize do
        local item = chest.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == CURRENCY.id then
            sum = sum + chest.pushItem('DOWN', i, money - sum)
        end
    end
    if sum < money then
        casino.reward(sum)
        return false, "Нужно " .. CURRENCY.name .. " x" .. money
    end
    currentBetSize = currentBetSize + money
    return true
end

casino.rewardManually = function(player, id, dmg, count)
    local file = io.open('manual_rewards.lua', 'r')
    local items = serialization.unserialize(file:read(999999))
    file:close()
    local playerItems = items[player]
    if (not playerItems) then
        playerItems = {}
    end
    local item = {}
    item.id = id
    item.dmg = dmg
    item.count = count
    table.insert(playerItems, item)
    items[player] = playerItems
    file = io.open('manual_rewards.lua', 'w')
    file:write(serialization.serialize(items))
    file:close()
end

casino.rewardItem = function(id, dmg, count)
    local items = meInterface.getAvailableItems()
    for i=1,#items do
        if (items[i].fingerprint.id == id and items[i].fingerprint.dmg == dmg and items[i].size >= count) then
            item = items[i]
            meInterface.exportItem(items[i].fingerprint,"UP" , count)
            return true
        end
    end
    return false
end

casino.downloadFile = function(url, saveTo, forceRewrite)
    if forceRewrite or not filesystem.exists(saveTo) then
        shell.execute("wget -fq " .. url .. " " .. saveTo)
    end
end

casino.setCurrency = function(currency)
    CURRENCY = currency
end

casino.getCurrency = function()
    return CURRENCY
end

casino.gameIsOver = function()
    currentBetSize = 0
end

casino.getCurrencyInStorage = function(currency)
    if not currency.id then
        return -1
    end 
    local item = {id=currency.id, dmg=currency.dmg}
    local detail = meInterface.getItemDetail(item)
    return detail and detail.basic().qty or 0
end


return casino
