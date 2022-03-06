-- SyntaxTools.lua
-- Generic tools for the Lua syntax.

local table = loadstring(game:HttpGet("https://github.com/LegitH3x0R/ExSuite/raw/main/src/Lib/TableTools.lua"))()

local Tools = {}
Tools.Symbols = {} do
    Tools.Symbols.IdentFirst = table.lookupify {
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o',
        'p', 'q', 'r', 's', 't',
        'u', 'v', 'w', 'x', 'y',
        'z', 'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H', 'I',
        'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S',
        'T', 'U', 'V', 'W', 'X',
        'Y', 'Z', '_',
    }

    Tools.Symbols.Ident = table.lookupify {
        '0', '1', '2', '3', '4',
        '4', '6', '7', '8', '9',
        'a', 'b', 'c', 'd', 'e',
        'f', 'g', 'h', 'i', 'j',
        'k', 'l', 'm', 'n', 'o',
        'p', 'q', 'r', 's', 't',
        'u', 'v', 'w', 'x', 'y',
        'z', 'A', 'B', 'C', 'D',
        'E', 'F', 'G', 'H', 'I',
        'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S',
        'T', 'U', 'V', 'W', 'X',
        'Y', 'Z', '_',
    }

    Tools.Symbols.Numbers = table.lookupify {
        '0', '1', '2', '3', '4',
        '4', '6', '7', '8', '9',
    }

    Tools.Symbols.Escapes = table.lookupify {
        '\a', '\b', '\f', '\n', '\r',
        '\v'
    }

    Tools.Symbols.EscapeMap = table.lookupify {
        'a', 'b', 'f', 'n', 'r',
        'v'
    }
end

function Tools.isValidVar(name)
    local c = string.sub(name, 1, 1)
    if not Tools.Symbols.IdentFirst[c] or Tools.Symbols.Numbers[c] then
        return false
    end

    for i = 2, #name do
        if not Tools.Symbols.Ident[string.sub(name, i, i)] then
            return false
        end
    end

    return true
end

function Tools.serializeString(str)
    return string.gsub(string.format("%q", str), ".", function(c)
        if Tools.Symbols.Escapes[c] then
            return Tools.Symbols.EscapeMap[Tools.Symbols.Escapes[c]]
        end

        return c
    end)
end

function Tools.getInstancePath(inst) -- Because GetFullName is trash.
    local path = ""
    repeat
        if Tools.IsValidVar(inst.name) then
            path = string.format(".%s%s", inst.name, path)
        else
            path = string.format("[%s]%s", Tools.SerializeString(inst.name), path)
        end
        inst = inst.Parent
    until inst == nil or inst.Parent == game -- There's two cases: The root is going to be either DataModel (game) or nil.

    if inst == workspace then -- game:GetService("Workspace") is just weird.
        return "workspace"..path
    elseif inst == nil then
        return "Nil("..string.sub(path, 2)..")"
    end

    return "game:GetService(\""..inst.ClassName.."\")"..path
end

function Tools.serialize(value)
	local vType = typeof(value)
	if vType == "nil" then
		return vType
	elseif vType == "string" then
		return Tools.SerializeString(value)
    elseif vType == "number" then
        if math.floor(value) ~= value then
            value = string.format("%.2f", value)
            if string.sub(value, -3) == ".00" then
                value = string.sub(value, 1, -4)
            else
                value = tostring(value)
            end
        end

        if value == "inf" then
            value = "math.huge"
        elseif value == "-inf" then
            return "-math.huge"
        elseif value == "-nan(ind)" then -- Doesn't apply with Synapse's VM for some reason...interesting.
            return "1/0" -- undefined
        elseif value == "-0" then
            return "0" -- bruh
        end

        return value
    elseif vType == "boolean" then
        return tostring(value)
    elseif vType == "userdata" then
        local addr = tonumber(string.split(tostring(value), ": 0x")[2], 16)
        return string.format("Userdata(0x%x)", addr)
    elseif vType == "table" then
        return Tools.SerializeTable(value)
    elseif vType == "function" then
        local name = debug.getinfo(value).name
        return string.format("Function(%s)", Tools.SerializeString((name == "") and "anonymous function" or name))
	elseif vType == "Instance" then
        return Tools.GetInstancePath(value)
	elseif vType == "Vector2" then
		return string.format("Vector2.new(%s, %s)", Tools.serialize(value.X), Tools.serialize(value.Y))
    elseif vType == "Vector2int16" then
        return string.format("Vector2int16.new(%s, %s)", Tools.serialize(value.X), Tools.serialize(value.Y))
	elseif vType == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", Tools.serialize(value.X), Tools.serialize(value.Y), Tools.serialize(value.Z))
    elseif vType == "Vector3int16" then
        return string.format("Vector3int16.new(%s, %s, %s)", Tools.serialize(value.X), Tools.serialize(value.Y), Tools.serialize(value.Z))
    elseif vType == "CFrame" then
        local rX, rY, rZ = value:ToOrientation()
        if rX == 0 and rY == 0 and rZ == 0 then
            return string.format("CFrame.new(%s, %s, %s)", Tools.serialize(value.X), Tools.serialize(value.Y), Tools.serialize(value.Z))
        end

        return string.format("CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%s), math.rad(%s), math.rad(%s))",
            Tools.serialize(value.X), Tools.serialize(value.Y), Tools.serialize(value.Z),
            Tools.serialize(math.deg(rX)), Tools.serialize(math.deg(rY)), Tools.serialize(math.deg(rZ))
        )
    elseif vType == "UDim" then
        return string.format("UDim.new(%s, %s)", Tools.serialize(value.Scale), Tools.serialize(value.Offset))
    elseif vType == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", Tools.serialize(value.X.Scale), Tools.serialize(value.X.Offset), Tools.serialize(value.Y.Scale), Tools.serialize(value.Y.Offset))
    elseif vType == "BrickColor" then
        return string.format("BrickColor.new(%q)", value.name)
    elseif vType == "Color3" then
        return string.format("Color3.fromRGB(%s, %s, %s)", Tools.serialize(value.R * 0xFF), Tools.serialize(value.G * 0xFF), Tools.serialize(value.B * 0xFF))
    elseif vType == "DateTime" then
        return string.format("DateTime.fromIsoDate(%q)", value:ToIsoDate())
        --local utc = value:ToUniversalTime()
        --return "DateTime.fromUniversalTime("..utc.Year..", "..utc.Month..", "..utc.Day..", "..utc.Hour..", "..utc.Minute..", "..utc.Second..", "..utc.Millisecond..")"
    elseif vType == "Enums" then
        return "Enum"
    elseif vType == "Enum" then
        return string.format("Enum.%s", tostring(value))
    elseif vType == "EnumItem" then
        return tostring(value)
    elseif vType == "Ray" then
        return string.format("Ray.new(%s, %s)", Tools.serialize(value.Origin), Tools.serialize(value.Direction))
    elseif vType == "RBXScriptSignal" then -- Possible guess functionality??
        return string.format("Signal(%q)", string.split(tostring(value), " ")[2])
    elseif vType == "RBXScriptConnection" then -- Maybe scan GC for relative connections?
        return "Connection()"
    elseif vType == "Region3" then -- I'm failing to do simple math so ill just put fuzzy here.
        return string.format("FuzzyRegion3(%s, %s) --[[ Center, Area ]]", Tools.serialize(value.CFrame), Tools.serialize(value.Size))
	end

	return string.format("unk(\"%s\", %s)", vType, Tools.SerializeString(tostring(value)))
end

function Tools.serializeTable(t, depth, cache)
    if not depth then
        cache = {}
        depth = 0
    end

    local Tab = string.rep("    ", depth)
    local Tab2, Dump = "    "..Tab, "{\n"
    for k, v in pairs(t) do
        local Key = (type(k) ~= "table") and Tools.serialize(k) or string.format("table(%q)", tostring(k))
        if type(v) == "table" then
            if table.find(cache, v) then
                Dump = Dump..string.format("%s[%s] = CyclicTable(%q),\n", Tab2, Key, tostring(v))
                continue;
            end

            cache[#cache + 1] = v
            Dump = Dump..string.format("%s[%s] = %s,\n", Tab2, Key, Tools.serializeTable(v, depth + 1, cache))
            continue;
        end
        Dump = Dump..string.format("%s[%s] = %s,\n", Tab2, Key, Tools.serialize(v))
    end

    return Dump..Tab.."}"
end

function Tools.serializeUnpacked(...)
    local Serialized = ""
    for _, o in ipairs({...}) do
        Serialized = Serialized..Tools.serialize(o)..", "
    end

    return string.sub(Serialized, 1, -3)
end

return Tools
