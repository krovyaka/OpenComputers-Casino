---
--- Created by krovyaka.
--- DateTime: 24.04.2020 17:31
---
local component = require("component")
local internet = component.internet
local casino = require("casino")

local games = {
    {title = "Рулетка"},
    {title = "Больше-Меньше"},
    {title = "Видео Покер"},
    {title = "Сапёр"}
}

local state = {
title = "/warp casino",
selection = 1;
}


function drawStatic()
    casino.drawRectangleWithCenterText(1, 1, 160, 5, state.title, 0x431148, 0xffffff)
end

function drawDynamic()
    casino.drawRectangle(1, 6, 48, 45, 0xF2F2F2)
    casino.drawRectangle(49, 6, 112, 45, 0xFFFFFF)
    for i = 1, #games do
        casino.drawRectangleWithCenterText(2, 3 + i * 4, 46, 3, games[i].title, 0xE3E3E3, 0x000000)
    end
    casino.drawRectangleWithCenterText(52, 40, 50, 5, "Играть", 0x431148, 0xffffff)
end

drawStatic()
drawDynamic()