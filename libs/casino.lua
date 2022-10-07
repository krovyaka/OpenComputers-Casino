local settings = require("settings")
local casino = {}
local component = require("component")
local shell = require("shell")
local filesystem = require("filesystem")
local storage
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


casino.container = nil
local containerSize = 0

if settings.PAYMENT_METHOD == 'CHEST' then
    casino.container = component.chest
    containerSize = casino.container.getInventorySize()
    storage = component.me_interface
elseif settings.PAYMENT_METHOD == 'PIM' then
    casino.container = component.pim
    containerSize = 40
    storage = component.me_interface
elseif settings.PAYMENT_METHOD == 'CRYSTAL' then
    casino.container = component.crystal
    containerSize = casino.container.getInventorySize()
    storage = component.diamond
elseif settings.PAYMENT_METHOD == 'DEV' then
    casino.container = {exportItem = function () return true end, getStackInSlot = function() end}
    containerSize = math.huge
    storage = casino.container
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

if settings.PAYMENT_METHOD == 'CRYSTAL' then
    casino.reward = function(money)
        if not CURRENCY.id then
            return true
        end
    
        money = math.floor(money + 0.5)
        if money > 0 then
            local allItems = component.diamond.getAllStacks()
            for k, v in pairs(allItems) do
                item = v.basic()
                if item and not item.nbt_hash and item.id == CURRENCY.id then
                    money = money - component.diamond.pushItem(settings.CONTAINER_GAIN, k, money)
                end
            end
        end
    end
else
    casino.reward = function(money)
        if not CURRENCY.id or settings.PAYMENT_METHOD == 'DEV' then
            return true
        end
    
        money = math.floor(money + 0.5)
        while money > 0 do
            local executed, g = pcall(function()
                return storage.exportItem(CURRENCY, settings.CONTAINER_GAIN, money < 64 and money or 64).size
            end)
            money = money - (money < 64 and money or 64)
        end
    end
end


casino.takeMoney = function(money)
    if not CURRENCY.id or settings.PAYMENT_METHOD == 'DEV' then
        return true
    end

    if CURRENCY.max and currentBetSize + money > CURRENCY.max then
        return false, "Превышен максимум"
    end

    local sum = 0
    for i = 1, containerSize do
        local item = casino.container.getStackInSlot(i)
        if item and not item.nbt_hash and item.id == CURRENCY.id and item.dmg == CURRENCY.dmg and item.dmg == CURRENCY.dmg then
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
    if count > 0 then
        local allItems = component.diamond.getAllStacks()
        for k, v in pairs(allItems) do
            item = v.basic()
            if item and item.id == id and item.dmg == dmg then
                count = count - component.diamond.pushItem(settings.CONTAINER_GAIN, k, count)
            end
        end
    end
    return (count == 0)
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

if settings.PAYMENT_METHOD == 'CRYSTAL' then
    casino.getCurrencyInStorage = function(currency)
        if not currency.id then
            return -1
        end
        local item = { id = currency.id, dmg = currency.dmg }
        local qty = 0
        local allItems = component.diamond.getAllStacks()
        for k, v in pairs(allItems) do
            item = v.basic()
            if item and not item.nbt_hash and item.id == CURRENCY.id and item.dmg == CURRENCY.dmg then
                qty = qty + item.qty
            end
        end
        return qty or 0
    end
elseif settings.PAYMENT_METHOD == 'DEV' then
    casino.getCurrencyInStorage = function(currency)
        return -1
    end
else 
    casino.getCurrencyInStorage = function(currency)
        if not currency.id then
            return -1
        end 
        local item = {id=currency.id, dmg=currency.dmg}
        local detail = storage.getItemDetail(item)
        return detail and detail.basic().qty or 0
    end
end

return casino