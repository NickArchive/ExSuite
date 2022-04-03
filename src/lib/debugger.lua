-- debugger.lua

local debugger = {}
debugger._Detouring = setmetatable({}, { __mode = "k" })

function debugger.detourMethod(o, f, detour)
    local detourInfo = {}
    detourInfo.Type = "method"
    detourInfo.Source = o
    detourInfo.Closure = type(f) == "string" and o[f] or f
    detourInfo.Hook = detour

    function detourInfo:Join()
        self.BaseClosure = hookfunction(self.Closure, self.Hook)
        debugger._Detouring[self.Source] = self
    end

    function detourInfo:Disband()
        hookfunction(self.Closure, self.BaseClosure)
        debugger._Detouring[self.Source] = nil
    end

    detourInfo:Join()
    return detourInfo
end

function debugger.detourRemote(o, detour)

end

do
    local detouring = debugger._Detouring
    local index, namecall;
    index = hookmetamethod(game, "__index", function(self, key)
        return index(self, key)
    end)

    namecall = hookmetamethod(game, "__namecall", function(self, ...)
        local detourInfo = detouring[self]
        if detourInfo and detourInfo.Type == "method" and detourInfo.Source == self then
            local methodName = getnamecallmethod()
            local method = index(self, methodName)
            if detourInfo.Closure == method then
                return method(self, ...)
            end
        end
        return namecall(self, ...)
    end)
end

return debugger