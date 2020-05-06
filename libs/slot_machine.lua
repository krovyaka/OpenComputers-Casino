---Creates shuffled table copy
---@param t table
---@return table
local function shuffle(t)
    local result = {}
    for i = 1, #t do
        result[i] = t[i]
    end
    -- Fisher–Yates shuffle
    for i = #result, 1, -1 do
        local j = math.random(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

local Symbol = {}
function Symbol:new()
    local obj = {}
    obj.sound = nil
    obj.image = nil

    setmetatable(obj, self)
    self.__index = self;
    return obj
end

local Machine = {}
function Machine:new()
    local obj = {}
    obj.symbols = nil

    --- @return table
    function obj.rollColumn()
        return shuffle(obj.symbols)
    end

    obj.spin = setmetatable(obj, self)
    self.__index = self;
    return obj
end

local slot_machine = {}
slot_machine.Symbol = Symbol
slot_machine.Slot = Slot
return slot_machine