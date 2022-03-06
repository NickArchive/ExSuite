-- TableTools.lua
-- An extension of the table library in Lua.

local table = setmetatable({}, { __index = table })
function table.lookupify(t)
    for k, v in pairs(t) do
        t[v] = k
    end

    return t -- Not required but I think the code is cleaner like this.
end

return table