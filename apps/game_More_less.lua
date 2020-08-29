local component = require("component")
local event = require("event")
local term = require("term")
local casino = require("casino")
local gpu = component.gpu

local login, value, players_card, dealer_card, time_sleep, time_sleep_end = false, 1, {}, {}, 0.2, 1.5
local first_win = false
local deck

local consoleLines = {}
for i = 1, 13 do
    consoleLines[i] = ""
end

local function drawRightMenu()
    gpu.setBackground(login and 0x613C3C or 0x990000)
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
                  { card = "T", suit = "♥" }, { card = "T", suit = "♦" }, { card = "T", suit = "♣" }, { card = "T", suit = "♠" }
    }

    obj.index = 1
    obj.pod = true

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

local function mathRound(num, idp)
    local mlt = 10 ^ (idp or 0)
    return math.floor(num * mlt + 0.5) / mlt
end

local function drawDisplayForOneHand()
    gpu.setBackground(0x006400)
    term.clear()
    drawRightMenu()
    gpu.setBackground(0x00aa00)
    gpu.fill(3, 2, 36, 18, " ")

    gpu.setBackground(0x229922)

    gpu.fill(9, 9, 6, 6, ' ')
    gpu.fill(27, 9, 6, 6, ' ')

    gpu.setBackground(0x20B2AA)
    gpu.set(17, 10, ' Больше ')

    gpu.set(17, 13, ' Меньше ')

    gpu.set(13, 6, " Забрать ставку ")
    gpu.setBackground(0x00aa00)
    gpu.setForeground(0xffffff)
    gpu.set(16, 4, "Ставка: " .. value)
    gpu.set(10, 16, "Следующая ставка: " .. value * 2)

end

local function giveCardPlayer(card)
    gpu.setBackground(0xffffff)
    if card.suit == '♥' or card.suit == '♦' then
        gpu.setForeground(0xaa0000)
    else
        gpu.setForeground(0x000000)
    end

    players_card = card

    gpu.fill(9, 9, 6, 6, ' ')

    os.sleep(time_sleep)
    gpu.fill(27, 9, 6, 6, ' ')
    os.sleep(time_sleep)
    gpu.set(9, 9, card.card)
    gpu.set(10, 10, card.suit)
    gpu.set(13, 13, card.suit)
    if card.card == '10' then
        gpu.set(13, 14, card.card)
    else
        gpu.set(14, 14, card.card)
    end
    os.sleep(time_sleep)
end

local function startGame()
    value = value / 2
    drawDisplayForOneHand()
    deck:hinder()
    local card = deck:get()
    giveCardPlayer(card)
end

local function giveCardCasino()
    local card = deck:get()
    gpu.setBackground(0xffffff)
    if card.suit == '♥' or card.suit == '♦' then
        gpu.setForeground(0xaa0000)
    else
        gpu.setForeground(0x000000)
    end

    dealer_card = card

    os.sleep(time_sleep)
    gpu.set(27, 9, card.card)
    gpu.set(28, 10, card.suit)
    gpu.set(29, 13, card.suit)
    if card.card == '10' then
        gpu.set(31, 14, card.card)
    else
        gpu.set(32, 14, card.card)
    end
    os.sleep(time_sleep)
end

--setDefaultColor(22,5,10)
local function setDefaultColor(left, top, bet)
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x888888)
    gpu.set(20, 5, '1')
    gpu.set(20, 7, '5')
    gpu.set(22, 5, '10')
    gpu.set(22, 7, '25')
    gpu.set(25, 5, '50')
    gpu.set(25, 7, '75')
    gpu.set(28, 5, '100')
    gpu.set(28, 7, '250')
    gpu.setBackground(0x00aa00)
    gpu.set(left, top, tostring(bet))
    return bet
end

local function drawDisplay()
    gpu.setBackground(0xe0e0e0)
    term.clear()
    drawRightMenu()
    gpu.setBackground(0x00aa00)
    gpu.fill(3, 2, 14, 7, ' ')
    gpu.setBackground(0xffffff)
    gpu.setForeground(0xaa0000)

    gpu.fill(5, 3, 4, 4, ' ')
    gpu.set(5, 3, 'J')
    gpu.set(6, 4, '♥')
    gpu.set(7, 5, '♥')
    gpu.set(8, 6, 'J')

    gpu.setForeground(0x000000)
    gpu.fill(11, 4, 4, 4, ' ')
    gpu.set(11, 4, 'T')
    gpu.set(12, 5, '♠')
    gpu.set(13, 6, '♠')
    gpu.set(14, 7, 'T')

    gpu.fill(3, 10, 36, 10, ' ')
    gpu.fill(19, 2, 20, 7, ' ')
    gpu.setForeground(0xffffff)
    setDefaultColor(20, 5, 1)

    gpu.setBackground(0x00aa00)
    gpu.fill(32, 5, 6, 3, ' ')
    gpu.set(20, 5, '1')
    value = 1
    gpu.set(32, 6, 'Начать')
    gpu.setForeground(0x000000)
    gpu.setBackground(0xffffff)

    gpu.set(21, 3, 'Выберите ставку')

end

local function getCardValue(card)
    if (card.card == '2') then
        return 2
    elseif (card.card == '3') then
        return 3
    elseif (card.card == '4') then
        return 4
    elseif (card.card == '5') then
        return 5
    elseif (card.card == '6') then
        return 6
    elseif (card.card == '7') then
        return 7
    elseif (card.card == '8') then
        return 8
    elseif (card.card == '9') then
        return 9
    elseif (card.card == '10') then
        return 10
    elseif (card.card == 'J') then
        return 11
    elseif (card.card == 'Q') then
        return 12
    elseif (card.card == 'K') then
        return 13
    elseif (card.card == 'T') then
        return 14
    end
end

local function win()
    if (first_win) then
        value = mathRound(value * 1.2, 2)
    else
        value = value * 2
        first_win = true
    end

    gpu.setBackground(0x00aa00)
    gpu.setForeground(0xffffff)
    gpu.fill(16, 4, 18, 1, " ")
    gpu.set(16, 4, "Ставка: " .. value)
    gpu.fill(10, 16, 25, 1, " ")
    gpu.set(10, 16, "Следующая ставка: " .. mathRound(value * 1.2, 2))
end

local function lose()
    login = false
    first_win = false
    message("Вы проиграли!")
    os.sleep(1)
    drawDisplay()
    casino.gameIsOver()
end

local function casinoPlay(type_of_game)
    giveCardCasino()
    if (type_of_game == 'less') then
        if (getCardValue(players_card) >= getCardValue(dealer_card)) then
            win()
            giveCardPlayer(dealer_card)
        else
            lose()
        end
    else
        if (getCardValue(players_card) <= getCardValue(dealer_card)) then
            win()
            giveCardPlayer(dealer_card)
        else
            lose()
        end
    end
end

local function rewardPlayer(reward, msg)
    message(msg)
    local money = mathRound(reward, 2)
    message("Вы выиграли " .. money)
    casino.reward(money)
    os.sleep(time_sleep_end)
    login = false
    first_win = false
    drawDisplay()
end

deck = Deck:new()
gpu.setResolution(70, 20)
drawDisplay()
while true do
    local e, _, x, y = event.pull(3, "touch")
    if e and login then
        if (x >= 13 and y == 6 and x <= 28) then
            rewardPlayer(value, "Вы забрали ставку.")
            login = false
            os.sleep(1)
            drawDisplay()
            casino.gameIsOver()
        elseif (x >= 17 and y == 10 and x <= 24) then
            casinoPlay('more')
        elseif (x >= 17 and y == 13 and x <= 24) then
            casinoPlay('less')
        elseif x >= 41 and x <= 69 and y >= 17 and y <= 19 then
            message("Сначала закончите игру.")
        end
    elseif e and not login then
        if x == 20 and y == 5 then
            value = setDefaultColor(20, 5, 1)
        elseif x == 20 and y == 7 then
            value = setDefaultColor(20, 7, 5)
        elseif (x == 22 or x == 23) and y == 5 then
            value = setDefaultColor(22, 5, 10)
        elseif (x == 22 or x == 23) and y == 7 then
            value = setDefaultColor(22, 7, 25)
        elseif (x == 25 or x == 26) and y == 5 then
            value = setDefaultColor(25, 5, 50)
        elseif (x == 25 or x == 26) and y == 7 then
            value = setDefaultColor(25, 7, 75)
        elseif (x == 28 or x == 29 or x == 30) and y == 5 then
            value = setDefaultColor(28, 5, 100)
        elseif (x == 28 or x == 29 or x == 30) and y == 7 then
            value = setDefaultColor(28, 7, 250)
        elseif x >= 41 and x <= 69 and y >= 17 and y <= 19 then
            error("Exit by request")
        elseif (x >= 32 and x <= 37 and y >= 5 and y <= 7) then
            local payed, reason = casino.takeMoney(value)
            if payed then
                login = true
                startGame()
            else
                message(reason)
            end
        end
    end
end