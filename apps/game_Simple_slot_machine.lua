local component = require("component")
local sm = require("slot_machine")
local image = require("image")
local buffer = require("doubleBuffering")
local shell = require("shell")
local casino = require("casino")
local gpu = component.gpu

local machine = sm.Machine:new()

local repository = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino-NoVirtual/master" -- TODO: remove line

local function initStaticData()
    local pre_symbols = {
        { "golden_apple", 1 },
        { "quartz", 2 },
        { "emerald", 3 },
        { "fish", 4 },
        { "tnt", 5 },
        { "creeper", 6 },
        { "diamond", 7 },
        { "uu_matter", 8 },
        { "crystal", 9 }
    }
    local imagesFolder = "/home/images/simple_slot_machine/"
    shell.execute("md " .. imagesFolder)
    machine.symbols = {}
    for i = 1, #pre_symbols do
        local symbol = sm.Symbol:new()
        local imgPath = imagesFolder .. pre_symbols[i][1] .. ".pic"
        local downloadUrl = repository .. "/home/images/simple_slot_machine/" .. pre_symbols[i][1] .. ".pic"
        casino.downloadFile(downloadUrl, imgPath)
        symbol.image = image.load(imgPath)
        symbol.name = pre_symbols[i][1]
        symbol.value = pre_symbols[i][2]
        machine.symbols[i] = symbol
    end
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
            buffer.drawImage(3 + j * 17, 5, columns[j][i].image)
        end
        buffer.drawChanges()
        os.sleep(0.2)
    end
end

initStaticData()
roll()
