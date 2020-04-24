local component = require("component")
local term = require("term")
local gpu = component.gpu
local unicode = require("unicode")

gpu.setForeground(0xffffff)

local player = "krovyak"

function drawCheck(nick)
    money_of_player = Connector:get(nick)
    gpu.setBackground(0x000000)
    gpu.fill(3, 2, 28, 14, " ")
    gpu.set(17 - math.floor(unicode.len(nick) / 2), 6, nick)
    gpu.set(7, 7, "   На вашем счету ")
    gpu.set(16 - math.floor(unicode.len(money_of_player .. '') / 2), 8, money_of_player .. '')
    gpu.set(6, 9, "      дюрексиков ")
    gpu.setBackground(0xaa0000)
    gpu.fill(3, 13, 28, 3, " ")
    gpu.set(9, 14, "Проверить баланс")
    gpu.setBackground(0x800080)
    gpu.set(25, 2, "Лакеры")
    gpu.set(3, 2, "Анлакеры")
end

function drawTop()
    local tbl = Connector:top()
    gpu.setBackground(0x000000)
    gpu.fill(3, 2, 28, 14, " ")
    gpu.set(4, 3, "Топ лакерков в казино:")
    for i = 1, 10 do
        if not tbl[i] then
            break
        end
        gpu.set(4, 3 + i, i .. ". " .. tbl[i][1] .. " " .. math.floor(tbl[i][2]) .. " дюр")
    end
    os.sleep(4)
    drawCheck(player)
end

function drawBottom()
    local tbl = Connector:top()
    gpu.setBackground(0x000000)
    gpu.fill(3, 2, 28, 14, " ")
    gpu.set(4, 3, "Топ анлакеров в казино:")
    for i = 1, 10 do
        if not tbl[i] then
            break
        end
        gpu.set(4, 3 + i, i .. ". " .. tbl[#tbl - i + 1][1] .. " " .. math.floor(tbl[#tbl - i + 1][2]) .. " дюр")
    end
    os.sleep(10)
    drawCheck(player)
end

gpu.setResolution(32, 16)
gpu.setBackground(0xa0a0a0)
term.clear()
drawCheck(player)
while true do
    local _, _, left, top, _, p = event.pull("touch")

    if (top > 12) then
        player = p
        drawCheck(p)
    end
    if (top == 2) then
        if (left < 11) then
            drawBottom()
        elseif (left > 24) then
            drawTop()
        end
    end
end

