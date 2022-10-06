local component = require("component")
local event = require("event")
local term = require("term")
local gpu = component.gpu
local unicode = require("unicode")
local io = require('io')
local dragging, game, player, lastx, lasty, ending, cooldown, flag = false, false, "", 0, 0, 0, 0, true
local map, start, finish, currentPos = {}, { 1, 17 }, { 35, 17 }, { 1, 17 }

local casino = require("casino")

local file = io.open('snake-cooldown', 'r')
if (file) then
    cooldown = tonumber(file:read("*a"))
    file:close();
end

function startGenerate()
    for i = 1, 35 do
        map[i] = {}
        for j = 1, 35 do
            if (i % 2 ~= 0 and j % 2 ~= 0) then
                map[i][j] = 1
            else
                map[i][j] = 0
            end
        end
    end
end

function generateMap()
    flag = true
    startGenerate()
    goToRandPlace(finish[1], finish[2])
end
function isSize(size, x, y)
    if (size == 1) then
        if (x > 1) and map[x - 2][y] == 1 then
            map[x - 1][y] = 2
            return true
        end
    elseif (size == 2) then
        if (y > 1) and map[x][y - 2] == 1 then
            map[x][y - 1] = 2
            return true
        end
    elseif (size == 3) then
        if (x < 35) and map[x + 2][y] == 1 then
            map[x + 1][y] = 2
            return true
        end
    elseif (size == 4) then
        if (y < 35) and map[x][y + 2] == 1 then
            map[x][y + 1] = 2
            return true
        end
    end
    return false
end
function nextSize(size, rand)
    if (rand == 1) then
        if (size < 4) then
            return size + 1
        else
            return 1
        end
    else
        if (size > 1) then
            return size - 1
        else
            return 4
        end
    end
end
function goToRandPlaceTemp(x, y, count)
    map[x][y] = 2
    if (count < 1) then
        return
    end
    local size = math.random(1, 4)
    local rand = math.random(1, 2)
    for i = 1, 4 do
        if (isSize(size, x, y)) then
            if (size == 1) then
                goToRandPlaceTemp(x - 2, y, count - 1)
            elseif (size == 2) then
                goToRandPlaceTemp(x, y - 2, count - 1)
            elseif (size == 3) then
                goToRandPlaceTemp(x + 2, y, count - 1)
            elseif (size == 4) then
                goToRandPlaceTemp(x, y + 2, count - 1)
            end
        else
            size = nextSize(size, rand)
        end
    end
end
function goToRandPlace(x, y)
    if (flag) then
        map[x][y] = 3
    else
        map[x][y] = 2
    end
    if (x == start[1] and y == start[2]) then
        local count = math.random(5, 15)
        local times = 5
        while times > 0 do
            local xRand = math.random(1, 35)
            local yRand = math.random(1, 35)

            if (map[xRand][yRand] == 3) then
                times = times - 1
                goToRandPlaceTemp(xRand, yRand, count)
            end
        end
    else
        local size = math.random(1, 4)
        local rand = math.random(1, 2)
        for i = 1, 4 do
            if (isSize(size, x, y)) then
                if (size == 1) then
                    goToRandPlace(x - 2, y)
                elseif (size == 2) then
                    goToRandPlace(x, y - 2)
                elseif (size == 3) then
                    goToRandPlace(x + 2, y)
                elseif (size == 4) then
                    goToRandPlace(x, y + 2)
                end
            else
                size = nextSize(size, rand)
            end
        end
    end
end
function setGame(status)
    game = status
    gpu.setForeground(0x000000)
    if (game) then
        gpu.setBackground(0xd69b8b)
        gpu.fill(81, 33, 34, 5, " ")
        gpu.set(98 - math.floor((12 + string.len(player)) / 2), 35, "Идёт игра у " .. player)
        Log(player .. " начал игру")
    else
        gpu.setBackground(0x90ee90)
        gpu.fill(81, 33, 34, 5, " ")
        gpu.set(95, 35, "Играть")
    end
    gpu.setBackground(0x990000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(81, 27, 34, 5, " ")
    gpu.set(95, 29, "Выход")
    gpu.setForeground(0x000000)
end
local loglist = { "", "", "", "", "", "", "", "", "", "", "" }
function Log(message)
    loglist[10] = unicode.sub(message .. "                                  ", 1, 34)
    gpu.setBackground(0xdddddd)
    for i = 1, 9 do
        loglist[i] = loglist[i + 1]
        gpu.set(81, 16 + i, loglist[i])
    end
end

function drag(left, top)
    local x, y = math.floor((left - 3) / 2), (top - 2)
    if (x < 1) or (x > 35) or (y < 1) or (y > 35) then
        lose("ушёл за поле")
        return
    end
    if (map[x][y] == 0) then
        lose("задел край")
    end
    if (x == finish[1]) and (y == finish[2]) then
        win()
    end
    drawPoint(x, y, 0xd1a926)
    map[x][y] = 2
end
function drawPoint(x, y, color)
    gpu.setBackground(color)
    gpu.fill(3 + x * 2, 2 + y, 2, 1, " ")
    if (game) then
        if math.abs(x - lastx) > 2 then
            lose("поторопился")
        end
        if math.abs(y - lasty) > 2 then
            lose("поторопился")
        end
    end

    lastx = x
    lasty = y
end
function drawField()
    generateMap()
    gpu.setBackground(0x03511a)
    gpu.fill(5, 3, 70, 35, " ")
    a = emptyarray()
    currentPos = { 1, 17 }
    for i = 1, 35 do
        for j = 1, 35 do
            if map[i][j] == 3 then
                map[i][j] = 2
            end
        end
    end
    map[start[1]][start[2]] = 3
    map[finish[1]][finish[2]] = 4
    for x = 1, 35 do
        for y = 1, 35 do
            if (map[x][y] == 2 or map[x][y] == 1) then
                drawPoint(x, y, 0x25d258)
            end
            if (map[x][y] == 3) then
                drawPoint(x, y, 0xd1a926)
            end
            if (map[x][y] == 4) then
                drawPoint(x, y, 0xc2ff7d)
            end
        end
    end
end
function lose(message)
    dragging = false
    setGame(false)
    Log(player .. " " .. message)
end
function win()
    dragging = false
    setGame(false)
    casino.reward(1)
    Log(player .. " победил. : ")
end

gpu.setResolution(118, 39)
gpu.setBackground(0xe0e0e0)
term.clear()
gpu.setBackground(0xffffff)
gpu.fill(3, 2, 74, 37, " ")
gpu.fill(79, 2, 38, 37, " ")
gpu.setBackground(0xdddddd)
gpu.fill(81, 17, 34, 9, " ")
gpu.setBackground(0xffffff)
gpu.setForeground(0x0000ff)
gpu.set(80, 2, "Правила игры:")
gpu.set(80, 11, "Цена и награда:")
gpu.setForeground(0xaaaaaa)
gpu.set(80, 3, "Необходимо добраться с левой точки")
gpu.set(80, 4, "до правой через лабиринт. Время")
gpu.set(80, 5, "ограничено 60-ю секундами.")
gpu.set(80, 6, " - Нельзя отпускать мышь")
gpu.set(80, 7, ' - Нельзя "телепортироваться"')
gpu.set(80, 8, " - Нельзя задевать стены")
gpu.set(80, 9, " - Нельзя выходить за поле")
gpu.set(80, 12, "Игра абсолютно БЕСПЛАТНАЯ.")
gpu.set(80, 13, "В случае успеха, награда 1 эм.")
gpu.set(80, 14, "Независимо от исхода игры, кулдаун")
gpu.set(80, 15, "игры одна серверная минута.")
function emptyarray()
    local arr = {}
    for i = 1, 36 do
        arr[i] = {}
        for j = 1, 36 do
            arr[i][j] = 0
        end
    end
    return arr
end
local a = emptyarray()
setGame(false)
drawField(false)
if (cooldown > (os.time() + 4320)) then
    cooldown = os.time();
end
while true do
    while (cooldown - os.time()) >= 0 do
        gpu.setBackground(0xaaaaaa)
        gpu.fill(81, 33, 34, 5, " ")
        gpu.set(91, 35, "Кулдаун " .. math.floor((cooldown - os.time()) / 72) .. " с.")
        local e, _, left, top, _, p = event.pull(1, "touch")
        if e and (left > 80) and (left < 115) and (top > 27) and (top < 32) then
            error("Exit by request")
        end
    end
    setGame(false)
    local e, _, left, top, _, p = event.pull("touch")
    if (left > 80) and (left < 115) and (top > 32) and (top < 38) then
        ending = os.time() + 4320
        player = p
        drawField(true)
        setGame(true)
    end
    if (left > 80) and (left < 115) and (top > 27) and (top < 32) then
        error("Exit by request")
    end
    while game do
        local e, _, left, top, _, p2 = event.pullMultiple(1, "touch", "drag", "drop")
        if (os.time() >= ending) then
            lose("не успел")
        end
        if (player == p2) then
            if ((e == "touch") or (e == "drop")) and (dragging) then
                lose("отпустил мышь")
            end
            if (e == "touch") and ((left == 5) or (left == 6)) and (top == 19) then
                lastx, lasty = math.floor((left - 3) / 2), (top - 2)
                dragging = true
            end
            if (e == "drag") and (dragging) then
                drag(left, top)
            end
        end

        if (not game) then
            cooldown = os.time() + 4320
            p = nil
            dragging = false
            file = io.open('snake-cooldown', 'w')
            file:write(cooldown)
            file:close();
        end
    end
    if (p == nil) then
        setGame(false)
    end
end