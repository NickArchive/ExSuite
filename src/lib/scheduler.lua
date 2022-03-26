-- scheduler.lua
-- Queue-based asynchronous task scheduler

local Signal = loadLibrary("signal")
local Scheduler = {}
Scheduler.MT = {
    __index = Scheduler
}

function Scheduler.new()
    local self = {}
    self._Queue = {}
    self._Active = false
    self._TaskCn = nil
    self.TaskFinished = Signal.new()
    return setmetatable(self, Scheduler.MT)
end

function Scheduler:Add(f, p)
    if type(p) == "number" then
        table.insert(self._Queue, p, f)
        return;
    elseif p == true then
        table.insert(self._Queue, 1, f)
        return;
    end
    self._Queue[#self._Queue + 1] = f
end

function Scheduler:Cancel(f)
    table.remove(self._Queue, table.find(self._Queue, f))
end

function Scheduler:Start()
    self._Active = true
    self._TaskCn = self.TaskFinished:Connect(function()
        if not self._Active then
            self._TaskCn:Disconnect()
            return;
        end

        while not self._Queue[1] do task.wait(); end
        self._Queue[1]()
        self:Cancel(self._Queue[1])
        self.TaskFinished:Fire()
    end)
    self.TaskFinished:Fire()
end

function Scheduler:Stop()
    self._Active = false
end

return Scheduler
