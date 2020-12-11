local component = require('component')
local selectorAddresses = { {}, {}, {}, {} }
local io = require('io')
local serialization = require('serialization')
local event = require('event')
selectorAddresses[1][1] = "f797e15d-3e07-4265-a67d-92e3b976e216"
selectorAddresses[2][1] = "d43d869e-10d4-43e2-8736-3679c3b26a7d"
selectorAddresses[3][1] = "23166c15-e4b6-4e99-aefa-8ce6baea75f3"
selectorAddresses[4][1] = "07b7e201-78fa-4750-a25e-cc7b2594640c"
selectorAddresses[1][2] = "a677a057-7edc-424b-b919-45282c224f64"
selectorAddresses[2][2] = "f4f79d0e-a18c-4590-a869-30cfa99e62e6"
selectorAddresses[3][2] = "da777c05-3da2-4cad-b3f8-920cc72ee183"
selectorAddresses[4][2] = "cb2f5444-9535-4ba2-b7f9-4933fd210b3d"
selectorAddresses[1][3] = "41a407ac-ebad-43bf-ad38-0fc72c2c0792"
selectorAddresses[2][3] = "e81c6065-71e1-426e-9cf9-151d1c21d257"
selectorAddresses[3][3] = "12e775d6-5678-43b6-9d09-cc3654128f14"
selectorAddresses[4][3] = "e11ee295-4f7d-478b-a98a-507c558a80c6"
selectorAddresses[1][4] = "855048ce-1d70-4566-b563-726d4ffb51e7"
selectorAddresses[2][4] = "8f852604-1f28-4491-b89a-6c5d0c7ef916"
selectorAddresses[3][4] = "133d58f2-e200-440c-8a76-cf70463316e7"
selectorAddresses[4][4] = "7c80e30a-09dd-443e-a955-b9193276a89b"

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
