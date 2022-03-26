-- table.lua
-- Extension of the table library.

local table = setmetatable({}, { __index = table })
function table.lookupify(t)
    for k, v in pairs(t) do
        t[v] = k
    end
    return t -- Not required but I think the code is cleaner like this.
end

return table