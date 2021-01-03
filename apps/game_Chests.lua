local buffer = require("doubleBuffering")
local casino = require("casino")
local event = require("event")

local BET_VALUES = {1, 2, 3, 5, 10, 25}

local bet = 1
local game = false
local chests = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0}

local consoleLines = {}
for i = 1, 14 do consoleLines[i] = "" end

local function drawRightMenu()
    buffer.drawRectangle(67, 2, 21, 15, 0, 0, " ")
    buffer.drawText(67, 2, 0xAAAAAA, "Вывод:")
    for i = 1, #consoleLines do
        buffer.drawText(67, 2 + i, (15 - #consoleLines + i) * 0x111111,
                        consoleLines[i])
    end
    buffer.drawRectangle(67, 19, 21, 6, 0xFFFFFF, 0, " ")
    for i = 1, 6 do
        if bet == 7 - i then
            buffer.drawRectangle(67, 18 + i, 21, 1, 0xFF8A00, 0, " ")
        end
        buffer.drawText(77, 18 + i, 0, tostring(BET_VALUES[7 - i]))
    end
    buffer.drawChanges()
end

local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, tostring(msg))
    drawRightMenu()
end

local function drawChest(id, isOpen)
    local x, y = id % 3 * 20 + 5, math.floor(id / 3) * 10 + 3
    buffer.drawRectangle(x, y, 18, 9, 0x675233, 0, " ")
    buffer.drawRectangle(x + 2, y + 1, 14, 1, 0xA8772C, 0, " ")
    buffer.drawRectangle(x + 2, y + 3, 14, 5, 0xA8772C, 0, " ")
    buffer.drawRectangle(x + 8, y + 2, 2, 2, 0x707070, 0, " ")
    if isOpen then buffer.drawRectangle(x, y, 18, 2, 0xFFFFFF, 0, " ") end
end

local function drawChestContent(id)
    local content = tostring(chests[id])
    local x, y = id % 3 * 20 + 14 - math.floor(string.len(content) / 2),
                 math.floor(id / 3) * 10 + 8
    buffer.drawText(x, y, 0xFFFFFF, content)
end

local function getChestId(x, y)
    local x, y = x - 5, y - 3
    if x % 20 ~= 18 and x % 20 ~= 19 and y % 10 ~= 9 then
        return math.floor(x / 20) + (math.floor(y / 10) * 3)
    end
end

local function gameEnd(chest)
    drawChest(chest, true)
    for i = 0, 8 do drawChestContent(i) end
    buffer.drawChanges()
    local reward = chests[chest]
    message("Вы выиграли " .. reward)
    casino.reward(reward)
    casino.gameIsOver()
    game = false
end

local function gameStart()
    game = true
    message("Началась игра за " .. BET_VALUES[bet])
    -- В одном из сундуков может быть малая вероятность на джекпот и большая вероятность на 0 (для баланса)
    local jackpotChest = math.random(0, #chests)

    for i = 0, #chests do
        drawChest(i)
        if jackpotChest == i then
            if math.random(1, 11) == 1 then
                chests[i] = BET_VALUES[bet] * 10
            else
                chests[i] = 0
            end
        else
            -- В обычных сундуках от 0 до Ставка х2
            chests[i] = math.random(0, BET_VALUES[bet] * 2)
        end
    end
    buffer.drawChanges()
end

local function drawStatic()
    buffer.setResolution(89, 33)
    buffer.clear(0xBFBFBF)
    buffer.drawRectangle(3, 2, 85, 31, 0xFFFFFF, 0, " ")
    buffer.drawRectangle(65, 2, 2, 31, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(67, 17, 22, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(67, 25, 22, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(67, 29, 22, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(67, 26, 22, 3, 0xc7ffc6, 0, " ")
    buffer.drawRectangle(67, 30, 22, 3, 0xffc6c6, 0, " ")
    buffer.drawText(74, 18, 0, 'Ставка')
    buffer.drawText(75, 27, 0, 'Играть')
    buffer.drawText(75, 31, 0, 'Выход')
    buffer.drawChanges()
end

drawStatic()
drawRightMenu()
buffer.drawChanges()

for id = 0, 8 do drawChest(id) end
buffer.drawChanges()

while true do
    local _, _, x, y = event.pull("touch")

    if x >= 5 and x <= 62 and y >= 3 and y <= 31 then
        if not game then
            message("Начните игру")
        else
            local chest = getChestId(x, y)
            if chest ~= nil then gameEnd(chest) end
        end
    end

    -- Right menu buttons
    if x >= 67 and x <= 87 then
        if game then
            message("Выберите сундук")
        else
            -- Bet buttons
            if y >= 19 and y <= 24 then
                local new_bet = 25 - y
                if new_bet ~= bet then
                    bet = new_bet
                    drawRightMenu()
                end
            end
            -- Play button
            if y >= 26 and y <= 28 then
                local payed, reason = casino.takeMoney(BET_VALUES[bet])
                if payed then
                    gameStart()
                else
                    message(reason)
                end
            end
            -- Exit button
            if y >= 30 and y <= 32 then error("Exit by request") end
        end
    end
end
