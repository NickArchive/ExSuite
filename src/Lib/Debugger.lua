local isDebugging = getreg()._DEBUGGING ~= nil
getreg()._DEBUGGING = isDebugging and getreg()._DEBUGGING or {
    RemoteEvent = {},
    RemoteFunction = {},
    BindableEvent = {},
    BindableFunction = {}
}; debugRegistry = getreg()._DEBUGGING

local function MakeHook(method, Class) -- Cancer code below.
    local old; old = hookfunction(method, function(self, ...)
        local hookSettings = Class[self]
        if hookSettings and ((hookSettings.Caller == "Exploit" and checkcaller()) or (hookSettings.Caller == "Client" and not checkcaller()) or (hookSettings.Caller == nil or hookSettings.Caller == "Both")) then
            local args = {...}
            if hookSettings.Callback then
                local res = { hookSettings.Callback(args) }
                if hookSettings.Override then return unpack(res); end
            end

            local res = { old(self, unpack(args)) }
            if hookSettings.PostCallback then task.spawn(hookSettings.PostCallback, args, res); end

            return unpack(res)
        end

        return old(self, ...)
    end)
end

if not isDebugging then
    local namecall; namecall = hookmetamethod(game, "__namecall", function(self, ...)
        if typeof(self) == "Instance" then
            local method = getnamecallmethod()
            if (method == "FireServer" and self.ClassName == "RemoteEvent") or (method == "InvokeServer" and self.ClassName == "RemoteFunction") or (method == "Fire" and self.ClassName == "BindableEvent") or (method == "Invoke" and self.ClassName == "BindableFunction") then
                return self[method](self, ...) -- Laziness.
            end
        end
        return namecall(self, ...)
    end)

    MakeHook(Instance.new("RemoteEvent").FireServer, debugRegistry.RemoteEvent)
    MakeHook(Instance.new("RemoteFunction").InvokeServer, debugRegistry.RemoteFunction) -- PostCallback doesn't work for RemoteFunctions, but it works for BindableFunctions. No idea why.
    MakeHook(Instance.new("BindableEvent").Fire, debugRegistry.BindableEvent)
    MakeHook(Instance.new("BindableFunction").Invoke, debugRegistry.BindableFunction)
end

return function(o, hookSettings) -- You can only debug a remote once. If you call debug on it again, it'll overwrite the old settings.
    debugRegistry[o.ClassName][o] = hookSettings
end