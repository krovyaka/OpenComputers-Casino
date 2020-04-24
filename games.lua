local games = {}

table.insert(games, {
    title = "Рулетка",
    file = "game_Roulette.lua",
    available = true,
    image = "game_Roulette.pic",
    description = "Руле́тка — азартная игра (слово рулетка (roulette) происходит от французского слова «ру» в " ..
    "переводе с французского означает «колесо, ролик, бегунок»). Рулетка впервые появилась во Франции. Она называлась " ..
    "«хока» и в ней было 40 пронумерованных гнёзд и три были помечены «зеро». Во времена короля Луи XIV, кардинал " ..
    "Мазарини, чтобы пополнить казну, повсеместно разрешил во Франции открывать казино. После смерти Мазарини в 1661 " ..
    "году вышел указ, гласивший, что всякий, кто осмелится открыть казино для игры в хока, будет казнен."
})

table.insert(games, { title = "Больше-Меньше", file = "game_More_less", available = true })
table.insert(games, { title = "Блэкджек", file = "game_Black_jack", available = true })
table.insert(games, { title = "Лабиринт", file = "game_Labyrinth", available = true })
table.insert(games, { title = "Сапёр", file = "game_Minesweeper", available = true })
table.insert(games, { title = "Видеопокер", file = "game_Video_poker", available = true })
table.insert(games, { title = "Слоты", file = "game_Slot_machine", available = false })

return games