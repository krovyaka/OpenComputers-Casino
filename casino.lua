local casino = {}
local component = require("component")
local unicode = require("unicode")
local shell = require("shell")
local filesystem = require("filesystem")
local gpu = component.gpu
local internet = component.internet

casino.writeCenter = function(x, y, text, color)
    gpu.setForeground(color)
    x = x - unicode.len(text) / 2
    gpu.set(x, y, text)
end

casino.drawRectangle = function(x, y, width, height, color)
    gpu.setBackground(color)
    gpu.fill(x, y, width, height, " ")
end

casino.drawRectangleWithCenterText = function(x, y, width, height, text, bgcolor, fgcolor)
    casino.drawRectangle(x, y, width, height, bgcolor)
    casino.writeCenter(width / 2 + x, height / 2 + y, text, fgcolor)
end

casino.drawBigText = function(x, y, maxWidth, text)
    local len = unicode.len(text)
    local line = 0
    for i = 1, len, maxWidth do
        gpu.set(x, y + line, unicode.sub(text, i, i + maxWidth - 1))
        line = line + 1
    end
end

casino.setResolution = function(width, height)
    gpu.setResolution(width, height)
end

casino.downloadFile = function(url, saveTo, forceRewrite)
    if forceRewrite or not filesystem.exists(saveTo) then
        shell.execute("wget -fq " .. url .. " " .. saveTo)
    end
end

casino.setBackground = function(background)
    gpu.setBackground(background)
end

return casino