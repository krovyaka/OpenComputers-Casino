local currencies = {}

local function addCurrency(name, id, dmg, model, color, max)
    table.insert(currencies, {
        name = name,
        id = id,
        dmg = dmg,
        model = model,
        color = color,
    })
end

addCurrency("Деньги",           "customnpcs:npcMoney",      0,   'INGOT', 0x85BB65, nil)
addCurrency("Светопыль",        "minecraft:glowstone_dust", 0,   'DUST',  0xD0D000, 5)
addCurrency("Железный слиток",  "minecraft:iron_ingot",     0,   'INGOT', 0xAAAAAA, nil)
addCurrency("Железный блок",    "minecraft:iron_block",     0,   'BLOCK', 0xAAAAAA, 6)
addCurrency("Медный слиток",    "IC2:itemIngot",            0,   'INGOT', 0xA5642F, nil)
addCurrency("Медный блок",      "Forestry:resourceStorage", 1,   'BLOCK', 0xA5642F, 6)
addCurrency("Оловянный слиток", "IC2:itemIngot",            1,   'INGOT', 0xCCCCCC, nil)
addCurrency("Оловянный блок",   "Forestry:resourceStorage", 2,   'BLOCK', 0xCCCCCC, 6)
addCurrency("Бесплатно",        nil,                        nil, nil,     0xE5E5E5, nil)

return currencies
