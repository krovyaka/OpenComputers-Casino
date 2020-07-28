local currencies = {}

table.insert(currencies, {
    name = "Деньги",
    image = "money.pic",
    id = "customnpcs:npcMoney",
    dmg = 0
})

table.insert(currencies, {
    name = "Светопыль",
    image = "glowstone_dust.pic",
    id = "minecraft:glowstone_dust",
    dmg = 0,
    max = 100
})

table.insert(currencies, {
    name = "Железный слиток",
    image = "iron_ingot.pic",
    id = "minecraft:iron_ingot",
    dmg = 0,
    max = 200
})

return currencies
