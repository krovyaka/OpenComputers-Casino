local currencies = {}

table.insert(currencies, {
    name = "Деньги",
    image = "money.pic",
    id = "",
    dmg = 0,
    max = nil
})

table.insert(currencies, {
    name = "Светопыль",
    image = "glowstone_dust.pic",
    id = 2000,
    dmg = 0,
    max = 100
})

table.insert(currencies, {
    name = "Железный слиток",
    image = "iron_ingot.pic",
    id = 350,
    dmg = 0,
    max = 200
})

return currencies
