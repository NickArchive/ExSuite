local ExecutedBefore = getreg()._DEBUGGING ~= nil
getreg()._DEBUGGING = ExecutedBefore and getreg()._DEBUGGING or {
    RemoteEvent = {},
    RemoteFunction = {},
    BindableEvent = {},
    BindableFunction = {}
}; Debugging = getreg()._DEBUGGING

local function MakeHook(Method, Class) -- Cancer code below.
    local Old; Old = hookfunction(Method, function(self, ...)
        local Settings = Class[self]
        if Settings and ((Settings.Caller == "Exploit" and checkcaller()) or (Settings.Caller == "Client" and not checkcaller()) or (Settings.Caller == nil or Settings.Caller == "Both")) then
            local Args = {...}
            if Settings.Callback then
                local Res = { Settings.Callback(Args) }
                if Settings.Override then return unpack(Res); end
            end

            local Res = { Old(self, unpack(Args)) }
            if Settings.PostCallback then task.spawn(Settings.PostCallback, Args, Res); end

            return unpack(Res)
        end

        return Old(self, ...)
    end)
end

if not ExecutedBefore then
    local Namecall; Namecall = hookmetamethod(game, "__namecall", function(self, ...)
        if typeof(self) == "Instance" then
            local Method = getnamecallmethod()
            if (Method == "FireServer" and self.ClassName == "RemoteEvent") or (Method == "InvokeServer" and self.ClassName == "RemoteFunction") or (Method == "Fire" and self.ClassName == "BindableEvent") or (Method == "Invoke" and self.ClassName == "BindableFunction") then
                return self[Method](self, ...) -- Laziness.
            end
        end
        return Namecall(self, ...)
    end)

    MakeHook(Instance.new("RemoteEvent").FireServer, Debugging.RemoteEvent)
    MakeHook(Instance.new("RemoteFunction").InvokeServer, Debugging.RemoteFunction) --PostCallback doesn't work for RemoteFunctions, but it works for BindableFunctions. No idea why.
    MakeHook(Instance.new("BindableEvent").Fire, Debugging.BindableEvent)
    MakeHook(Instance.new("BindableFunction").Invoke, Debugging.BindableFunction)
end

return function(Obj, Settings) -- You can only debug a remote once. If you call debug on it again, it'll overwrite the old settings.
    Debugging[Obj.ClassName][Obj] = Settings
end