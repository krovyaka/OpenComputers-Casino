local currencies = {}

table.insert(currencies, {
    name = "Деньги",
    color = 0x85BB65,
    id = "customnpcs:npcMoney",
    dmg = 0
})

table.insert(currencies, {
    name = "Светопыль",
    color = 0xD0D000,
    id = "minecraft:glowstone_dust",
    dmg = 0,
    max = 50
})

table.insert(currencies, {
    name = "Железный слиток",
    color = 0xD5D5D5,
    id = "minecraft:iron_ingot",
    dmg = 0,
})

table.insert(currencies, {
    name = "Железный блок",
    color = 0xD5D5D5,
    id = "minecraft:iron_block",
    dmg = 0,
    max = 64
})

table.insert(currencies, {
    name = "Медный слиток",
    color = 0xA5642F,
    id = "IC2:itemIngot",
    dmg = 0
})
table.insert(currencies, {
    name = "Медный блок",
    color = 0xA5642F,
    id = "Forestry:resourceStorage",
    dmg = 1,
    max = 64
})

table.insert(currencies, {
    name = "Оловянный слиток",
    color = 0xE5E5E5,
    id = "IC2:itemIngot",
    dmg = 1
})
table.insert(currencies, {
    name = "Оловянный блок",
    color = 0xE5E5E5,
    id = "Forestry:resourceStorage",
    dmg = 2,
    max = 64
})

table.insert(currencies, {
    name = "Бесплатно",
})

return currencies
