local casino = require("casino")
local event = require("event")
local shell = require("shell")
local games
local image
local buffer

local repository = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino-NoVirtual/master"

local state = {
    title = "/warp casino",
    selection = 1;
}

local requiredDirectories = { "/lib/FormatModules", "/home/images/", "/home/images/games_logo", "/home/apps" }

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

local function drawStatic()
    casino.setResolution(160, 50)
    casino.drawRectangleWithCenterText(1, 1, 160, 5, state.title, 0x431148, 0xFFFFFF)
end

local function drawDynamic()
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

    casino.setBackground(0xFFFFFF)
    casino.writeCenter(133, 7, currentGame.title, 0x000000)
    casino.drawBigText(102, 9, 57, currentGame.description)
    casino.drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
end

local function initLauncher()
    for i = 1, #requiredDirectories do
        shell.execute("md " .. requiredDirectories[i])
    end
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

for i = 1, 5 do
    local e, _, x, y = event.pull("touch")
    if (e == "touch") then
        -- Left menu buttons
        if (x >= 2 and x <= 47 and y >= 7 and ((y - 2) % 4)) then
            local selection = math.floor((y - 3) / 4)
            if (selection <= #games) then
                state.selection = selection
                drawDynamic()
            end
        end
        if (x >= 51 and y >= 40 and x <= 100 and y <= 44) then
            local currentGame = games[state.selection]
            casino.downloadFile(repository .. "/apps/" .. currentGame.file, "/home/apps/" .. currentGame.file)
            local result, errorMsg = pcall(loadfile("/home/apps/" .. currentGame.file))
            drawStatic()
            drawDynamic()
        end
    end

end
