local casino = require("casino")
local event = require("event")
local shell = require("shell")
local unicode = require("unicode")
local settings = require("settings")
local computer = require('computer')
local games
local currencies
local image
local buffer
local colorlib

REPOSITORY = settings.REPOSITORY

CURRENT_APP = nil
SHOULD_INTERRUPT = false

event.shouldInterrupt = function()
    if SHOULD_INTERRUPT then
        SHOULD_INTERRUPT = false
        if CURRENT_APP then
            CURRENT_APP = nil
            return true
        end
    end
    return false
end

local state = {
    selection = 1,
    devMode = false,
    currencyDropdown = false
}


local requiredDirectories = { "/lib/FormatModules", "/home/images/", "/home/images/games_logo", "/home/images/currencies", "/home/apps" }

local libs = {
    {
        url = REPOSITORY .. "/config/settings.lua",
        path = "/lib/settings.lua"
    },
    {
        url = REPOSITORY .. "/libs/casino.lua",
        path = "/lib/casino.lua"
    },
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
        url = REPOSITORY .. "/libs/slot_machine.lua",
        path = "/lib/slot_machine.lua"
    },
    {
        url = REPOSITORY .. "/config/openChestConfiguration.lua",
        path = "/lib/openChestConfiguration.lua"
    }
}

local function isAdmin(player)
    for i = 1, #settings.ADMINS do
        if settings.ADMINS[i] == player then
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

local function drawCurrency(x, y, currency, current)
    buffer.drawRectangle(x, y, 46, 3, --[[current and 0xA890AA or--]] 0xE3E3E3, 0, " ")
    buffer.drawText(x + 8, y    , 0, currency.name)
    buffer.drawText(x + 8, y + 1, 0, "Максимальная ставка: " .. (currency.max or "-"))
    buffer.drawText(x + 8, y + 2, 0, "У казино: " .. casino.getCurrencyInStorage(currency) .. " шт.")

    local color = currency.color or 0xE3E3E3
    local darkColor = colorlib.transition(color, 0, 0.1)
    if currency.model == 'INGOT' then
        buffer.drawSemiPixelLine(x, y * 2 + 1, x + 2, y * 2 + 1, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2, x + 5, y * 2, darkColor)
        buffer.drawSemiPixelLine(x, y * 2 + 2, x + 2, y * 2 + 2, color)
        buffer.drawSemiPixelLine(x + 3, y * 2 + 1, x + 5, y * 2 + 1, color)
        buffer.drawSemiPixelLine(x, y * 2 + 3, x + 2, y * 2 + 3, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2 + 2, x + 5, y * 2 + 2, darkColor)
    elseif currency.model == 'DUST' then
        buffer.drawSemiPixelRectangle(x + 2, y * 2 + 1, 3, 2, color)
        buffer.drawSemiPixelRectangle(x + 1, y * 2 + 3, 5, 1, color)
        buffer.drawSemiPixelLine(x, y * 2 + 3, x + 3, y * 2, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2, x + 6, y * 2 + 3, darkColor)
        buffer.drawSemiPixelLine(x + 1, y * 2 + 4, x + 5, y * 2 + 4, darkColor)
    elseif currency.model == 'BLOCK' then
        buffer.drawSemiPixelRectangle(x, y * 2 - 1, 6, 6, darkColor)
        buffer.drawSemiPixelRectangle(x + 1, y * 2, 4, 4, color)
    end

end

local function drawStatic()
    buffer.setResolution(160, 50)
    drawRectangleWithCenterText(1, 1, 160, 5, settings.TITLE, 0x431148, 0xFFFFFF)

    if (state.devMode) then
        writeCenter(158, 1, "{dev}", 0xE700FF)
        writeCenter(160, 2, "X", 0xFF0000)
        writeCenter(157, 3, "[LIBS]", 0xE700FF)
    else
        writeCenter(158, 1, "{dev}", 0x78517C)
    end
    buffer.drawRectangle(1, 6, 48, 45, 0xF2F2F2, 0, " ")
    buffer.drawChanges()
end

local function drawLibSettings()
    buffer.drawRectangle(49, 6, 112, 45, 0xFFFFFF, 0, " ")
    for i = 1, #libs do
        buffer.drawText(51, 5 + i * 2, 0x0000AA, "Скачать  Правка");
        buffer.drawText(68, 5 + i * 2, 0, libs[i].path);
    end
    buffer.drawText(51, 5 + (1 + #libs) * 2, 0xff0000, "При редактировании, компьютер не будет защищен от других игроков!");
    buffer.drawText(51, 6 + (1 + #libs) * 2, 0xff0000, "Изменения вступят в силу после перезагрузки!");
    buffer.drawChanges()
end

local function drawDynamic()
    if state.selection == 0 then
        drawLibSettings()
        return
    end
    local selection = games[state.selection]
    local gameImgPath = "/home/images/games_logo/" .. selection.image
    buffer.drawRectangle(49, 6, 112, 45, 0xFFFFFF, 0, " ")
    buffer.drawRectangle(1, 6, 48, 45, 0xF2F2F2, 0, " ")
    casino.downloadFile(REPOSITORY .. "/resources/images/games_logo/" .. selection.image, gameImgPath)
    buffer.drawImage(51, 7, image.load(gameImgPath))  -- 50х32
    writeCenter(133, 7, selection.title, 0x000000)
    drawBigText(102, 9, (selection.description or " ") .. "\n \n" .. "Разработчик: " .. selection.author)

    for i = 1, #games do
        local bgColor = selection == games[i] and 0xA890AA or 0xE3E3E3
        drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, bgColor, 0x000000)
    end

    local currentCurrency = casino.getCurrency()
    if state.currencyDropdown then
        local currencyLen = #currencies
        for i = 1, currencyLen do
            drawCurrency(2, 43 - 4 * (currencyLen - i), currencies[i], currencies[i] == currentCurrency)
        end
    end
    drawRectangleWithCenterText(2, 46, 46, 1, "Текущая валюта", 0x431148, 0xFFFFFF)
    drawCurrency(2, 47, currentCurrency)
    buffer.drawText(40, 48, 0, "Сменить")

    if (state.devMode) then
        drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
    else
        if selection.available then
            drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
        else
            drawRectangleWithCenterText(51, 40, 50, 5, "Временно недоступно", 0x433b44, 0xffffff)
        end
    end
    buffer.drawChanges()
end

local function removeUsers()
    local users = table.pack(computer.users())
    for i = 1, #users do
        if not isAdmin(users[i]) then
            computer.removeUser(users[i])
        end
    end
end

local function onPimPlayerOff(_, name)
    SHOULD_INTERRUPT = true
end

local function handlePim()
    if casino.container.getInventoryName() == 'pim' then
        removeUsers()
        casino.setCurrency(currencies[1])
        buffer.setResolution(32, 9)
        buffer.drawChanges()
        local frame = 0
        while casino.container.getInventoryName() == 'pim' do
            if frame < 25 then
                for i = 1, 5 do
                    frame = frame + 1
                    buffer.drawRectangle(1, 1, 32, 9, 0x000000, 0x0, ' ')
                    buffer.drawSemiPixelLine(frame * 3, 0, frame * 3 - 18, 18, 0xFFFFFF)
                    buffer.drawText(5, 3, 0x00FFFF, 'Наступите, чтобы начать')
                    buffer.drawText(15, 6, 0x00FFFF, ' ||')
                    buffer.drawText(15, 7, 0x00FFFF, ' ||')
                    buffer.drawText(15, 8, 0x00FFFF, '\\  /')
                    buffer.drawText(15, 9, 0x00FFFF, ' \\/')
                    buffer.drawChanges()
                    os.sleep(0.1)
                end
            else
                frame = frame + 5
                os.sleep(0.5)
            end
            if frame > 150 then
                frame = 0
            end
        end
        computer.addUser(casino.container.getInventoryName())
        buffer.drawRectangle(1, 1, 32, 9, 0xFFFFFF, 0x0, ' ')
        drawRectangleWithCenterText(1, 4, 32, 1, casino.container.getInventoryName(), 0xFFFFFF, 0x0)
        buffer.drawText(2, 6, 0xFF0000, 'Не покидайте PIM до конца игры')
        buffer.drawChanges()
        os.sleep(2)
        drawStatic()
        drawDynamic()
        buffer.drawChanges()
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
    currencies = require("currencies")
    image = require("image")
    buffer = require("doubleBuffering")
    colorlib = require("color")
    casino.setCurrency(currencies[1])
end

initLauncher()
buffer.flush()
drawStatic()
drawDynamic()

if settings.PAYMENT_METHOD == 'PIM' then event.listen('player_off', onPimPlayerOff) end

while true do
    :: continue :: -- В Lua отсутствует ключевое слово continiue
    local e, _, x, y, _, p = event.pull(1)
    if e == "touch" then
        if state.devMode and not isAdmin(p) then
            goto continue
        end

        -- Currency
        if state.currencyDropdown and state.selection > 0 then
            if x >= 2 and x <= 46 and  y % 4 ~= 2 then
                local currencyId = math.floor((y - (47 - 4 * #currencies)) / 4 + 1)
                if currencyId > 0 and currencyId <= #currencies then
                    casino.setCurrency(currencies[currencyId])
                end
            end
            state.currencyDropdown = false
            drawDynamic()
            goto continue
        elseif x >= 2 and y >= 46 and x <= 92 and y <= 50 and state.selection > 0 then
            state.currencyDropdown = true
            drawDynamic()
        end

        -- Left menu buttons
        if (x >= 2 and x <= 47 and y >= 7 and ((y - 2) % 4)) and state.selection > 0 then
            local selection = math.floor((y - 3) / 4)
            if (selection <= #games) then
                state.selection = selection
                drawDynamic()
            end
        end

        -- Run/Update button
        if (x >= 51 and y >= 40 and x <= 100 and y <= 44) and state.selection > 0 then
            local selection = games[state.selection]
            if state.devMode then
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x5B5B5B, 0xffffff)
                buffer.drawChanges()
                casino.downloadFile(REPOSITORY .. "/resources/images/games_logo/" .. selection.image, "/home/images/games_logo/" .. selection.image, true)
                casino.downloadFile(REPOSITORY .. "/apps/" .. selection.file, "/home/apps/" .. selection.file, true)
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
                drawDynamic()
            else
                if selection.available then
                    casino.downloadFile(REPOSITORY .. "/apps/" .. selection.file, "/home/apps/" .. selection.file)
                    CURRENT_APP = selection.title
                    local result, errorMsg = pcall(loadfile("/home/apps/" .. selection.file))
                    CURRENT_APP = nil
                    casino.gameIsOver()
                    drawStatic()
                    drawDynamic()
                end
            end
        end

        -- Lib buttons
        if state.devMode and state.selection == 0 and y >= 7 and y % 2 == 1 then
            local lib = libs[math.floor((y - 7) / 2) + 1]
            -- Download
            if lib and x >= 51 and x <= 57 then
                buffer.drawText(51, y, 0xAAAAAA, "Скачать");
                buffer.drawChanges()
                casino.downloadFile(lib.url, lib.path, true)
                buffer.drawText(51, y, 0x0000AA, "Скачать");
                buffer.drawChanges()
            end
            -- Edit
            if lib and x >= 60 and x <= 65 then
                local component = require("component")
                component.gpu.setBackground(0);
                component.gpu.setForeground(0xffffff);
                shell.execute("edit " .. lib.path)
                drawStatic()
                drawDynamic()
            end
        end

        -- Dev mode button
        if x >= 157 and y == 1 and isAdmin(p) then
            state.devMode = not state.devMode
            state.selection = 1
            drawStatic()
            drawDynamic()
        end

        -- Reset button
        if x == 159 and y == 2 and state.devMode then
            shell.execute("reboot")
        end

        -- Libs configuration
        if x >= 156 and y == 3 and state.devMode then
            state.selection = 0
            drawStatic()
            drawDynamic()
        end
    end
    if settings.PAYMENT_METHOD == 'PIM' then handlePim() end
end
