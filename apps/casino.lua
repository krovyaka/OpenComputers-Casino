local casino = {}
local component = require("component")
local gpu = component.gpu
local unicode = require("unicode")

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
    casino.writeCenter( width / 2 + x, height / 2 + y, text, fgcolor)
end

casino.setResolution = function(width, height)
    gpu.setResolution(width, height)
end

return casino