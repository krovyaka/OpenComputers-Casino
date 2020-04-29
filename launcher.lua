local casino = require("casino")
local event = require("event")
local shell = require("shell")
local games
local image
local buffer

event.shouldInterrupt = function()
    return false
end

local repository = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino-NoVirtual/master"

local state = {
    title = "Приветствуем вас, Котики ^_^. Эксклюзивно на /warp lol", -- TODO: Move to the config
    admins = { "krovyak", "Durex77" }, -- TODO: Move to the config
    selection = 1,
    devMode = false
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

local function isAdmin(player)
    for i = 1, #state.admins do
        if state.admins[i] == player then
            return true
        end
    end
    return false
end

local function drawStatic()
    casino.setResolution(160, 50)
    casino.drawRectangleWithCenterText(1, 1, 160, 5, state.title, 0x431148, 0xFFFFFF)

    if (state.devMode) then
        casino.writeCenter(158, 1, "{dev}", 0xE700FF)
        casino.writeCenter(160, 2, "X", 0xFF0000)
    else
        casino.writeCenter(158, 1, "{dev}", 0x78517C)
    end

    casino.drawRectangle(1, 6, 48, 45, 0xF2F2F2)
end

local function drawDynamic()
    local currentGame = games[state.selection]
    local imgPath = "/home/images/games_logo/" .. currentGame.image
    casino.drawRectangle(49, 6, 112, 45, 0xFFFFFF)
    casino.downloadFile(repository .. "/resources/images/games_logo/" .. currentGame.image, imgPath)
    buffer.flush()
    buffer.drawImage(51, 7, image.load(imgPath))  -- 50х32
    buffer.drawChanges()
    casino.setBackground(0xFFFFFF)
    casino.writeCenter(133, 7, currentGame.title, 0x000000)
    casino.drawBigText(102, 9, (currentGame.description or " ") .. "\n \n" .. "Разработчик: " .. currentGame.author)

    for i = 1, #games do
        if (currentGame == games[i]) then
            casino.drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xA890AA, 0x000000)
        else
            casino.drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xE3E3E3, 0x000000)
        end
    end

    if (state.devMode) then
        casino.drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
    else
        if currentGame.available then
            casino.drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
        else
            casino.drawRectangleWithCenterText(51, 40, 50, 5, "Временно недоступно", 0x433b44, 0xffffff)
        end
    end
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

while true do
    :: continue ::
    local e, _, x, y, _, p = event.pull("touch")
    if (e == "touch") then
        if state.devMode then
            if not isAdmin(p) then
                goto continue
            end
        end

        -- Left menu buttons
        if (x >= 2 and x <= 47 and y >= 7 and ((y - 2) % 4)) then
            local selection = math.floor((y - 3) / 4)
            if (selection <= #games) then
                state.selection = selection
                drawDynamic()
            end
        end

        -- Run/Update button
        if (x >= 51 and y >= 40 and x <= 100 and y <= 44) then
            local currentGame = games[state.selection]
            if state.devMode then
                casino.drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x5B5B5B, 0xffffff)
                casino.downloadFile(repository .. "/resources/images/games_logo/" .. currentGame.image, "/home/images/games_logo/" .. currentGame.image, true)
                casino.downloadFile(repository .. "/apps/" .. currentGame.file, "/home/apps/" .. currentGame.file, true)
                casino.drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
                drawDynamic()
            else
                if currentGame.available then
                    casino.downloadFile(repository .. "/apps/" .. currentGame.file, "/home/apps/" .. currentGame.file)
                    local result, errorMsg = pcall(loadfile("/home/apps/" .. currentGame.file))
                    drawStatic()
                    drawDynamic()
                end
            end
        end

        -- Dev mode button
        if x >= 157 and x <= 159 and y == 1 and isAdmin(p) then
            state.devMode = not state.devMode
            drawStatic()
            drawDynamic()
        end

        -- Reset button
        if x == 159 and y == 2 and state.devMode then
            casino.downloadFile(libs[6].url, libs[6].path, true)
            shell.execute("reboot")
        end
    end
end
