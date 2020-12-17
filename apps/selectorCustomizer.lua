local component = require('component')
local selectorAddresses = { {}, {}, {}, {} }
local io = require('io')
local serialization = require('serialization')
local event = require('event')
selectorAddresses[1][1] = "db900102-d014-4f5d-969b-ed05c9e73a52"
selectorAddresses[2][1] = "8c640ca2-272b-4803-9e93-9a172e9f27de"
selectorAddresses[3][1] = "94a1ed7e-f5dc-43f6-82e4-aff5295472aa"
selectorAddresses[4][1] = "61ce24fe-79d8-4837-b417-1e945a4bc6c1"
selectorAddresses[1][2] = "fdf27232-607c-409b-9b41-1d316b3e0871"
selectorAddresses[2][2] = "8facaf4d-ab08-45b4-b4bc-1d2b506fb0ee"
selectorAddresses[3][2] = "60275c56-9d70-4dfa-b241-78f47238e8a6"
selectorAddresses[4][2] = "839cba86-6947-478a-b246-03b5b04ed786"
selectorAddresses[1][3] = "9838eb41-3c22-4b51-91f8-f3229a6b0c93"
selectorAddresses[2][3] = "f51fbdf4-ce16-4f9c-a71f-bd1bddd6fd32"
selectorAddresses[3][3] = "42a2f18e-1bf9-4204-b9c7-a663750b5186"
selectorAddresses[4][3] = "51e63266-7f0e-4641-8a38-c944a386c561"
selectorAddresses[1][4] = "f5c07e3a-814f-40d9-8ce0-56b21b2f75f2"
selectorAddresses[2][4] = "175ed3a7-f68f-4dca-a9de-2149e9141493"
selectorAddresses[3][4] = "417eae4c-dfb9-4373-9ee8-ccbcc39dccfa"
selectorAddresses[4][4] = "36be8423-8355-463e-8f30-8f875cdaffb3"

local selectors = {}

local function getSelectorByAddress(address)
    for index, selObj in pairs(selectors) do
        if (selObj.selector.address == address) then
            return selObj
        end
    end
end

local function customizeSelectors()
    for k, v in pairs(component.list("openperipheral_selector")) do
        local selectorObj = {}
        selectorObj.selector = component.proxy(k)
        selectorObj.componentAddress = k
        selectorObj.colors = { {}, {}, {}, {} }
        selectorObj.items = {}
        table.insert(selectors, selectorObj)
    end
    local index = 1
    for index, selObj in pairs(selectors) do
        selObj.selector.setSlots({})
        selObj.index = index
        selObj.selector.setSlot(1, { id = "minecraft:wool", dmg = index })
        index = index + 1
    end

    for i = 1, 4 do
        for j = 1, 4 do
            _, slot, address = event.pull("slot_click")
            local selObj = getSelectorByAddress(selectorAddresses[j][i])
            selObj.clickAddress = address
            selObj.x = j
            selObj.y = i
            selObj.selector.setSlots({})
        end
    end

    for index, selObj in pairs(selectors) do
        selObj.selector = nil
    end

    local file = io.open('selectors.cfg','w')
    file:write(serialization.serialize(selectors))
    file:close()
end
customizeSelectors()
