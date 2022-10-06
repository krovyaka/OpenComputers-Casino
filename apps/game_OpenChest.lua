local component = require("component")
local term = require("term")
local gpu = component.gpu
local event = require("event")
local casino = require("casino")
local io = require('io')
local serialization = require('serialization')
local items, login, player, selectors, page, countOfChests, chanceCount = {}, false, 'p', {}, 1, 1, 0
local exitButtonName = 'Выход'
local price = 15
local consoleLines = {}
for i = 1, 13 do
    consoleLines[i] = ""
end

local phraces = {
    "Выкладываю вещи в сундуки",
    "Подкручиваю шансы",
    "Забираю все ценные призы",
    "Гадаю по лунному гороскопу",
    "Отправил запрос богу азарта",
    "Лунная призма дай мне силу",
    "Зову модера что б забанил вас"
}

local function getSelectorByCords(x, y)
    for index, selObj in pairs(selectors) do
        if (selObj.x == x and selObj.y == y) then
            return selObj
        end
    end
end

local function customizeSelectors()
    local file = io.open('selectors.cfg', 'r')
    selectors = serialization.unserialize(file:read(999999))
    file:close()
    for index, sel in pairs(selectors) do
        sel.selector = component.proxy(sel.componentAddress)
    end
end

local function drawRightMenu()
    gpu.setBackground(login and 0x613C3C or 0x990000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(41, 17, 28, 3, ' ')
    gpu.set(49, 18, exitButtonName)
    gpu.setBackground(0x000000)
    gpu.setForeground(0xAAAAAA)
    gpu.fill(41, 2, 28, 14, " ")
    gpu.set(42, 2, "Вывод:")
    for i = 1, #consoleLines do
        gpu.setForeground((15 - #consoleLines + i) * 0x111111)
        gpu.set(42, 16 - i, consoleLines[i])
    end
end

local function changeExitButton(btnName)
    exitButtonName = btnName
    drawRightMenu()
end


local function message(msg)
    table.remove(consoleLines, 1)
    table.insert(consoleLines, msg)
    drawRightMenu()
end

local function getRandColor()
    local r = math.random(0, 0xff)
    local g = math.random(0, 0xff)
    local b = math.random(0, 0xff)
    local background = r * 16 * 16 * 16 * 16 + g * 16 * 16 + b
    local foreground = (r + 88) % 0xff * 16 * 16 * 16 * 16 + (g + 88) % 0xff * 16 * 16 + (b + 88) % 0xff
    local colors = {}
    colors.background = background
    colors.foreground = foreground
    return colors
end

local function between(number, left, right)
    return (number >= left and number <= right)
end

local function openItem(selectorX, selectorY, slotX, slotY)
    local selObj = getSelectorByCords(selectorX, selectorY)
    local slotNum = (slotY - 1) * 3 + slotX
    local item = selObj.items[slotNum].item
    if (selObj.items[slotNum].isOpen) then
        message('Сундук уже открыт')
        return false
    end
    selObj.items[slotNum].isOpen = true
    selObj.selector.setSlot(slotNum, item)
    message("Приз: " .. item.name)
    if (not casino.rewardItem(item.id, item.dmg, item.count)) then
        message("Вещи нет в наличие")
        casino.rewardManually(player, item.id, item.dmg, 1)
    end
    gpu.setBackground(selObj.colors[slotX][slotY].background)
    gpu.setForeground(selObj.colors[slotX][slotY].foreground)
    gpu.set((5 + 2 * slotX + ((selectorX - 1) * 8)), 1 + slotY + ((selectorY - 1) * 4), '<')
    gpu.set((6 + 2 * slotX + ((selectorX - 1) * 8)), 1 + slotY + ((selectorY - 1) * 4), '>')
    return true
end

local function drawCountOfChest(count)
    gpu.setBackground(0xe0e0e0)
    gpu.setForeground(0x000000)
    gpu.set(7, 18, 'Осталось сундуков: ' .. count .. '   ')
end

local function drawGame()
    gpu.setBackground(0xe0e0e0)
    gpu.fill(3, 2, 38, 20, ' ')
    gpu.setBackground(0xffffff)
    gpu.setForeground(0xaa0000)
    for i = 1, 4 do
        for j = 1, 4 do
            for k = 1, 3 do
                for l = 1, 3 do
                    local colors = getRandColor()
                    getSelectorByCords(i, j).colors[k][l] = colors
                    gpu.setBackground(colors.background)
                    gpu.setForeground(colors.foreground)
                    gpu.set((5 + 2 * k + ((i - 1) * 8)), 1 + l + ((j - 1) * 4), ' ')
                    gpu.set((6 + 2 * k + ((i - 1) * 8)), 1 + l + ((j - 1) * 4), ' ')
                end
            end
        end
    end
end

local function drawWaitingInverface()
    gpu.setBackground(0xe0e0e0)
    gpu.fill(3, 2, 38, 20, ' ')
    gpu.setForeground(0xaa0000)
    local randIndex = math.random(1, #phraces)
    gpu.set(15, 9, "Загрузка ...")
    gpu.set(10, 10, phraces[randIndex])
end

local function initializeDatabaseItems()
    local file = io.open('lib/items.cfg', 'r')
    items = serialization.unserialize(file:read(999999))
    for index, item in pairs(items) do
        chanceCount = chanceCount + item.chance
    end
    file:close()
end

local function getItemByChance(index)
    for i=1,#items do
        index = index - items[i].chance
        if (index <= 0) then
            return items[i]
        end
    end
end

local function drawSelectors()
    local counter = 2
    for index, selObj in pairs(selectors) do
        counter = counter + 1
        if (counter == 3) then
            counter = 0
            drawWaitingInverface()
        end
        for i = 1, 9 do
            local randIndex = math.random(1, chanceCount)
            selObj.items[i] = {}
            selObj.items[i].item = getItemByChance(randIndex)
            selObj.items[i].isOpen = false
            selObj.selector.setSlot(i, { id = "minecraft:chest" })
        end
    end
end

local counts = { 1, 2, 3, 5, 10, 15, 20, 25, 50, 99 }

local function drawItems(page)
    gpu.setBackground(0xa0a0a0)
    gpu.setForeground(0xffffff)
    gpu.fill(4, 2, 34, 14, ' ')
    gpu.set(4, 2, 'Предмет')
    gpu.set(28, 2, 'Кол.')
    gpu.set(33, 2, 'Шанс')
    gpu.setBackground(0xb0b0b0)
    gpu.fill(4, 3, 34, 13, ' ')
    gpu.setForeground(0x000000)
    for i = 1, 13 do
        local item = items[(page - 1) * 13 + i]
        if (not item) then
            break
        end
        gpu.setForeground(item.color)
        gpu.set(4, i + 2, item.name)
        gpu.set(28, i + 2, item.count .. '')
        gpu.set(33, i + 2, (math.floor((item.chance/chanceCount*10000)+0.5)/100)..'%')
    end
end

local function changeCountOfChests(value)
    --    gpu.fill(4, 17, 15, 3, ' ')
    countOfChests = value
    local removeSpaces = 0
    for i = 1, #counts / 2 do
        local text1 = counts[2 * i - 1] .. ''
        local text2 = counts[2 * i] .. ''
        if (text1 == value .. '') then
            gpu.setBackground(0x00a000)
        else
            gpu.setBackground(0xa0a0a0)
        end
        gpu.setForeground(0xffffff)
        gpu.set(1 + i * 3 - removeSpaces, 17, text1)
        if (text2 == value .. '') then
            gpu.setBackground(0x00a000)
        else
            gpu.setBackground(0xa0a0a0)
        end
        gpu.set(1 + i * 3 - removeSpaces, 19, text2)
        if (string.len(text1) == 1) then
            removeSpaces = removeSpaces + 1
        end
    end

    gpu.setForeground(0xe0e0e0)
    gpu.setBackground(0x000000)
    gpu.fill(17, 17, 8, 3, ' ')
    gpu.set(19, 17, 'Цена')
    gpu.set(19, 18, countOfChests * price .. '')
    gpu.set(20, 19, 'эм')
end

local function drawDisplay()
    casino.gameIsOver()
    gpu.setBackground(0xe0e0e0)
    term.clear()
    changeExitButton("Выход")
    page = 1
    drawItems(page)
    changeCountOfChests(counts[1])

    gpu.setForeground(0xffffff)
    gpu.setBackground(0x00aa00)
    gpu.fill(26, 17, 12, 3, ' ')
    gpu.set(29, 18, 'Начать')
end

local function showAllItems()
    for i = 1, 4 do
        for j = 1, 4 do
            for k = 1, 3 do
                for l = 1, 3 do
                    local selObj = getSelectorByCords(i, j)
                    local slotNum = (k - 1) * 3 + l
                    local item = selObj.items[slotNum].item
                    selObj.selector.setSlot(slotNum, item)
                end
            end
        end
    end
end

local function startGame(count)
    changeExitButton("Показать призы")
    drawWaitingInverface()
    drawSelectors()
    drawGame()
    drawCountOfChest(count)

    local showedAllItems = false
    while true do
        local e, _, x, y, _, p = event.pull("touch")
        local selectorX = math.floor((x - 7) / 8 + 1)
        local selectorY = math.floor((y - 2) / 4 + 1)

        local slotX = math.floor(((x - 7) % 8) / 2 + 1)
        local slotY = (y - 2) % 4 + 1

        if (between(selectorX, 1, 4) and between(selectorY, 1, 4) and between(slotX, 1, 3) and between(slotY, 1, 3)) then
            if (count > 0) then
                if (openItem(selectorX, selectorY, slotX, slotY)) then
                    count = count - 1
                    drawCountOfChest(count)
                end
            else
                message("У вас нету сундуков")
            end
        elseif x >= 41 and x <= 69 and y >= 17 and y <= 19 then
            if (count > 0) then
                message("Используйте все сундуки")
            elseif (not showedAllItems) then
                showedAllItems = true
                changeExitButton("Выход")
                showAllItems()
            else
                break
            end
        end
    end


    drawDisplay()
end

initializeDatabaseItems()
customizeSelectors()
gpu.setResolution(70, 20)
drawDisplay()

while true do
    local e, _, x, y, _, p = event.pull(4, "touch")
    player = p
    if (p) then
        if (x >= 25 and x <= 37 and y >= 17 and y <= 20) then
            local bool, msg = casino.takeMoney(countOfChests * price)
            if (bool) then
                startGame(countOfChests)
            else
                message(msg)
            end
        elseif (x == 4 and y == 17) then
            changeCountOfChests(counts[1])
        elseif (x == 4 and y == 19) then
            changeCountOfChests(counts[2])
        elseif (x == 6 and y == 17) then
            changeCountOfChests(counts[3])
        elseif (x == 6 and y == 19) then
            changeCountOfChests(counts[4])
        elseif (x >= 8 and x <= 9 and y == 17) then
            changeCountOfChests(counts[5])
        elseif (x >= 8 and x <= 9 and y == 19) then
            changeCountOfChests(counts[6])
        elseif (x >= 11 and x <= 12 and y == 17) then
            changeCountOfChests(counts[7])
        elseif (x >= 11 and x <= 12 and y == 19) then
            changeCountOfChests(counts[8])
        elseif (x >= 14 and x <= 15 and y == 17) then
            changeCountOfChests(counts[9])
        elseif (x >= 14 and x <= 15 and y == 19) then
            changeCountOfChests(counts[10])
        elseif x >= 41 and x <= 69 and y >= 17 and y <= 19 then
            error("Exit by request")
        end
    else
        if ((#items) / (page * 13) > 1) then
            page = page + 1
        else
            page = 1
        end
        drawItems(page)
    end
end