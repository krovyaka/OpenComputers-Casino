local component = require("component")
local term = require("term")
local casino = require("casino")
local event = require("event")
local gpu = component.gpu

local login = false
local time_sleep = 0.15
local value = 1
local game = false
local card_holds = { false, false, false, false, false }
local players_cards

local consoleLines = {}
for i = 1, 13 do
    consoleLines[i] = ""
end

local function drawRightMenu()
    gpu.setBackground(0x990000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(41, 17, 28, 3, " ")
    gpu.set(52, 18, "Выход")

    gpu.setBackground(0x000000)
    gpu.setForeground(0xAAAAAA)
    gpu.fill(41, 2, 28, 14, " ")
    gpu.set(42, 2, "Вывод:")
    for i = 1, #consoleLines do
        gpu.setForeground((15 - #consoleLines + i) * 0x111111)
        gpu.set(42, 16 - i, consoleLines[i])
    end
end

local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, msg)
    drawRightMenu()
end

local function drawGame()
    gpu.setBackground(0x7fa77d)
    term.clear()
    drawRightMenu()
    gpu.setBackground(0x3d3d3d)
    gpu.fill(4, 2, 24, 1, ' ')
    gpu.fill(24, 5, 4, 10, ' ')
    gpu.fill(30, 11, 8, 1, ' ')
    gpu.fill(4, 5, 20, 1, ' ')
    gpu.setForeground(0x00ff00)
    gpu.set(4, 5, 'Комбинации:')
    gpu.set(30, 11, 'Ставка:')

    gpu.setBackground(0xffffff)
    for x = 0, 4 do
        x = x * 5 + 4
        gpu.fill(x, 16, 4, 4, ' ')
    end
    gpu.setBackground(0x000000)
    gpu.fill(4, 3, 24, 1, ' ')
    gpu.fill(4, 6, 20, 9, ' ')
    gpu.fill(30, 12, 8, 5, ' ')
    gpu.setForeground(0xffffff)
    gpu.set(4, 6, 'Флеш Рояль')
    gpu.set(4, 7, 'Стрит Флеш')
    gpu.set(4, 8, 'Каре')
    gpu.set(4, 9, 'Фулл хаус')
    gpu.set(4, 10, 'Флеш')
    gpu.set(4, 11, 'Стрит')
    gpu.set(4, 12, 'Трипс')
    gpu.set(4, 13, 'Две пары')
    gpu.set(4, 14, 'Пара вальтов и выше')
    for i = 1, 5 do
        gpu.set(33, 11 + i, tostring(i))
    end
    gpu.setBackground(0x00ff00)
    gpu.fill(30, 17, 8, 3, ' ')
    gpu.set(31, 18, 'Начать')

    --Рисую картинку
    gpu.setBackground(0xffffff)
    gpu.fill(34, 3, 1, 1, ' ')
    gpu.fill(33, 4, 3, 1, ' ')
    gpu.fill(32, 5, 5, 1, ' ')
    gpu.fill(31, 6, 7, 1, ' ')
    gpu.fill(34, 7, 1, 1, ' ')
    gpu.fill(33, 8, 3, 1, ' ')
    gpu.setBackground(0xc6c6c6)
    gpu.set(33, 3, ' ')
    gpu.set(32, 4, ' ')
    gpu.set(31, 5, ' ')
    gpu.set(30, 6, ' ')
    gpu.set(33, 7, ' ')
    gpu.set(32, 8, ' ')
end

local function getDivideBy4(number)
    return string.rep(' ', 4 - string.len(number)) .. number
end

local function moneyOfCombination(combination)
    if (value == 5 and combination == 1) then
        return 4000
    elseif (combination == 1) then
        return 250 * value
    elseif (combination == 2) then
        return 50 * value
    elseif (combination == 3) then
        return 25 * value
    elseif (combination == 4) then
        return 9 * value
    elseif (combination == 5) then
        return 5 * value
    elseif (combination == 6) then
        return 4 * value
    elseif (combination == 7) then
        return 3 * value
    elseif (combination == 8) then
        return 2 * value
    elseif (combination == 9) then
        return 1 * value
    else
        return 0
    end
end

local function drawRewards(k, comb)
    gpu.setForeground(0x0000ff)
    gpu.setBackground(0x3d3d3d)
    if (k == 5) then
        gpu.set(24, 6, getDivideBy4(4000))
    else
        gpu.set(24, 6, getDivideBy4(250 * k))
    end
    gpu.set(24, 7, getDivideBy4(50 * k))
    gpu.set(24, 8, getDivideBy4(25 * k))
    gpu.set(24, 9, getDivideBy4(9 * k))
    gpu.set(24, 10, getDivideBy4(5 * k))
    gpu.set(24, 11, getDivideBy4(4 * k))
    gpu.set(24, 12, getDivideBy4(3 * k))
    gpu.set(24, 13, getDivideBy4(2 * k))
    gpu.set(24, 14, getDivideBy4(1 * k))

    if (comb > 0) then
        gpu.setBackground(0x00ff00)
        if (k == 5 and comb == 1) then
            gpu.set(24, 6, getDivideBy4(4000))
        else
            gpu.set(24, comb + 5, getDivideBy4(moneyOfCombination(comb)))
        end
    end
    gpu.setBackground(0x000000)
    for i = 1, 5 do
        if (i == k) then
            gpu.setForeground(0x00ff00)
            gpu.set(33, 11 + i, tostring(i))
        else
            gpu.setForeground(0xffffff)
            gpu.set(33, 11 + i, tostring(i))
        end
    end
end

local Deck = {}

function Deck:new()
    local obj = {}
    obj.cards = { { card = "2", suit = "♥" }, { card = "2", suit = "♦" }, { card = "2", suit = "♣" }, { card = "2", suit = "♠" },
                  { card = "3", suit = "♥" }, { card = "3", suit = "♦" }, { card = "3", suit = "♣" }, { card = "3", suit = "♠" },
                  { card = "4", suit = "♥" }, { card = "4", suit = "♦" }, { card = "4", suit = "♣" }, { card = "4", suit = "♠" },
                  { card = "5", suit = "♥" }, { card = "5", suit = "♦" }, { card = "5", suit = "♣" }, { card = "5", suit = "♠" },
                  { card = "6", suit = "♥" }, { card = "6", suit = "♦" }, { card = "6", suit = "♣" }, { card = "6", suit = "♠" },
                  { card = "7", suit = "♥" }, { card = "7", suit = "♦" }, { card = "7", suit = "♣" }, { card = "7", suit = "♠" },
                  { card = "8", suit = "♥" }, { card = "8", suit = "♦" }, { card = "8", suit = "♣" }, { card = "8", suit = "♠" },
                  { card = "9", suit = "♥" }, { card = "9", suit = "♦" }, { card = "9", suit = "♣" }, { card = "9", suit = "♠" },
                  { card = "10", suit = "♥" }, { card = "10", suit = "♦" }, { card = "10", suit = "♣" }, { card = "10", suit = "♠" },
                  { card = "J", suit = "♥" }, { card = "J", suit = "♦" }, { card = "J", suit = "♣" }, { card = "J", suit = "♠" },
                  { card = "Q", suit = "♥" }, { card = "Q", suit = "♦" }, { card = "Q", suit = "♣" }, { card = "Q", suit = "♠" },
                  { card = "K", suit = "♥" }, { card = "K", suit = "♦" }, { card = "K", suit = "♣" }, { card = "K", suit = "♠" },
                  { card = "T", suit = "♥" }, { card = "T", suit = "♦" }, { card = "T", suit = "♣" }, { card = "T", suit = "♠" } }

    obj.index = 1

    function obj:get()
        local temp = self.cards[self.index]
        self.index = self.index + 1
        return temp
    end

    function obj:hinder()
        for first = 1, 52 do
            local second, firstCard = math.random(1, 52), self.cards[first]
            self.cards[first] = self.cards[second]
            self.cards[second] = firstCard
        end
        self.index = 1
    end

    setmetatable(obj, self)
    self.__index = self;
    return obj
end

local deck = Deck:new()

local function isFlush(cards)
    for i = 2, #cards do
        if (cards[i].suit ~= cards[1].suit) then
            return false
        end
    end
    return true
end

local function cardPower(card)
    if card == '2' then
        return 2
    elseif card == '3' then
        return 3
    elseif card == '4' then
        return 4
    elseif card == '5' then
        return 5
    elseif card == '6' then
        return 6
    elseif card == '7' then
        return 7
    elseif card == '8' then
        return 8
    elseif card == '9' then
        return 9
    elseif card == '10' then
        return 10
    elseif card == 'J' then
        return 11
    elseif card == 'Q' then
        return 12
    elseif card == 'K' then
        return 13
    elseif card == 'T' then
        return 14
    end
end

local function isCardWithPower(cards, power)
    for i = 1, #cards do
        if (cardPower(cards[i].card) == power) then
            return true
        end
    end
    return false
end

local function getMaxCard(cards)
    local index = 1
    for i = 2, #cards do
        if (cardPower(cards[i].card) > cardPower(cards[index].card)) then
            index = i
        end
    end
    return cards[index].card
end

local function isStraight(cards)
    local temp_card = getMaxCard(cards)
    if (isCardWithPower(cards, 2) and isCardWithPower(cards, 3) and isCardWithPower(cards, 4) and isCardWithPower(cards, 5) and isCardWithPower(cards, 14)) then
        return true
    end
    for i = 1, 4 do
        if (isCardWithPower(cards, cardPower(temp_card) - i) == false) then
            return false
        end
    end
    return true
end

local function isStraightFlush(cards)
    return (isStraight(cards) and isFlush(cards))
end

local function isFlushRoyal(cards)
    return (isStraightFlush(cards) and isCardWithPower(cards, 14) and isCardWithPower(cards, 13))
end

local function cardsCount(cards, card)
    local count = 0
    for i = 1, #cards do
        if (cards[i].card == card) then
            count = count + 1
        end
    end
    return count
end

local function isFourOfAKind(cards)
    for i = 1, 2 do
        if (cardsCount(cards, cards[i].card) == 4) then
            return true
        end
    end
    return false
end

local function isFullHouse(cards)
    local trips, pair = false, false
    for i = 1, 4 do
        if (cardsCount(cards, cards[i].card) == 3) then
            trips = true
        elseif (cardsCount(cards, cards[i].card) == 2) then
            pair = true
        end
    end
    return (trips and pair)
end

local function isTrips(cards)
    for i = 1, 3 do
        if (cardsCount(cards, cards[i].card) == 3) then
            return true
        end
    end
    return false
end

local function isTwoPairs(cards)
    local count_of_pairs = 0
    for i = 1, 5 do
        if (cardsCount(cards, cards[i].card) == 2) then
            count_of_pairs = count_of_pairs + 1
        end
    end
    return (count_of_pairs == 4)
end

local function isJackOrBetter(cards)
    for i = 1, 4 do
        if (cardsCount(cards, cards[i].card) == 2 and cardPower(cards[i].card) >= 11) then
            return true
        end
    end
    return false
end

local function getCombination(cards)
    if (isFlushRoyal(cards)) then
        return 1
    elseif (isStraightFlush(cards)) then
        return 2
    elseif (isFourOfAKind(cards)) then
        return 3
    elseif (isFullHouse(cards)) then
        return 4
    elseif (isFlush(cards)) then
        return 5
    elseif (isStraight(cards)) then
        return 6
    elseif (isTrips(cards)) then
        return 7
    elseif (isTwoPairs(cards)) then
        return 8
    elseif (isJackOrBetter(cards)) then
        return 9
    else
        return 0
    end
end

local function logging()
    drawGame()
    game = false
    drawRewards(1, 0)
end

local function drawCard(x, card)
    x = x * 5 + 4
    gpu.fill(x, 16, 4, 4, ' ')
    os.sleep(time_sleep)
    gpu.set(x, 16, card.card)
    gpu.set(x + 1, 17, card.suit)
    gpu.set(x + 2, 18, card.suit)
    if card.card == '10' then
        gpu.set(x + 2, 19, card.card)
    else
        gpu.set(x + 3, 19, card.card)
    end
    os.sleep(time_sleep)
end

local function giveCardToPlayer(id_card)
    gpu.setBackground(0xffffff)
    local card = deck:get()
    if card.suit == '♥' or card.suit == '♦' then
        gpu.setForeground(0xaa0000)
    else
        gpu.setForeground(0x000000)
    end
    drawCard(id_card, card)
    players_cards[id_card + 1] = card
    os.sleep(time_sleep)
end

local function startGame()
    drawRewards(value, 0)
    gpu.setBackground(0x7fa77d)
    gpu.setForeground(0xffffff)
    gpu.fill(4, 15, 25, 5, ' ')
    card_holds = { false, false, false, false, false }
    gpu.setBackground(0x00ff00)
    gpu.set(30, 18, 'Поменять')
    game = true
    players_cards = {}
    deck:hinder()
    for i = 0, 4 do
        giveCardToPlayer(i)
    end
    drawRewards(value, getCombination(players_cards))
end

local function drawHeld(x)
    gpu.setBackground(0x7fa77d)
    gpu.setForeground(0xffffff)
    if card_holds[x + 1] then
        card_holds[x + 1] = false
        x = x * 5 + 4
        gpu.fill(x, 15, 4, 1, ' ')
    else
        card_holds[x + 1] = true
        x = x * 5 + 4
        gpu.set(x, 15, 'Hold')
    end
end

local function rewardPlayer(reward)
    if reward and reward > 0 then
        message("Вы выиграли " .. reward)
        casino.reward(reward)
        gpu.setBackground(0x000000)
        gpu.setForeground(0xffffff)
    else
        message("Вы проиграли ")
    end
    casino.gameIsOver()
end

local function updateCards()
    for i = 1, 5 do
        if (card_holds[i] == false) then
            giveCardToPlayer(i - 1)
        end
    end
    game = false
    gpu.setBackground(0x00ff00)
    gpu.setForeground(0xffffff)
    gpu.set(30, 18, ' Начать ')
    drawRewards(value, getCombination(players_cards))
    rewardPlayer(moneyOfCombination(getCombination(players_cards)))
end

gpu.setResolution(70, 20)
logging()
while true do
    local e, _, x, y, _, p = event.pull(3, "touch")
    if e then
        if (game == false) then
            if x >= 30 and y >= 17 and x <= 37 and y <= 19 then
                local payed, reason = casino.takeMoney(value)
                if payed then
                    gpu.setBackground(0x000000)
                    gpu.setForeground(0xffffff)
                    startGame()
                else
                    message(reason)
                end
            elseif (x >= 30 and y >= 12 and x <= 37 and y <= 16) then
                if (y == 12) then
                    drawRewards(1, 0)
                    value = 1
                elseif (y == 13) then
                    drawRewards(2, 0)
                    value = 2
                elseif (y == 14) then
                    drawRewards(3, 0)
                    value = 3
                elseif (y == 15) then
                    drawRewards(4, 0)
                    value = 4
                elseif (y == 16) then
                    drawRewards(5, 0)
                    value = 5
                end
            end
        else
            if (x >= 30 and y >= 17 and x <= 37 and y <= 19) then
                updateCards()
            elseif (x >= 4 and x <= 7 and y >= 16 and y <= 19) then
                drawHeld(0)
            elseif (x >= 9 and x <= 12 and y >= 16 and y <= 19) then
                drawHeld(1)
            elseif (x >= 14 and x <= 17 and y >= 16 and y <= 19) then
                drawHeld(2)
            elseif (x >= 19 and x <= 22 and y >= 16 and y <= 19) then
                drawHeld(3)
            elseif (x >= 24 and x <= 27 and y >= 16 and y <= 19) then
                drawHeld(4)
            end
        end
    end

    if e and x >= 41 and x <= 69 and y >= 17 and y <= 19 then
        if game then
            message("Сначала закончите игру")
        else
            error("Exit by request")
        end
    end
end