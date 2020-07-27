local casino = require("casino")
local event = require("event")
local shell = require("shell")
local unicode = require("unicode")
local games
local currencies
local image
local buffer

event.shouldInterrupt = function()
    return false
end

REPOSITORY = "https://raw.githubusercontent.com/krovyaka/OpenComputers-Casino-NoVirtual/feature/Feature-MultiCurrency"

local state = {
    title = "Приветствуем вас, Котики ^_^. Эксклюзивно на /warp lol", -- TODO: Move to the config
    admins = { "krovyak", "Durex77" }, -- TODO: Move to the config
    selection = 1,
    devMode = false,
    currencyDropdown = false
}

local requiredDirectories = { "/lib/FormatModules", "/home/images/", "/home/images/games_logo", "/home/images/currencies", "/home/apps" }

local libs = {
    {
        url = REPOSITORY .. "/external/IgorTimofeev/AdvancedLua.lua",
        path = "/lib/advancedLua.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/Color.lua",
        path = "/lib/color.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/OCIF.lua",
        path = "/lib/FormatModules/OCIF.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/Image.lua",
        path = "/lib/image.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/DoubleBuffering.lua",
        path = "/lib/doubleBuffering.lua"
    },
    {
        url = REPOSITORY .. "/config/games.lua",
        path = "/lib/games.lua"
    },
    {
        url = REPOSITORY .. "/config/currencies.lua",
        path = "/lib/currencies.lua"
    },
    {
        url = REPOSITORY .. "/lib/slot_machine.lua",
        path = "/lib/slot_machine.lua"
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

local function writeCenter(x, y, text, color)
    buffer.drawText(math.floor(x - unicode.len(text) / 2), math.floor(y), color, text)
end

local function drawRectangleWithCenterText(x, y, width, height, text, bgColor, fgColor)
    buffer.drawRectangle(x, y, width, height, bgColor, 0, " ")
    writeCenter(width / 2 + x, height / 2 + y, text, fgColor)
end

local function drawBigText(x, y, text)
    if not text then
        return
    end
    local lines = casino.splitString(text, "\n")
    for i = 0, #lines - 1 do
        buffer.drawText(x, y + i, 0x000000, lines[i + 1])
    end
end

local function drawStatic()
    buffer.setResolution(160, 50)
    drawRectangleWithCenterText(1, 1, 160, 5, state.title, 0x431148, 0xFFFFFF)

    if (state.devMode) then
        writeCenter(158, 1, "{dev}", 0xE700FF)
        writeCenter(160, 2, "X", 0xFF0000)
    else
        writeCenter(158, 1, "{dev}", 0x78517C)
    end
    buffer.drawRectangle(1, 6, 48, 45, 0xF2F2F2, 0, " ")
    buffer.drawChanges()
end

local function drawDynamic()
    local currentGame = games[state.selection]
    local gameImgPath = "/home/images/games_logo/" .. currentGame.image
    buffer.drawRectangle(49, 6, 112, 45, 0xFFFFFF, 0, " ")
    buffer.drawRectangle(1, 6, 48, 45, 0xF2F2F2, 0, " ")
    casino.downloadFile(REPOSITORY .. "/resources/images/games_logo/" .. currentGame.image, gameImgPath)
    buffer.drawImage(51, 7, image.load(gameImgPath))  -- 50х32
    writeCenter(133, 7, currentGame.title, 0x000000)
    drawBigText(102, 9, (currentGame.description or " ") .. "\n \n" .. "Разработчик: " .. currentGame.author)

    for i = 1, #games do
        if (currentGame == games[i]) then
            drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xA890AA, 0x000000)
        else
            drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xE3E3E3, 0x000000)
        end
    end

    local currency = casino.getCurrency()
    local currencyImgFolder = "/home/images/currencies/"
    if state.currencyDropdown then
        for i = 1, #currencies do
            local y = 43 - 4 * (#currencies - i)
            local img = currencies[i].image
            casino.downloadFile(REPOSITORY .. "/resources/images/currencies/" .. img, currencyImgFolder .. img)
            buffer.drawImage(2, y, image.load(currencyImgFolder .. img))
        end
    end
    drawRectangleWithCenterText(2, 46, 46, 1, "Текущая валюта", 0x431148, 0xFFFFFF)
    buffer.drawRectangle(2, 47, 46, 3, 0xE3E3E3, 0, " ")
    casino.downloadFile(REPOSITORY .. "/resources/images/currencies/" .. currency.image, currencyImgFolder .. currency.image)
    buffer.drawImage(2, 47, image.load(currencyImgFolder .. currency.image))  -- 6x3

    if (state.devMode) then
        drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
    else
        if currentGame.available then
            drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
        else
            drawRectangleWithCenterText(51, 40, 50, 5, "Временно недоступно", 0x433b44, 0xffffff)
        end
    end
    buffer.drawChanges()
end

local function initLauncher()
    for i = 1, #requiredDirectories do
        shell.execute("md " .. requiredDirectories[i])
    end
    for i = 1, #libs do
        casino.downloadFile(libs[i].url, libs[i].path)
    end
    games = require("games")
    currencies = require("currencies")
    image = require("image")
    buffer = require("doubleBuffering")
    casino.setCurrency(currencies[1])
end

initLauncher()
buffer.flush()
drawStatic()
drawDynamic()

while true do
    :: continue ::
    local e, _, x, y, _, p = event.pull("touch")
    if (e == "touch") then
        if state.devMode and not isAdmin(p) then
            goto continue
        end

        -- Currency
        if state.currencyDropdown then
            state.currencyDropdown = false
            drawDynamic()
        elseif x >= 2 and y >= 46 and x <= 92 and y <= 50 then
            state.currencyDropdown = true
            drawDynamic()
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
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x5B5B5B, 0xffffff)
                buffer.drawChanges()
                casino.downloadFile(REPOSITORY .. "/resources/images/games_logo/" .. currentGame.image, "/home/images/games_logo/" .. currentGame.image, true)
                casino.downloadFile(REPOSITORY .. "/apps/" .. currentGame.file, "/home/apps/" .. currentGame.file, true)
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
                drawDynamic()
            else
                if currentGame.available then
                    casino.downloadFile(REPOSITORY .. "/apps/" .. currentGame.file, "/home/apps/" .. currentGame.file)
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
