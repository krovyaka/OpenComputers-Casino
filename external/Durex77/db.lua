local fs = require("filesystem")
local shell = require("shell")
local serial = require("serialization")
local component = require('component')
DurexDatabase = {}
function DurexDatabase:new()
    local obj = {}

    function obj:save()
    end

    function obj:read()
    end

    function obj:init(value)
        self.fullPath = shell.getWorkingDirectory() .. "/durex/" .. value.table .. "/"
        self.dataPath = shell.getWorkingDirectory() .. "/durex/" .. value.table .. '/data/'
        self.indexPath = shell.getWorkingDirectory() .. "/durex/" .. value.table .. '/index/'
        self.query = value

        if (not self.query.limit) then
            self.query.limit = 10000
        end
        if (not self.query.skip) then
            self.query.skip = 0
        end
    end

    function obj:executeQuery(value)
        self:init(value);
        if (self.query.type == "SELECT") then
            return self:selectQ()
        elseif (self.query.type == "INSERT") then
            self:insert()
        elseif (self.query.type == "CREATE") then
            if (self.query.createType == "DATABASE") then
                self:createDataBase()
            elseif (self.query.createType == "INDEX") then
                self:createIndex()
            end
        elseif (self.query.type == "DELETE") then
            self:delete()
        end
    end

    function obj:createDataBase()
        fs.makeDirectory(shell.getWorkingDirectory() .. "/durex")
        fs.makeDirectory(self.fullPath)
        fs.makeDirectory(self.dataPath)
        fs.makeDirectory(self.indexPath)
    end

    function obj:createIndex()
        fs.makeDirectory(shell.getWorkingDirectory() .. "/durex")
        fs.makeDirectory(self.fullPath)
        fs.makeDirectory(self.indexPath)
        self:initIndex()
    end

    function obj:initIndex()
        local indexedValues = {}
        indexedValues[""] = {} --todo check if it needed
        local elements = fs.list(self.dataPath)
        for element in (elements) do
            local file = io.open(self.dataPath .. "/" .. element, "r")
            local indexedValue, value = self:indexValue(serial.unserialize(file:read("*a")), element, self.query.field .. '.' .. self.query.indexType)
            if (not indexedValues[indexedValue]) then
                indexedValues[indexedValue] = {}
            end
            table.insert(indexedValues[indexedValue], value)
            file:close()
        end
        local file = io.open(self.indexPath .. self.query.field .. "." .. self.query.indexType, "w")
        file:write(serial.serialize(indexedValues))
        file:close()
    end

    function obj:indexValue(value, pathToValue, key)
        local words = {}
        for word in key:gmatch("%w+") do table.insert(words, word) end
        if ("EXACT" == words[2]) then
            return tostring(value[words[1]]), pathToValue:gsub(":", "")
        end
        if ("STARTFROM" == words[2]) then
            return tostring(value[words[1]]), pathToValue:gsub(":", "")
        end
    end

    function obj:insert()
        local oldValue;
        if (fs.exists(self.dataPath .. self.query.id .. ".row")) then
            local file = io.open(self.dataPath .. self.query.id .. ".row", "r")
            oldValue = serial.unserialize(file:read("*a"))
            file:close()
        end
        self:updateIndexValues(oldValue, self.query.value, self.query.id .. ".row")
        oldValue = nil
        local file = io.open(self.dataPath .. self.query.id .. ".row", "w")
        file:write(serial.serialize(self.query.value))
        file:close()
    end


    function obj:insertWithLimits(resultValue, tempValue)
        if (self.query.skip > 0) then
            self.query.skip = self.query.skip - 1
        else
            if (self.query.limit == 0) then
                return false
            end
            self.query.limit = self.query.limit - 1
            table.insert(resultValue, tempValue)
        end
        return true
    end

    function obj:tablefind(tab, el)
        for index, value in pairs(tab) do
            if value == el then
                return index
            end
        end
    end

    function obj:clearIndexes()
        for index in (fs.list(self.indexPath)) do
            local file = io.open(self.indexPath .. index, "w")
            file:write('')
            file:close()
        end
    end

    function obj:updateIndexValues(oldItem, newItem, name)
        for index in (fs.list(self.indexPath)) do
            local file = io.open(self.indexPath .. index, "r")
            local indexedValues = serial.unserialize(file:read("*a"))
            if (not indexedValues) then
                indexedValues = {}
            end
            file:close()
            if (oldItem) then
                local indexedValue, value = self:indexValue(oldItem, name, index)
                table.remove(indexedValues[indexedValue], self:tablefind(indexedValues[indexedValue], value))
            end
            file = io.open(self.indexPath .. index, "w")
            if (newItem) then
                local indexedValue, value = self:indexValue(newItem, name, index)
                if (not indexedValues[indexedValue]) then
                    indexedValues[indexedValue] = {}
                end
                table.insert(indexedValues[indexedValue], value)
            end
            file:write(serial.serialize(indexedValues))
            file:close()
        end
    end

    function obj:selectById(resultValue)
        local path = self.dataPath .. self.query.fields[1].value .. ".row"
        if (not fs.exists(path)) then
            return
        end

        local file = io.open(path, "r")
        table.insert(resultValue, serial.unserialize(file:read("*a")))
        file:close()
    end

    function obj:selectFromObject(object)
        object:init()
        local filters = object:getFilters()
        local resultValues = {}
        if (object:getCount() == 0) then
            return resultValues
        end

        if (not filters) then
            while (self.query.skip > 0) do
                self.query.skip = self.query.skip - 1
                object:skip()
            end
        end

        local value = object:next()
        repeat
            local isItemValid = true
            if (filters) then
                for j, field in pairs(filters) do
                    if (not self:isValid(value[field.column], field.value, field.operation)) then
                        isItemValid = false
                        break
                    end
                end
            end

            if (isItemValid) then
                if (not self:insertWithLimits(resultValues, value)) then
                    return resultValues
                end
            end
            value = object:next()
        until (not value)
        return resultValues
    end

    function obj:selectByIndex(indexValues, searchValue, indexType)
        if (indexType == "EXACT") then
            return indexValues[searchValue]
        elseif (indexType == "STARTFROM") then
            local result = {}
            for k, v in pairs(indexValues) do
                if (self:isValid(k, searchValue, indexType)) then
                    for i, v1 in pairs(v) do
                        table.insert(result, v1)
                    end
                end
            end
            return result
        end
    end

    function obj:selectQ()
        local resultValue = {}
        local sortedValues = {}
        if (self.query.fields and self.query.fields[1].column == "ID") then
            self:selectById(resultValue)
        elseif (self:isIndexExist(self.query.fields)) then
            local indexedValues = {}
            function indexedValues:new(parent)
                local obj1 = {}
                obj1.parent = parent
                function obj1:init()
                    local indexes = self.parent:isIndexExist(self.parent.query.fields)
                    local file = io.open(self.parent.indexPath .. self.parent.query.fields[indexes[1]].column .. "." .. self.parent:getIndexType(self.parent.query.fields[indexes[1]].operation))
                    local indexedValues1 = serial.unserialize(file:read("*a"))
                    file:close()
                    local searchValues = self.parent:selectByIndex(indexedValues1, self.parent.query.fields[indexes[1]].value, self.parent:getIndexType(self.parent.query.fields[indexes[1]].operation))
                    for i = 2, #indexes do
                        local file = io.open(self.parent.indexPath .. self.parent.query.fields[indexes[i]].column .. "." .. self.parent:getIndexType(self.parent.query.fields[indexes[i]].operation))
                        local tempIndexedValues = serial.unserialize(file:read("*a"))
                        file:close()
                        searchValues = self.parent:intersection(searchValues, tempIndexedValues[self.parent.query.fields[indexes[i]].value])
                    end
                    if (obj.query.orderBy) then
                        local file = io.open(self.parent.indexPath .. obj.query.orderBy .. ".EXACT")
                        if (file) then
                            local tempIndexedValues = serial.unserialize(file:read("*a"))
                            file:close()
                            local mapToIndex = {}
                            for k, v in pairs(tempIndexedValues) do
                                for i = 1, #v do
                                    mapToIndex[v[i]] = k
                                end
                            end

                            table.sort(searchValues, function(left, right)
                                return tonumber(mapToIndex[left]) > tonumber(mapToIndex[right])
                            end)

                            self.isContainceKeys = true
                        else
                            local allValues = {}
                            for i = 1, #searchValues do
                                file = io.open(self.parent.dataPath .. searchValues[i])
                                local value = serial.unserialize(file:read("*a"))
                                file:close()
                                table.insert(allValues, value)
                            end

                            table.sort(allValues, function(left, right)
                                return left[self.parent.query.orderBy] > right[self.parent.query.orderBy]
                            end)
                            self.isContainceKeys = false
                            searchValues = allValues
                        end
                    end
                    self.searchValues = searchValues
                    self.index = 1
                    self.filters = self.parent.query.fields
                    self.count = #searchValues
                end

                function obj1:next()
                    if (self.isContainceKeys) then
                        local idOfValue = self.searchValues[self.index]
                        self.index = self.index + 1
                        if (not idOfValue) then
                            return
                        end
                        local file = io.open(self.parent.dataPath .. idOfValue)
                        local value = serial.unserialize(file:read("*a"))
                        file:close()
                        return value
                    else
                        local value = self.searchValues[self.index]
                        self.index = self.index + 1
                        return value
                    end
                end

                function obj1:getFilters()
                    return self.filters
                end

                function obj1:skip()
                    self.index = self.index + 1
                end

                function obj1:getCount()
                    return self.count
                end

                setmetatable(obj1, self)
                self.__index = self; return obj1
            end

            return self:selectFromObject(indexedValues:new(self))
        else
            local values = {}
            function values:new(parent)
                local obj1 = {}
                obj1.parent = parent

                function obj1:init()
                    local searchValues = {}
                    if (self.parent.query.orderBy) then
                        local file = io.open(self.parent.indexPath .. self.parent.query.orderBy .. '.EXACT')
                        if (file) then
                            local tempIndexedValues = serial.unserialize(file:read("*a"))
                            file:close()
                            local sortedList = {}
                            for k, v in pairs(tempIndexedValues) do
                                for i = 1, #v do
                                    local tempItem = {}
                                    tempItem[1] = k
                                    tempItem[2] = v[i]
                                    table.insert(sortedList, tempItem)
                                end
                            end


                            table.sort(sortedList, function(left, right)
                                return tonumber(left[1]) > tonumber(right[1])
                            end)
                            for i = 1, #sortedList do
                                searchValues[i] = sortedList[i][2]
                            end
                            self.isContainceKeys = true
                        else
                            for item in (fs.list(self.parent.dataPath)) do
                                file = io.open(self.parent.dataPath .. item)
                                local tempValue = serial.unserialize(file:read("*a"))
                                file:close()
                                table.insert(searchValues, tempValue)
                            end
                            table.sort(searchValues, function(left, right)
                                return left[self.parent.query.orderBy] > right[self.parent.query.orderBy]
                            end)
                            self.isContainceKeys = false
                        end
                    else
                        for item in (fs.list(self.parent.dataPath)) do
                            table.insert(searchValues, item)
                        end
                        self.isContainceKeys = true;
                    end

                    self.searchValues = searchValues
                    self.index = 1
                    self.filters = self.parent.query.fields
                    self.count = #searchValues
                end

                function obj1:next()
                    if (self.isContainceKeys) then
                        local idOfValue = self.searchValues[self.index]
                        self.index = self.index + 1
                        if (not idOfValue) then
                            return
                        end
                        local file = io.open(self.parent.dataPath .. idOfValue)
                        local value = serial.unserialize(file:read("*a"))
                        file:close()
                        return value
                    else
                        local value = self.searchValues[self.index]
                        self.index = self.index + 1
                        return value
                    end
                end

                function obj1:getFilters()
                    return self.filters
                end

                function obj1:skip()
                    self.index = self.index + 1
                end

                function obj1:getCount()
                    return self.count
                end

                setmetatable(obj1, self)
                self.__index = self; return obj1
            end

            return self:selectFromObject(values:new(self))
        end
        if (self.query.orderBy) then --todo is it valid?
            table.sort(sortedValues, function(left, right)
                return left[self.query.orderBy] > right[self.query.orderBy]
            end)

            for i = 1, #sortedValues do
                if (not self:insertWithLimits(resultValue, sortedValues[i])) then
                    break
                end
            end
        end
        return resultValue
    end

    function obj:getIndexType(operation)
        if (operation == '=') then
            return "EXACT"
        elseif (operation == 'STARTFROM') then
            return 'STARTFROM'
        end
    end

    function obj:isIndexExist(fields)
        if fields == null then
            return false
        end
        local indexes = {}
        for index, value in pairs(fields) do
            if (fs.exists(self.indexPath .. "/" .. value.column .. "." .. self:getIndexType(value.operation))) then
                table.insert(indexes, index)
            end
        end
        if (#indexes > 0) then
            return indexes
        end
        return false
    end

    function obj:starts_with(str, start)
        return str:sub(1, #start) == start
    end

    function obj:isValid(value1, value2, operation)
        if (operation == "=") then
            return tostring(value1) == tostring(value2)
        elseif (operation == "STARTFROM") then
            local result = self:starts_with(string.lower(value1), string.lower(value2))
            local a = 'false'
            if (result) then a = 'true' end
            return result
        end
    end

    function obj:delete()
        if (self.query.fields) then

        else
            local elements = fs.list(self.dataPath)
            for i = 1, #elements do
                fs.remove(self.dataPath .. "/" .. elements[i])
            end
            self:clearIndexes()
        end
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end
