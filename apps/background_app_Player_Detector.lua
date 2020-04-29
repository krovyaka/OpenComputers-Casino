local component = require("component")
local sensor = component.openperipheral_sensor
local event = require("event")

local setOutput = component.redstone.setOutput
local getPlayerByUUID = sensor.getPlayerByUUID
local getPlayers = sensor.getPlayers

-- min_x, min_y, min z, max_x, max_y, max_z, REDSTONE_SIDE
local points = {
    { -2.7, 0, -5, 1.7, 3.3, 0.4, 4 },
    { 0, 0, 0, 0, 3.3, 0, 5 },
}

local activePoints = {}

local function getPoint(uuid)
    local playerInfo = getPlayerByUUID(uuid)
    if not playerInfo then
        return nil
    end
    local position = playerInfo.basic().position
    for i = 1, #points do
        local point = points[i]
        if position.x >= point[1] and position.y >= point[2] and position.z >= point[3] and position.x <= point[4] and position.y <= point[5] and position.z <= point[6] then
            return point
        end
    end
end

local function scan()
    local players = getPlayers()
    local newActivePoints = {}
    for i = 1, #players do
        local point = getPoint(players[i].uuid)
        if point then
            table.insert(newActivePoints, point)
            if not table.contains(activePoints, point) then
                setOutput(point[7], 15)
            end
        end
    end

    for i = 1, #activePoints do
        local point = activePoints[i]
        if not table.contains(newActivePoints, point) then
            setOutput(point[7], 0)
        end
    end
    activePoints = newActivePoints
end

table.contains = function(t, object)
    for _,v in pairs(t) do
        if v == object then
            return true
        end
    end
    return false
end

event.timer(2, scan, math.huge)