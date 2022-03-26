local getreg = getreg or debug.getregistry
assert(getreg, "'getreg' does not exist.")
assert(readfile and writefile, "Filesystem functions do not exist.")

local HttpService = game:GetService("HttpService")

local callEnv = getfenv(2)
local loadSettings = rawget(callEnv, "EXSUITE_LOADER_SETTINGS") or {}
loadSettings.branch = loadSettings.branch or "main"
loadSettings.maintainer = loadSettings.maintainer or "LegitH3x0R"
local base = ("http://github.com/%s/ExSuite/raw/%s"):format(loadSettings.maintainer, loadSettings.branch)

local reg = getreg()
local meta = reg.exSuiteMeta
if not meta then
    meta = {}
    reg.exSuiteMeta = meta
end
meta.cached = {}

local loadLibrary;
if loadSettings.dev then
    loadLibrary = function(module) -- Bypass caching for fast testing.
        return loadstring(readfile((".projects/ExSuite/src/lib/%s.lua"):format(module)))()
    end
else
    loadLibrary = function(module)
        local args = meta.cached[module]
        if not args then
            args = { loadstring(game:HttpGet(("%s/src/lib/%s.lua"):format(base, module)))() }
            meta.cached[module] = args
        end
        return unpack(args)
    end
end
rawset(callEnv, "loadLibrary", loadLibrary)

if loadSettings.loadEnv then
    local env = HttpService:JSONDecode(game:HttpGet(("%s/src/env.json"):format(base)))
    for k, v in pairs(env) do
        rawset(callEnv, k, loadLibrary(v))
    end
end

return loadLibrary