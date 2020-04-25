local games = {}

table.insert(games, {
    title = "Рулетка",
    file = "game_Roulette.lua",
    available = true,
    image = "game_Roulette.pic",
    author = "krovyaka",
    description = "Руле́тка — азартная игра (слово рулетка (roulette) происходит от французского слова «ру» в " ..
            "переводе с французского означает «колесо, ролик, бегунок»). Рулетка впервые появилась во Франции. Она называлась " ..
            "«хока» и в ней было 40 пронумерованных гнёзд и три были помечены «зеро». Во времена короля Луи XIV, кардинал " ..
            "Мазарини, чтобы пополнить казну, повсеместно разрешил во Франции открывать казино. После смерти Мазарини в 1661 " ..
            "году вышел указ, гласивший, что всякий, кто осмелится открыть казино для игры в хока, будет казнен."
})

table.insert(games, {
    title = "Больше-Меньше",
    file = "game_More_less.lua",
    available = false,
    image = "game_More_less.pic",
    author = "Durex77",
    description = "Описание временно недоступно"
})

table.insert(games, {
    title = "Блэкджек",
    file = "game_Blackjack.lua",
    available = true,
    image = "game_Blackjack.pic",
    author = "Durex77",
    description = "Описание временно недоступно"
})

table.insert(games, {
    title = "Лабиринт",
    file = "game_Labyrinth.lua",
    available = false,
    image = "game_Labyrinth.pic",
    author = "krovyaka, Durex77",
    description = "Описание временно недоступно"
})

table.insert(games, {
    title = "Сапёр",
    file = "game_Minesweeper.lua",
    available = false,
    image = "game_Minesweeper.pic",
    author = "krovyaka",
    description = "Описание временно недоступно"
})

table.insert(games, {
    title = "Видеопокер",
    file = "game_Video_poker.lua",
    available = false,
    image = "game_Video_poker.pic",
    author = "Durex77",
    description = "Описание временно недоступно"
})

return games