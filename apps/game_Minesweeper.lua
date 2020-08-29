local component = require("component")
local gpu = component.gpu
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local casino = require("casino")

local bomb_count = 5 -- 6 мин = 40% на победу, 5 мин 47% на победу
local bets = { 1, 2, 3, 4, 5, 10, 16 }
local symb = string.rep(unicode.char(0xE0BF), 2)
local fields = {}
local game = false
local bet = 1
local attempts = 0

local field_types = {
    ["clear"] = 0x98df94,
    ["close"] = 0xd0d0d0,
    ["bomb"] = 0xff0000,
    ["close_bomb"] = 0xff0000,
}

local function getBombPos(x)
    return 5 + ((x - 1) % 6) * 12, 3 + math.floor((x - 1) / 6) * 6
end

local function drawField(x, f_type)
    gpu.setBackground(field_types[f_type])
    local pos_x, pos_y = getBombPos(x)
    gpu.fill(pos_x, pos_y, 10, 5, " ")
    if (f_type == "bomb") then
        gpu.setForeground(0)
        gpu.set(pos_x, pos_y + 0, symb .. "      " .. symb)
        gpu.set(pos_x, pos_y + 1, "  \\    /  ")
        gpu.set(pos_x, pos_y + 2, "    " .. symb .. "    ")
        gpu.set(pos_x, pos_y + 3, "  /    \\  ")
        gpu.set(pos_x, pos_y + 4, symb .. "      " .. symb)
    end
end

local animations = {
    ["load"] = function()
        for i = 1, 24 do
            drawField(i, "clear")
            os.sleep()
            drawField(i, "close")
        end
    end,

    ["reveal"] = function()
        for i = 0, 3 do
            for j = 1, 6 do
                drawField(j + i * 6, "clear")
            end
            os.sleep(0.1)
            for j = 1, 6 do
                if (fields[j + i * 6] == "close_bomb") then
                    drawField(j + i * 6, "bomb")
                else
                    drawField(j + i * 6, "close")
                end
            end
        end
        os.sleep(1)
        for i = 0, 3 do
            for j = 1, 6 do
                drawField(j + i * 6, "clear")
            end
            os.sleep(0.1)
            for j = 1, 6 do
                drawField(j + i * 6, "close")
            end
        end
    end,
    ["error"] = function()
        for i = 1, 2 do
            gpu.setBackground(0xff0000)
            gpu.setForeground(0xffffff)
            gpu.fill(58, 29, 17, 5, " ")
            gpu.set(61, 31, "Начать игру")
            os.sleep(0.1)
            gpu.setBackground(0x90ef7e)
            gpu.setForeground(0)
            gpu.fill(58, 29, 17, 5, " ")
            gpu.set(61, 31, "Начать игру")
            os.sleep(0.1)
        end
    end
}

local function generateFields()
    fields = {}
    for i = 1, 24 do
        fields[i] = "close"
    end
    local i = 0
    while i < bomb_count
    do
        local rand = math.random(1, 24)
        if (fields[rand] ~= "close_bomb") then
            fields[rand] = "close_bomb"
            i = i + 1
        end
    end
end

local function getBombId(left, top)
    if (((left - 3) % 12) == 0) or (((left - 4) % 12) == 0) or (((top - 2) % 6) == 0) then
        return 0
    end
    return (math.floor((top - 3) / 6) * 6) + math.floor((left + 7) / 12)
end

local function endGame()
    os.sleep(0.7)
    animations.reveal()
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x990000)
    gpu.fill(58, 35, 17, 3, " ")
    gpu.set(64, 36, "Выход")
    gpu.setBackground(0x90ef7e)
    gpu.setForeground(0)
    gpu.fill(58, 29, 17, 5, " ")
    gpu.set(61, 31, "Начать игру")
    game = false
    casino.gameIsOver()
end

local function drawBets()
    gpu.setForeground(0)
    for i = 0, #bets - 1 do
        gpu.setBackground(i == bet - 1 and 0x90ef7e or 0xd0d0d0)
        gpu.fill(5 + i * 7, 37, 5, 1, " ")
        gpu.set(7 + i * 7, 37, tostring(bets[i + 1]))
    end
end

local function handleFieldClick(top, left)
    local id = getBombId(left, top)
    if (id > 0) then
        if (fields[id] == "close") then
            drawField(id, "clear")
            fields[id] = "clear"
            attempts = attempts - 1
        end
        if (fields[id] == "close_bomb") then
            drawField(id, "bomb")
            endGame()
            return
        end
    end
    if (attempts == 0) then
        casino.reward(bets[bet] * 2)
        endGame()
        return
    end
end

gpu.setResolution(78, 39)
gpu.setBackground(0xe0e0e0)
term.clear()
gpu.setBackground(0xffffff)
gpu.fill(3, 2, 74, 37, " ")
gpu.setForeground(0x00a000)
gpu.set(4, 29, "Правила игры и награды:")
gpu.set(4, 35, "Ставка:")
gpu.setForeground(0x000000)
gpu.set(4, 30, "Начинайте игру и ищите поля без мин. Если 3 раза")
gpu.set(4, 31, "подряд не наткнулись на поле с миной, то вы")
gpu.set(4, 32, "победили. Всего в игре 24 поля, из которых 5 ")
gpu.set(4, 33, "заминированы. Победа в игре удваивает ставку. ")
gpu.setBackground(0xe0e0e0)
gpu.fill(1, 27, 76, 1, " ")
gpu.fill(54, 27, 2, 12, " ")
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x990000)
gpu.fill(58, 35, 17, 3, " ")
gpu.set(64, 36, "Выход")
gpu.setBackground(0x90ef7e)
gpu.setForeground(0)
gpu.fill(58, 29, 17, 5, " ")
gpu.set(61, 31, "Начать игру")
drawBets()
animations.load()
while true do
    local _, _, left, top = event.pull("touch")

    -- start game button
    if not game and left >= 58 and left <= 75 and top >= 29 and top <= 33 then
        local payed, reason = casino.takeMoney(bets[bet])
        if payed then
            generateFields()
            gpu.setBackground(0xffa500)
            gpu.fill(58, 29, 17, 5, " ")
            gpu.set(62, 31, "Идёт игра")
            gpu.setForeground(0xFFFFFF)
            gpu.setBackground(0x613C3C)
            gpu.fill(58, 35, 17, 3, " ")
            gpu.set(64, 36, "Выход")
            attempts = 3
            game = true
        else
            animations.error()
        end
    end

    -- exit button
    if not game and left >= 58 and left <= 75 and top >= 35 and top <= 37 then
        error("Exit by request")
    end

    -- game fields
    if game and left >= 5 and left <= 74 and top >= 2 and top <= 25 then
        handleFieldClick(top, left)
    end

    -- bet buttons
    if not game and top == 37 and left >= 5 and left <= 51 then
        if (left - 5) % 7 < 5 then
            bet = math.floor((left - 5) / 7) + 1
            drawBets()
        end
    end
end