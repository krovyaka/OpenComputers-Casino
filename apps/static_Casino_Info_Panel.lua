local component = require("component")
local unicode = require("unicode")
local term = require("term")
local gpu = component.gpu

local COLORS = {
    ["0"] = 0x000000, ["1"] = 0x0000AA, ["2"] = 0x00AA00, ["3"] = 0x00AAAA,
    ["4"] = 0xAA0000, ["5"] = 0xAA00AA, ["6"] = 0xAAAA00, ["7"] = 0xAAAAAA,
    ["8"] = 0x505050, ["9"] = 0x5050FF, ["a"] = 0x50FF50, ["b"] = 0x50FFFF,
    ["c"] = 0xFF5050, ["d"] = 0xFF50FF, ["e"] = 0xFFFF50, ["f"] = 0xFFFFFF
}

local function formattedText(x, y, text)
    local textLen = unicode.len(text)
    local line = 0
    local left = 0
    local color = "f"
    local i = 0
    gpu.setForeground(COLORS[color])
    while i < textLen do
        i = i + 1
        local char = unicode.sub(text, i, i)
        local colorCode = char == "&" and unicode.sub(text, i + 1, i + 1)
        if COLORS[colorCode] then
            color = colorCode
            i = i + 1
            gpu.setForeground(COLORS[color])
        elseif char == "\n" then
            line = line + 1
            left = 0
        else
            gpu.set(x + left, y + line, char)
            left = left + 1
        end
    end
end

local howToPlay = [[
&aКак играть?
 &f1. Зайдите в кабинку и выберите игру.
 2. Положите в сундук необходимое количество валюты и играйте.
 &cБудьте внимательны и не пускайте посторонних игроков к себе в кабинку!

&aКак выбирать валюту?
 &fВ главном меню внизу обозначена текущая валюта. Нажатие на неё откроет выпадающий список,
 в котором можно выбрать иную валюту.

&aК кому обращаться с вопросами?
 &f1. krovyaka &3Discord: &bkrovyaka#2862 &3VK: &bvk.com/krovyaka
 &f2. Durex77  &3Discord: &bDurex77#2033

&aКак убедиться в честности казино?
 &fДанный варп одобрен старшим модераторским составом.
 При возникновении любых подозрений мы готовы предоставить любую необходимую информацию.

&aЧто в планах?
 &f1. Отображение текущей валюты в каждой игре, а не только в главном меню. &8(возможно выбор)
 &f2. Добавление большого количества слот-машин.
 &f3. Пробные игры без валюты.
]]

gpu.setResolution(100, 25)
gpu.setBackground(0)
term.clear()
formattedText(6, 3, howToPlay)
os.sleep(math.huge)
