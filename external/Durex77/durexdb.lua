require('db')
--require('inMemoryDb')
local db = DurexDatabase:new()
Database = {}


function Database:new()
    local obj = {}

    function obj:read() -- only for in memory db
        return db:read()
    end

    function obj:save() -- only for in memory db
        return db:save()
    end

    function obj:execute(inputQuery, value)
        local args = {}
        local query = {}
        for word in inputQuery:gmatch("%S+") do
            table.insert(args, word)
        end
        query.type = args[1];
        if (args[1] == 'SELECT') then
            query.table = args[3]
            local fields = {}
            for i = 4, #args do
                if (args[i] == 'WHERE' or args[i] == 'AND') then
                    local field = {}
                    field.column = args[i + 1]
                    field.operation = args[i + 2]
                    field.value = args[i + 3]:gsub("___", " ")
                    table.insert(fields, field)
                elseif (args[i] == 'SKIP') then
                    query.skip = tonumber(args[i + 1])
                elseif (args[i] == 'LIMIT') then
                    query.limit = tonumber(args[i + 1])
                elseif (args[i] == 'ORDER' and args[i + 1] == 'BY') then
                    query.orderBy = args[i + 2]
                end
            end
            if (#fields > 0) then
                query.fields = fields
            end
        end

        if (query.type == 'CREATE') then
            query.createType = args[2]
            if (query.createType == 'DATABASE') then
                query.table = args[3]
            elseif (query.createType == 'INDEX') then
                query.name = args[3]
                query.table = args[5]
                query.field = args[6]
                query.indexType = args[7]
            end
        end

        if (query.type == 'INSERT') then
            query.table = args[3]
            query.id = args[4]:gsub(":", "")
            query.value = value
        end

        if (query.type == 'DELETE') then
            query.table = args[3]

            local i = 5
            if (args[i]) then
                query.fields = {}
            end
            while (args[i]) do
                local field = {}
                field.column = args[i]
                field.operation = args[i + 1]
                field.value = args[i + 2]
                table.insert(query.fields, field)
                i = i + 3
            end
        end
        return db:executeQuery(query)
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end
