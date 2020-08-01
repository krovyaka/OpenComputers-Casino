local casino = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local chest = component.chest
local meInterface = component.me_interface

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

    money = math.floor(money + 0.5)
    while money > 0 do
        local executed, g = pcall(function()
            return meInterface.exportItem(CURRENCY, "UP", money < 64 and money or 64).size
        end)
        money = money - (money < 64 and money or 64)
    end
end

casino.takeMoney = function(money)
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
        return false, "Недостаточно средств"
    end
    currentBetSize = currentBetSize + money
    return true
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
    local item = {id=currency.id, dmg=currency.dmg}
    local detail = meInterface.getItemDetail(item)
    return detail and detail.basic().qty or 0
end


return casino