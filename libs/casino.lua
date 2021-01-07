local casino = {}

local settings = require("settings")
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local durexdb = require("durexdb")
local meInterface = component.me_interface

local CURRENCY = {
    name = nil,
    max = nil,
    image = nil,
    id = nil,
    dmg = nil
}

local db = DurexDatabase:new()
local currentBetSize = 0

casino.container = nil
local containerSize = 0

if settings.PAYMENT_METHOD == 'CHEST' then
    casino.container = component.chest
    containerSize = casino.container.getInventorySize()
elseif settings.PAYMENT_METHOD == 'PIM' then
    casino.container = component.pim
    containerSize = 40
end

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
            return meInterface.exportItem(CURRENCY, settings.CONTAINER_GAIN, money < 64 and money or 64).size
        end)
        money = money - (money < 64 and money or 64)
    end
    db:executeQuery("INSERT INTO MissedRewards " )
end

casino.takeMoney = function(money)
    if not CURRENCY.id then
        return true
    end 

    if CURRENCY.max and currentBetSize + money > CURRENCY.max then
        return false, "Превышен максимум"
    end

    local sum = 0
    for i = 1, containerSize do
        local item = casino.container.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == CURRENCY.id then
            sum = sum + casino.container.pushItem(settings.CONTAINER_PAY, i, money - sum)
        end
    end
    if sum < money then
        casino.reward(sum)
        return false, "Нужно " .. CURRENCY.name .. " x" .. money
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
    if not currency.id then
        return -1
    end 
    local item = {id=currency.id, dmg=currency.dmg}
    local detail = meInterface.getItemDetail(item)
    return detail and detail.basic().qty or 0
end


return casino