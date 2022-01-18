-- TableTools.lua
-- An extension of the table library in Lua.

local Table = {}
function Table.Lookupify(t)
    for k, v in pairs(t) do
        t[v] = k
    end
    
    return t -- Not required but I think the code is cleaner like this.
end

return Table