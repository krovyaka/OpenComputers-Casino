local sm = require("slot_machine")
local image = require("image")
local buffer = require("doubleBuffering")
local shell = require("shell")
local casino = require("casino")
local event = require("event")

local machine = sm.Machine:new()
local bet = 1

local consoleLines = {}
for i = 1, 11 do
    consoleLines[i] = ""
end

local function drawRightMenu()
    buffer.drawRectangle(63, 2, 21, 12, 0, 0, " ")
    buffer.drawText(63, 2, 0xAAAAAA, "Вывод:")
    for i = 1, #consoleLines do
        buffer.drawText(63, 2 + i, (15 - #consoleLines + i) * 0x111111, consoleLines[i])
    end
    buffer.drawRectangle(63, 16, 21, 6, 0xFFFFFF, 0, " ")
    for i = 1, 6 do
        if bet == 7 - i then
            buffer.drawRectangle(63, 15 + i, 21, 1, 0xFF8A00, 0, " ")
        end
        buffer.drawText(73, 15 + i, 0, tostring(7 - i))
    end
    buffer.drawChanges()
end

local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, tostring(msg))
    drawRightMenu()
end

local function initStaticData()
    local pre_symbols = {
        { "fish", 5, "Фугу" },
        { "cookie", 5, "Печенье" },
        { "quartz", 5, "Кристалл истинного кварца" },
        { "emerald", 10, "Изумруд" },
        { "crystal", 10, "Лазутроновый кристалл" },
        { "golden_apple", 20, "Золотое яблоко" },
        { "diamond", 50, "Алмаз" },
        { "uu_matter", 100, "Материя" },
        { "creeper", 200, "Голова крипера" }
    }
    local imagesFolder = "/home/images/one_armed_creeper/"
    shell.execute("md " .. imagesFolder)
    machine.symbols = {}
    for i = 1, #pre_symbols do
        local symbol = sm.Symbol:new()
        local imgPath = imagesFolder .. pre_symbols[i][1] .. ".pic"
        local downloadUrl = REPOSITORY .. "/resources/images/one_armed_creeper/" .. pre_symbols[i][1] .. ".pic"
        casino.downloadFile(downloadUrl, imgPath)
        symbol.image = image.load(imgPath)
        symbol.name = pre_symbols[i][3]
        symbol.ratio = pre_symbols[i][2]
        machine.symbols[i] = symbol
    end
end

local function calculateRewardRatio(symbols)
    local a, b, c = symbols[1], symbols[2], symbols[3]
    if a == b and b == c then
        return a.ratio
    end
    if a == b or b == c then
        return 1
    end
    if a == c then
        return 2
    end
    return 0
end

local function roll()
    local result = {}
    local columns = {}
    local columnSize = #machine.symbols
    for i = 1, 3 do
        columns[i] = machine.rollColumn()
        result[i] = columns[i][columnSize]
    end
    for i = 1, columnSize do
        for j = 1, 3 do
            buffer.drawImage(-10 + j * 17, 4, columns[j][i].image)
        end
        buffer.drawChanges()
        os.sleep(0.2)
    end
    return result
end

local function drawRewards()
    buffer.drawText(6, 17, 0, "Пара смежных символов: " .. bet * 1 .. "  ")
    buffer.drawText(6, 18, 0, "Пара символов по краям: " .. bet * 2 .. "  ")
    local symbols = machine.symbols
    for i = 1, #symbols do
        buffer.drawText(7, 19 + i, 0, symbols[i].name .. ": " .. symbols[i].ratio * bet .. "  ")
    end
    buffer.drawChanges()
end

local function drawStatic()
    buffer.setResolution(85, 30)
    buffer.clear(0xBFBFBF)
    buffer.drawRectangle(3, 2, 81, 28, 0xFFFFFF, 0, " ")
    buffer.drawRectangle(61, 1, 2, 32, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(1, 14, 60, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(63, 14, 21, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(63, 22, 21, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(63, 26, 21, 1, 0xBFBFBF, 0, " ")
    buffer.drawRectangle(63, 23, 21, 3, 0xc7ffc6, 0, " ")
    buffer.drawRectangle(63, 27, 21, 3, 0xffc6c6, 0, " ")
    buffer.drawText(5, 16, 0, "Награды:")
    buffer.drawText(6, 19, 0, "Три символа в ряд:")
    buffer.drawText(70, 15, 0, 'Ставка')
    buffer.drawText(70, 24, 0, 'Играть')
    buffer.drawText(70, 28, 0, 'Выход')
    buffer.drawChanges()
end

initStaticData()
drawStatic()
drawRightMenu()
drawRewards()
for j = 1, 3 do
    buffer.drawImage(-10 + j * 17, 4, machine.symbols[#machine.symbols].image)
end
buffer.drawChanges()
while true do
    local _, _, x, y = event.pull("touch")
    -- Right menu buttons
    if x >= 63 and x <= 84 then
        -- Bet buttons
        if y >= 16 and y <= 21 then
            local new_bet = 22 - y
            if new_bet ~= bet then
                bet = new_bet
                drawRightMenu()
                drawRewards()
            end
        end
        -- Play button
        if y >= 23 and y <= 25 then
            local payed, reason = casino.takeMoney(bet)
            if payed then
                message("Вы поставили " .. bet)
                local ratio = calculateRewardRatio(roll())
                if ratio > 0 then
                    message("Вы выиграли " .. bet * ratio)
                    casino.reward(bet * ratio)
                else
                    message("Вы проиграли")
                end
                casino.gameIsOver()
            else
                message(reason)
            end
        end
        -- Exit button
        if y >= 27 and y <= 29 then
            error("Exit by request")
        end
    end
end
