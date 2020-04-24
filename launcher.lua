local casino = require("casino")
local games
local image
local buffer

local repository = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino-NoVirtual/master"

local state = {
    title = "/warp casino",
    selection = 1;
}

local libs = {
    {
        url = repository .. "/external/IgorTimofeev/AdvancedLua.lua",
        path = "/lib/advancedLua.lua"
    },
    {
        url = repository .. "/external/IgorTimofeev/Color.lua",
        path = "/lib/color.lua"
    },
    {
        url = repository .. "/external/IgorTimofeev/OCIF.lua",
        path = "/lib/FormatModules/OCIF.lua"
    },
    {
        url = repository .. "/external/IgorTimofeev/Image.lua",
        path = "/lib/image.lua"
    },
    {
        url = repository .. "/external/IgorTimofeev/DoubleBuffering.lua",
        path = "/lib/doubleBuffering.lua"
    },
    {
        url = repository .. "/games.lua",
        path = "/lib/games.lua"
    }
}

function drawStatic()
    casino.drawRectangleWithCenterText(1, 1, 160, 5, state.title, 0x431148, 0xffffff)
end

function drawDynamic()
    casino.drawRectangle(1, 6, 48, 45, 0xF2F2F2)
    casino.drawRectangle(49, 6, 112, 45, 0xFFFFFF)
    for i = 1, #games do
        if (games[i].available) then
            casino.drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xE3E3E3, 0x000000)
        end
    end

    local currentGame = games[state.selection]
    local imgPath = "/home/images/games_logo/" .. currentGame.image
    casino.downloadFile(repository .. "/resources/images/games_logo/" .. currentGame.image, imgPath)
    buffer.flush()
    buffer.drawImage(51, 7, image.load(imgPath))  -- 50х32
    buffer.drawChanges()

    casino.drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
end

function initLauncher()
    for i = 1, #libs do
        casino.downloadFile(libs[i].url, libs[i].path)
    end
    games = require("games")
    image = require("image")
    buffer = require("doubleBuffering")
end

initLauncher()
drawStatic()
drawDynamic()