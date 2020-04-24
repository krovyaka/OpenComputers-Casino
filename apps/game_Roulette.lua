local component = require("component")
local gpu = component.gpu
local term = require("term")
local event = require("event")
local casino = require("casino")

local consoleLines = { "", "", "", "", "", "", "", "", "" }

local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, msg)
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x002f15)
    gpu.fill(3, 23, 71, 9, ' ')
    for i = 1, #consoleLines do
        gpu.set(4, 32 - i, consoleLines[i])
    end
end

local values = { [0] = 'z', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'b', 'r', 'b', 'r', 'b', 'r', 'b', 'r' }
local wheel = { 0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26, 0, 32, 15, 19, 4, 21, 2, 25, 17 }
local red = { 1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36 }
local black = { 2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35 }

local function drawNumber(left, top, number)
    if (values[number] == 'r') then
        gpu.setBackground(0xff0000)
    elseif (values[number] == 'b') then
        gpu.setBackground(0x000000)
    else
        gpu.setBackground(0x00ff00)
    end
    gpu.fill(left, top, 6, 3, ' ')
    gpu.set(left + 2, top + 1, tostring(number))
end

local function getColor(number)
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

gpu.setResolution(112, 32)
gpu.setBackground(0xffffff)
term.clear()
gpu.setForeground(0x000000)
gpu.set(103, 14, "Ставки:")
gpu.set(103, 15, "ЛКМ 1$")
gpu.set(103, 16, "ПКМ 10$")
gpu.setForeground(0xffffff)
gpu.setBackground(0x00ff00)
gpu.fill(13, 2, 5, 11, ' ')
gpu.set(15, 7, "0")
for i = 1, 36 do
    drawNumber(19 + math.floor((i - 1) / 3) * 7, 2 + ((3 - i) % 3 * 4), i)
end
gpu.setBackground(0x34a513)
gpu.fill(103, 2, 9, 3, ' ')
gpu.fill(103, 6, 9, 3, ' ')
gpu.fill(103, 10, 9, 3, ' ')
gpu.set(106, 3, "2к1")
gpu.set(106, 7, "2к1")
gpu.set(106, 11, "2к1")
gpu.fill(19, 14, 27, 3, ' ')
gpu.fill(47, 14, 27, 3, ' ')
gpu.fill(75, 14, 27, 3, ' ')
gpu.set(28, 15, "первая 12")
gpu.set(56, 15, "вторая 12")
gpu.set(84, 15, "третья 12")
gpu.fill(19, 18, 13, 3, ' ')
gpu.fill(33, 18, 13, 3, ' ')
gpu.fill(75, 18, 13, 3, ' ')
gpu.fill(89, 18, 13, 3, ' ')
gpu.set(22, 19, "1 до 18")
gpu.set(38, 19, "Чёт")
gpu.set(79, 19, "Нечёт")
gpu.set(91, 19, "19 до 36")
gpu.setBackground(0xff0000)
gpu.fill(75, 29, 36, 3, ' ')
gpu.set(90, 30, "Выход")
gpu.fill(47, 18, 13, 3, ' ')
gpu.set(50, 19, "Красное")
gpu.setBackground(0xffb109)
gpu.fill(3, 2, 8, 19, ' ')
gpu.setBackground(0xffda54)
gpu.fill(3, 9, 8, 5, ' ')
gpu.setBackground(0x000000)
gpu.fill(61, 18, 13, 3, ' ')
gpu.set(64, 19, "Чёрное")
gpu.setBackground(0x002f15)
gpu.fill(3, 22, 71, 10, ' ')
gpu.setForeground(0xaaaaaa)
gpu.set(4, 22, "Вывод:")
gpu.setForeground(0xffffff)

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

local bets = {}
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

local function fixClicks(left, top)
    return not ((left < 13) or (top < 2) or (left > 111) or (top > 20) or (left < 19 and top > 12) or (left == 18) or (left == 46) or (left == 102) or (top == 12) or (top == 17) or (((left > 18) and (left < 102) and (top > 1) and (top < 13)) and getNumberClick(left, top) == 0) or (top > 17 and top < 21 and (left == 32 or left == 46 or left == 60 or left == 74 or left == 88)) or (left > 101 and top > 12) or (left > 102 and (top == 5 or top == 9)))
end

local endBets = 0

while true do
    resetBets()
    endBets = 0
    while endBets == 0 or (endBets > os.time()) do
        local e, _, left, top, clickType, _ = event.pull(3, "touch")
        if (e ~= nil) then
            local number, money = 0, 1 + clickType * 9
            if left >= 75 and left <= 110 and top >= 29 and top <= 31 and endBets == 0 then
                error("Exit by request")
            end
            if (fixClicks(left, top)) then
                if (casino.takeMoney(money)) then
                    if (endBets == 0) then
                        endBets = os.time() + 15 -- 1080
                        message("Рулетка крутится через 15 сек после первой ставки.")
                    end
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
                    message("У Вас недостаточно средств.")
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
    message("Выпало число " .. out .. " " .. getColor(out))
    if bets[out] then
        casino.reward(bets[out])
        message("Вы выиграли " .. bets[out])
    end
end