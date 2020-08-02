local component = require("component")
local term = require("term")
local gpu = component.gpu
local event = require("event")
local casino = require("casino")

local login, blackjack, player, value, players_cards, dialer_cards, time_sleep, time_sleep_end = false, false, 'p', 1, {}, {}, 0.2, 3

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
    obj.cards = { { card = "2", suit = "♥" }, { card = "2", suit = "♦" }, { card = "2", suit = "♣" },
                  { card = "2", suit = "♠" }, { card = "3", suit = "♥" }, { card = "3", suit = "♦" },
                  { card = "3", suit = "♣" }, { card = "3", suit = "♠" }, { card = "4", suit = "♥" },
                  { card = "4", suit = "♦" }, { card = "4", suit = "♣" }, { card = "4", suit = "♠" },
                  { card = "5", suit = "♥" }, { card = "5", suit = "♦" }, { card = "5", suit = "♣" },
                  { card = "5", suit = "♠" }, { card = "6", suit = "♥" }, { card = "6", suit = "♦" },
                  { card = "6", suit = "♣" }, { card = "6", suit = "♠" }, { card = "7", suit = "♥" },
                  { card = "7", suit = "♦" }, { card = "7", suit = "♣" }, { card = "7", suit = "♠" },
                  { card = "8", suit = "♥" }, { card = "8", suit = "♦" }, { card = "8", suit = "♣" },
                  { card = "8", suit = "♠" }, { card = "9", suit = "♥" }, { card = "9", suit = "♦" },
                  { card = "9", suit = "♣" }, { card = "9", suit = "♠" }, { card = "10", suit = "♥" },
                  { card = "10", suit = "♦" }, { card = "10", suit = "♣" }, { card = "10", suit = "♠" },
                  { card = "J", suit = "♥" }, { card = "J", suit = "♦" }, { card = "J", suit = "♣" },
                  { card = "J", suit = "♠" }, { card = "Q", suit = "♥" }, { card = "Q", suit = "♦" },
                  { card = "Q", suit = "♣" }, { card = "Q", suit = "♠" }, { card = "K", suit = "♥" },
                  { card = "K", suit = "♦" }, { card = "K", suit = "♣" }, { card = "K", suit = "♠" },
                  { card = "T", suit = "♥" }, { card = "T", suit = "♦" }, { card = "T", suit = "♣" },
                  { card = "T", suit = "♠" } }
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

local deck = Deck:new()

local function drawDisplayForOneHand()
    gpu.setBackground(0x006400)
    term.clear()
    gpu.setBackground(0x00aa00)
    gpu.fill(3, 2, 36, 18, " ")

    gpu.setBackground(0x229922)
    for i = 0, 4 do
        gpu.fill(9 + i * 5, 6, 4, 4, ' ')
    end
    for i = 0, 4 do
        gpu.fill(9 + i * 5, 15, 4, 4, ' ')
    end

    gpu.setBackground(0x20B2AA)
    gpu.fill(9, 11, 11, 1, ' ')
    gpu.set(13, 11, 'Ещё')
    gpu.fill(22, 11, 11, 1, ' ')
    gpu.set(25, 11, 'Хватит')

    gpu.fill(9, 13, 11, 1, ' ')
    gpu.set(11, 13, 'Удвоить')

    gpu.setBackground(0x00aa00)
    gpu.setForeground(0xffffff)
    gpu.set(13, 4, "Ставка: " .. value)
end

local function countCards(temp_cards, boolean)
    local Tcount = 0
    local count = 0
    for i = 1, #temp_cards do
        if temp_cards[i].card == '2' then
            count = count + 2
        elseif temp_cards[i].card == '3' then
            count = count + 3
        elseif temp_cards[i].card == '4' then
            count = count + 4
        elseif temp_cards[i].card == '5' then
            count = count + 5
        elseif temp_cards[i].card == '6' then
            count = count + 6
        elseif temp_cards[i].card == '7' then
            count = count + 7
        elseif temp_cards[i].card == '8' then
            count = count + 8
        elseif temp_cards[i].card == '9' then
            count = count + 9
        elseif temp_cards[i].card == '10' then
            count = count + 10
        elseif temp_cards[i].card == 'J' then
            count = count + 10
        elseif temp_cards[i].card == 'Q' then
            count = count + 10
        elseif temp_cards[i].card == 'K' then
            count = count + 10
        elseif temp_cards[i].card == 'T' then
            Tcount = Tcount + 1
        end
    end

    if (boolean) then
        if Tcount > 0 then
            if count + Tcount * 11 > 21 then
                count = count + Tcount
            else
                count = count + Tcount * 11
            end
        end
        return count
    else
        local temp_count = count
        if Tcount > 0 then
            if (count + Tcount * 11 <= 21) then
                temp_count = temp_count + Tcount
                temp_count = temp_count .. "/"
                count = count + Tcount * 11
                temp_count = temp_count .. count
                return temp_count
            else
                temp_count = temp_count + Tcount
                temp_count = temp_count .. ""
                return temp_count
            end
        end
        return temp_count .. ''
    end
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
    casino.gameIsOver()
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

    gpu.set(5, 11, 'Blackjack')
    gpu.set(5, 13, 'Правила:')
    gpu.set(5, 14, '1. Нужно набрать больше очков,')
    gpu.set(5, 15, 'чем у дилера.')
    gpu.set(5, 16, '2. Нельзя набирать больше 21 очка.')
    gpu.set(5, 17, '3. Победа удваивает ставку.')
    gpu.set(5, 18, '4. Ничья возвращает ставку.')
    gpu.set(5, 19, 'Более подробно есть в интернете.')

    gpu.set(21, 3, 'Выберите ставку')
end

local function giveCardPlayer()
    gpu.setBackground(0xffffff)
    local card = deck:get()
    if card.suit == '♥' or card.suit == '♦' then
        gpu.setForeground(0xaa0000)
    else
        gpu.setForeground(0x000000)
    end
    if #players_cards == 0 then
        gpu.fill(9, 15, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(9, 15, card.card)
        gpu.set(10, 16, card.suit)
        gpu.set(11, 17, card.suit)
        if card.card == '10' then
            gpu.set(11, 18, card.card)
        else
            gpu.set(12, 18, card.card)
        end
        os.sleep(time_sleep)
    elseif #players_cards == 1 then
        gpu.fill(14, 15, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(14, 15, card.card)
        gpu.set(15, 16, card.suit)
        gpu.set(16, 17, card.suit)
        if card.card == '10' then
            gpu.set(16, 18, card.card)
        else
            gpu.set(17, 18, card.card)
        end
    elseif #players_cards == 2 then
        gpu.fill(19, 15, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(19, 15, card.card)
        gpu.set(20, 16, card.suit)
        gpu.set(21, 17, card.suit)
        if card.card == '10' then
            gpu.set(21, 18, card.card)
        else
            gpu.set(22, 18, card.card)
        end
    elseif #players_cards == 3 then
        gpu.fill(24, 15, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(24, 15, card.card)
        gpu.set(25, 16, card.suit)
        gpu.set(26, 17, card.suit)
        if card.card == '10' then
            gpu.set(26, 18, card.card)
        else
            gpu.set(27, 18, card.card)
        end
    elseif #players_cards == 4 then
        gpu.fill(29, 15, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(29, 15, card.card)
        gpu.set(30, 16, card.suit)
        gpu.set(31, 17, card.suit)
        if card.card == '10' then
            gpu.set(31, 18, card.card)
        else
            gpu.set(32, 18, card.card)
        end
    end
    players_cards[#players_cards + 1] = card
    gpu.setBackground(0x00aa00)
    gpu.setForeground(0xffffff)
    gpu.fill(19, 19, 10, 1, ' ')
    gpu.set(19, 19, countCards(players_cards, false))
    if countCards(players_cards, true) > 21 then
        message("Перебор, победа казино!")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
    end
end

local function giveCardDialer()
    gpu.setBackground(0xffffff)
    local card = deck:get()
    if card.suit == '♥' or card.suit == '♦' then
        gpu.setForeground(0xaa0000)
    else
        gpu.setForeground(0x000000)
    end
    if #dialer_cards == 0 then
        gpu.fill(9, 6, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(9, 6, card.card)
        gpu.set(10, 7, card.suit)
        gpu.set(11, 8, card.suit)
        if card.card == '10' then
            gpu.set(11, 9, card.card)
        else
            gpu.set(12, 9, card.card)
        end
        os.sleep(time_sleep)
        gpu.fill(14, 6, 4, 4, ' ')
    elseif #dialer_cards == 1 then
        os.sleep(time_sleep)
        gpu.set(14, 6, card.card)
        gpu.set(15, 7, card.suit)
        gpu.set(16, 8, card.suit)
        if card.card == '10' then
            gpu.set(16, 9, card.card)
        else
            gpu.set(17, 9, card.card)
        end
        os.sleep(time_sleep)
    elseif #dialer_cards == 2 then
        gpu.fill(19, 6, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(19, 6, card.card)
        gpu.set(20, 7, card.suit)
        gpu.set(21, 8, card.suit)
        if card.card == '10' then
            gpu.set(21, 9, card.card)
        else
            gpu.set(22, 9, card.card)
        end
        os.sleep(time_sleep)
    elseif #dialer_cards == 3 then
        gpu.fill(24, 6, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(24, 6, card.card)
        gpu.set(25, 7, card.suit)
        gpu.set(26, 8, card.suit)
        if card.card == '10' then
            gpu.set(26, 9, card.card)
        else
            gpu.set(27, 9, card.card)
        end
        os.sleep(time_sleep)
    elseif #dialer_cards == 4 then
        gpu.fill(29, 6, 4, 4, ' ')
        os.sleep(time_sleep)
        gpu.set(29, 6, card.card)
        gpu.set(30, 7, card.suit)
        gpu.set(31, 8, card.suit)
        if card.card == '10' then
            gpu.set(31, 9, card.card)
        else
            gpu.set(32, 9, card.card)
        end
        os.sleep(time_sleep)
    end
    dialer_cards[#dialer_cards + 1] = card
    gpu.setBackground(0x00aa00)
    gpu.setForeground(0xffffff)
    gpu.fill(19, 10, 10, 1, ' ')
    gpu.set(19, 10, countCards(dialer_cards, false))
end

local function dialerStartPlay()
    giveCardDialer()
    if (countCards(dialer_cards, true) == 21) then
        message("Blackjack, Победа казино!")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
        return
    end
    while countCards(dialer_cards, true) < 17 and #dialer_cards < 5 do
        giveCardDialer()
    end
    if countCards(dialer_cards, true) > 21 then
        message("Перебор, победа игрока!")
        casino.reward(value * 2)
        message("Вы выиграли " .. 2 * value .. "$")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
    elseif countCards(players_cards, true) > countCards(dialer_cards, true) then
        message("Победа игрока!")
        casino.reward(value * 2)
        message("Вы выиграли " .. 2 * value .. "$")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
    elseif countCards(players_cards, true) < countCards(dialer_cards, true) then
        message("Победа казино!")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
    else
        message("Ничья!")
        casino.reward(value)
        message("Вы выиграли " .. value .. "$")
        os.sleep(time_sleep_end)
        login = false
        drawDisplay()
    end
end

local function startGame()
    blackjack = false
    dialer_cards = {}
    players_cards = {}
    deck:hinder()

    drawDisplayForOneHand()
    drawRightMenu()
    giveCardPlayer()
    giveCardPlayer()
    giveCardDialer()
    if (countCards(players_cards, true) == 21) then
        if (countCards(dialer_cards, true) == 11) then
            message("Blackjack!")
            blackjack = true
            gpu.setBackground(0x00aa00)
            gpu.fill(9, 11, 26, 3, " ")
            gpu.setBackground(0x20B2AA)
            gpu.setForeground(0xffffff)
            gpu.fill(9, 11, 11, 1, ' ')
            gpu.set(12, 11, 'Забрать')
            gpu.fill(22, 11, 11, 1, ' ')
            gpu.set(22, 11, 'Продолжить')
        else
            message("Blackjack!")
            message("Вы выиграли " .. value * 1.5)
            casino.reward(value * 1.5)
            os.sleep(time_sleep_end)
            login = false
            drawDisplay()
        end
    end
end

local function reward(money, msg)
    message(msg)
    message("Вы выиграли " .. money)
    casino.reward(money)
    os.sleep(time_sleep_end)
    login = false
    blackjack = false
    drawDisplay()
end

gpu.setResolution(70, 20)
drawDisplay()
while true do
    local e, _, x, y, _, p = event.pull(3, "touch")
    if e and login and p == player then
        if blackjack then
            if (x >= 9 and y == 11 and x <= 19) then
                reward(value, "Blackjack!")
            elseif (x >= 22 and y == 11 and x < 33) then
                giveCardDialer()
                if (countCards(dialer_cards, true) == 21) then
                    message("Blackjack!, победа казино!")
                else
                    reward(value * 2.5, "Blackjack!")
                end
            end
        elseif x >= 9 and y == 11 and x < 20 then
            giveCardPlayer()
        elseif x >= 22 and y == 11 and x < 33 then
            dialerStartPlay()
        elseif x >= 9 and y == 13 and x < 20 then
            if (#players_cards > 2) then
                message("Только с двумя картами!")
            else
                local payed, reason = casino.takeMoney(value)
                if payed then
                    message("Начало игры за " .. value)
                    gpu.setBackground(0x00aa00)
                    value = value * 2
                    gpu.setForeground(0xffffff)
                    gpu.set(13, 4, "Ставка: " .. value)
                    giveCardPlayer()
                    if (login) then
                        dialerStartPlay()
                    end
                else
                    message(reason)
                end
            end
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
                player = p
                login = true
                startGame()
            else
                message(reason)
            end
        end
    end
end