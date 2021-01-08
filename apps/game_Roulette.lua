local component = require("component")
local term = require("term")
local event = require("event")
local casino = require("casino")
local buffer = require("doubleBuffering")

local values = { [0] = 'z', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r' }
local wheel = { 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26, 0, 32, 15, 19, 4, 21, 2, 25, 17 }
local red = { 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 }
local black = { 2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35 }
local bets = {}

local consoleLines = { "", "", "", "", "", "", "", "", "" }

local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, msg)
    buffer.drawRectangle(3, 23, 71, 9, 0x002f15, 0xffffff, " ")
    for i = 1, #consoleLines do
        buffer.drawText(4, 32 - i, (15 - #consoleLines + i) * 0x111111, consoleLines[i])
    end
    buffer.drawChanges()
end

local function drawNumber(left, top, number) -- requires redraw changes
    local background = values[number] == 'r' and 0xff0000 or values[number] == 'b' and 0x000000 or 0x00ff00
    buffer.drawRectangle(left, top, 6, 3, background, 0xffffff, " ")
    buffer.drawText(left + 2, top + 1, 0xffffff, tostring(number))
end

local function getNumberPostfix(number)
    if (number == 0) then
        return ""
    end
    for i = 1, #red do
        if (red[i] == number) then
            return "(красное)"
        end
    end
    return "(чёрное)"
end

local function drawStatic()
    buffer.setResolution(112, 32)
    buffer.clear(0xffffff)
    buffer.drawText(103, 14, 0x000000, "Ставки:")
    buffer.drawText(103, 15, 0x000000, "ЛКМ 1$")
    buffer.drawText(103, 16, 0x000000, "ПКМ 10$")
    buffer.drawRectangle(13, 2, 5, 11, 0x34a513, 0xffffff, ' ')
    buffer.drawText(15, 7, 0xffffff, "0")
    for i = 1, 36 do
        drawNumber(19 + math.floor((i - 1) / 3) * 7, 2 + ((3 - i) % 3 * 4), i)
    end
    buffer.drawRectangle(103, 2,  9,  3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(103, 6,  9,  3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(103, 10, 9,  3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(19,  14, 27, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(47,  14, 27, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(75,  14, 27, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(19,  18, 13, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(33,  18, 13, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(75,  18, 13, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(89,  18, 13, 3, 0x34a513, 0xffffff, ' ')
    buffer.drawText(106, 3, 0xffffff, "2к1")
    buffer.drawText(106, 7, 0xffffff, "2к1")
    buffer.drawText(106, 11, 0xffffff, "2к1")
    buffer.drawText(28, 15, 0xffffff, "первая 12")
    buffer.drawText(56, 15, 0xffffff, "вторая 12")
    buffer.drawText(84, 15, 0xffffff, "третья 12")
    buffer.drawText(22, 19, 0xffffff, "1 до 18")
    buffer.drawText(38, 19, 0xffffff, "Чёт")
    buffer.drawText(79, 19, 0xffffff, "Нечёт")
    buffer.drawText(91, 19, 0xffffff, "19 до 36")
    buffer.drawRectangle(75, 29, 36, 3,  0xff0000, 0xffffff, ' ')
    buffer.drawRectangle(75, 25, 36, 3,  0x34a513, 0xffffff, ' ')
    buffer.drawRectangle(47, 18, 13, 3,  0xff0000, 0xffffff, ' ')
    buffer.drawRectangle(3,  2,  8,  19, 0xffb109, 0xffffff, ' ')
    buffer.drawRectangle(3,  9,  8,  5,  0xffda54, 0xffffff, ' ')
    buffer.drawRectangle(61, 18, 13, 3,  0x000000, 0xffffff, ' ')
    buffer.drawRectangle(3,  22, 71, 10, 0xaaaaaa, 0xffffff, ' ')
    buffer.drawRectangle(3,  23, 71, 9,  0x002f15, 0xffffff, " ")
    buffer.drawRectangle(75, 22, 36, 1,  0xaaaaaa, 0xffffff, ' ')
    buffer.drawRectangle(75, 23, 36, 1,  0x002f15, 0xffffff, ' ')
    buffer.drawText(89, 26, 0xffffff, "Крутить")
    buffer.drawText(90, 30, 0xffffff, "Выход")
    buffer.drawText(50, 19, 0xffffff, "Красное")
    buffer.drawText(64, 19, 0xffffff, "Чёрное")
    buffer.drawText(4,  22, 0x000000, "Вывод:")
    buffer.drawText(76, 22, 0x000000, "Текущая валюта:")
    buffer.drawText(76, 23, 0xffffff, casino.getCurrency().name or "")
    buffer.drawChanges()
end

local function Roll()
    local current = math.random(1, 35)
    for i = 1, math.random(30, 50) do
        current = current + 1
        if (current == 38) then
            current = 1
        end
        drawNumber(4, 2, wheel[current + 4])
        drawNumber(4, 6, wheel[current + 3])
        drawNumber(4, 10, wheel[current + 2])
        drawNumber(4, 14, wheel[current + 1])
        drawNumber(4, 18, wheel[current])
        buffer.drawChanges()
        os.sleep(i / 140)
    end
    return wheel[current + 2]
end

local function getNumberClick(left, top)
    if (top == 5) or (top == 9) or (left % 7 == 4) then
        return 0
    end
    return (math.floor((left - 18) / 7) * 3) + math.floor(4 - (top - 1) / 4)
end

local function resetBets()
    bets = {}
    for i = 0, 36 do
        bets[i] = 0
    end
end

local function placeBet(number, money)
    if (bets[number] == nil) then
        bets[number] = money
    else
        bets[number] = bets[number] + money
    end
end

local function placeBetByTable(t, money)
    for i = 1, #t do
        placeBet(t[i], money)
    end
end

local function fixClicks(left, top) -- lol watta hell is this?
    return not (
        (left < 13) or (top < 2) or (left > 111) or (top > 20) or (left < 19 and top > 12) or (left == 18) or (left == 46) or (left == 102) or 
        (top == 12) or (top == 17) or (((left > 18) and (left < 102) and (top > 1) and (top < 13)) and getNumberClick(left, top) == 0) or 
        (top > 17 and top < 21 and (left == 32 or left == 46 or left == 60 or left == 74 or left == 88)) or (left > 101 and top > 12) or 
        (left > 102 and (top == 5 or top == 9)))
end

drawStatic()
message("")
while true do
    resetBets()
    local ready = false
    while true do
        local e, _, left, top, clickType, _ = event.pull("touch")
        if (e ~= nil) then
            local number, money = 0, 1 + clickType * 9
            if left >= 75 and left <= 110 and top >= 29 and top <= 31 then
                if ready then
                    message("Сначала завершите игру")
                else
                    error("Exit by request")
                end
            end
            if left >= 75 and left <= 110 and top >= 25 and top <= 27 then
                if ready then
                    break
                else
                    message("Недоступно до первой ставки")
                end
            end
            if (fixClicks(left, top)) then
                local payed, reason = casino.takeMoney(money)
                if payed then
                    ready = true
                    if (left > 18) and (left < 102) and (top > 1) and (top < 13) then
                        number = getNumberClick(left, top)
                    end
                    if number > 0 then
                        placeBet(number, money * 36)
                        message("Вы поставили " .. money .. " на " .. number)
                    elseif (left > 12) and (left < 18) and (top > 1) and (top < 13) then
                        message("Вы поставили " .. money .. " на 0")
                        placeBet(0, money * 36)
                    elseif (left > 18) and (left < 46) and (top > 13) and (top < 17) then
                        message("Вы поставили " .. money .. " на первую 12")
                        money = money * 3
                        for i = 1, 12 do
                            placeBet(i, money)
                        end
                    elseif (left > 46) and (left < 74) and (top > 13) and (top < 17) then
                        message("Вы поставили " .. money .. " на вторую 12")
                        money = money * 3
                        for i = 13, 24 do
                            placeBet(i, money)
                        end
                    elseif (left > 74) and (left < 102) and (top > 13) and (top < 17) then
                        message("Вы поставили " .. money .. " на третью 12")
                        money = money * 3
                        for i = 25, 36 do
                            placeBet(i, money)
                        end
                    elseif (left > 18) and (left < 32) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на 1 до 18")
                        money = money * 2
                        for i = 1, 18 do
                            placeBet(i, money)
                        end
                    elseif (left > 32) and (left < 46) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на чётное")
                        money = money * 2
                        for i = 2, 36, 2 do
                            placeBet(i, money)
                        end
                    elseif (left > 46) and (left < 60) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на красное")
                        placeBetByTable(red, money * 2)
                    elseif (left > 60) and (left < 74) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на чёрное")
                        placeBetByTable(black, money * 2)
                    elseif (left > 74) and (left < 88) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на нечётное")
                        money = money * 2
                        for i = 1, 35, 2 do
                            placeBet(i, money)
                        end
                    elseif (left > 88) and (left < 102) and (top > 17) and (top < 21) then
                        message("Вы поставили " .. money .. " на 19 до 36")
                        money = money * 2
                        for i = 19, 36 do
                            placeBet(i, money)
                        end
                    elseif (left > 102) and (left < 112) and (top > 1) and (top < 5) then
                        message("Вы поставили " .. money .. " на 2к1 (верхний ряд)")
                        money = money * 3
                        for i = 3, 36, 3 do
                            placeBet(i, money)
                        end
                    elseif (left > 102) and (left < 112) and (top > 5) and (top < 9) then
                        message("Вы поставили " .. money .. " на 2к1 (средний ряд)")
                        money = money * 3
                        for i = 2, 35, 3 do
                            placeBet(i, money)
                        end
                    elseif (left > 102) and (left < 112) and (top > 9) and (top < 13) then
                        message("Вы поставили " .. money .. " на 2к1 (нижний ряд)")
                        money = money * 3
                        for i = 1, 34, 3 do
                            placeBet(i, money)
                        end
                    end
                else
                    message(reason)
                end
            end
        end
    end
    message("Колесо крутится... Сумма ставок на игру: " .. (function()
        local sum = 0
        for k, v in pairs(bets) do
            sum = sum + v
        end
        return sum / 36
    end)())
    local out = Roll()
    message("Выпало число " .. out .. " " .. getNumberPostfix(out))
    if bets[out] then
        casino.reward(bets[out])
        message("Вы выиграли " .. bets[out])
    end
    casino.gameIsOver()
end