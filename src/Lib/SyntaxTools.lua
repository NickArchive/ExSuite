-- Syntaxsyntools.lua
-- Generic syntools for the Lua syntax.

local table = loadstring(game:HttpGet("https://github.com/LegitH3x0R/ExSuite/raw/main/src/Lib/Tablesyntools.lua"))()

local syntools = {}
syntools.Symbols = {} do
    syntools.Symbols.IdentFirst = table.lookupify {
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

    syntools.Symbols.Ident = table.lookupify {
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

    syntools.Symbols.Numbers = table.lookupify {
        '0', '1', '2', '3', '4',
        '4', '6', '7', '8', '9',
    }

    syntools.Symbols.Escapes = table.lookupify {
        '\a', '\b', '\f', '\n', '\r',
        '\v'
    }

    syntools.Symbols.EscapeMap = table.lookupify {
        'a', 'b', 'f', 'n', 'r',
        'v'
    }
end

function syntools.isValidVar(name)
    local c = string.sub(name, 1, 1)
    if not syntools.Symbols.IdentFirst[c] or syntools.Symbols.Numbers[c] then
        return false
    end

    for i = 2, #name do
        if not syntools.Symbols.Ident[string.sub(name, i, i)] then
            return false
        end
    end

    return true
end

function syntools.serializeString(str)
    return string.gsub(string.format("%q", str), ".", function(c)
        if syntools.Symbols.Escapes[c] then
            return syntools.Symbols.EscapeMap[syntools.Symbols.Escapes[c]]
        end

        return c
    end)
end

function syntools.getInstancePath(inst) -- Because GetFullName is trash.
    local path = ""
    repeat
        if syntools.IsValidVar(inst.name) then
            path = string.format(".%s%s", inst.name, path)
        else
            path = string.format("[%s]%s", syntools.SerializeString(inst.name), path)
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

function syntools.serialize(value)
	local vType = typeof(value)
	if vType == "nil" then
		return vType
	elseif vType == "string" then
		return syntools.SerializeString(value)
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
        return syntools.SerializeTable(value)
    elseif vType == "function" then
        local name = debug.getinfo(value).name
        return string.format("Function(%s)", syntools.SerializeString((name == "") and "anonymous function" or name))
	elseif vType == "Instance" then
        return syntools.GetInstancePath(value)
	elseif vType == "Vector2" then
		return string.format("Vector2.new(%s, %s)", syntools.serialize(value.X), syntools.serialize(value.Y))
    elseif vType == "Vector2int16" then
        return string.format("Vector2int16.new(%s, %s)", syntools.serialize(value.X), syntools.serialize(value.Y))
	elseif vType == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", syntools.serialize(value.X), syntools.serialize(value.Y), syntools.serialize(value.Z))
    elseif vType == "Vector3int16" then
        return string.format("Vector3int16.new(%s, %s, %s)", syntools.serialize(value.X), syntools.serialize(value.Y), syntools.serialize(value.Z))
    elseif vType == "CFrame" then
        local rX, rY, rZ = value:ToOrientation()
        if rX == 0 and rY == 0 and rZ == 0 then
            return string.format("CFrame.new(%s, %s, %s)", syntools.serialize(value.X), syntools.serialize(value.Y), syntools.serialize(value.Z))
        end

        return string.format("CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%s), math.rad(%s), math.rad(%s))",
            syntools.serialize(value.X), syntools.serialize(value.Y), syntools.serialize(value.Z),
            syntools.serialize(math.deg(rX)), syntools.serialize(math.deg(rY)), syntools.serialize(math.deg(rZ))
        )
    elseif vType == "UDim" then
        return string.format("UDim.new(%s, %s)", syntools.serialize(value.Scale), syntools.serialize(value.Offset))
    elseif vType == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", syntools.serialize(value.X.Scale), syntools.serialize(value.X.Offset), syntools.serialize(value.Y.Scale), syntools.serialize(value.Y.Offset))
    elseif vType == "BrickColor" then
        return string.format("BrickColor.new(%q)", value.name)
    elseif vType == "Color3" then
        return string.format("Color3.fromRGB(%s, %s, %s)", syntools.serialize(value.R * 0xFF), syntools.serialize(value.G * 0xFF), syntools.serialize(value.B * 0xFF))
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
        return string.format("Ray.new(%s, %s)", syntools.serialize(value.Origin), syntools.serialize(value.Direction))
    elseif vType == "RBXScriptSignal" then -- Possible guess functionality??
        return string.format("Signal(%q)", string.split(tostring(value), " ")[2])
    elseif vType == "RBXScriptConnection" then -- Maybe scan GC for relative connections?
        return "Connection()"
    elseif vType == "Region3" then -- I'm failing to do simple math so ill just put fuzzy here.
        return string.format("FuzzyRegion3(%s, %s) --[[ Center, Area ]]", syntools.serialize(value.CFrame), syntools.serialize(value.Size))
	end

	return string.format("unk(\"%s\", %s)", vType, syntools.SerializeString(tostring(value)))
end

function syntools.serializeTable(t, depth, cache)
    if not depth then
        cache = {}
        depth = 0
    end

    local tab = string.rep("    ", depth)
    local tab2, tblDump = "    "..tab, "{\n"
    for k, v in pairs(t) do
        local key = (type(k) ~= "table") and syntools.serialize(k) or string.format("table(%q)", tostring(k))
        if type(v) == "table" then
            if table.find(cache, v) then
                tblDump = tblDump..string.format("%s[%s] = CyclicTable(%q),\n", tab2, key, tostring(v))
                continue;
            end

            cache[#cache + 1] = v
            tblDump = tblDump..string.format("%s[%s] = %s,\n", tab2, key, syntools.serializeTable(v, depth + 1, cache))
            continue;
        end
        tblDump = tblDump..string.format("%s[%s] = %s,\n", tab2, key, syntools.serialize(v))
    end

    return tblDump..tab.."}"
end

function syntools.serializeUnpacked(...)
    local Serialized = ""
    for _, o in ipairs({...}) do
        Serialized = Serialized..syntools.serialize(o)..", "
    end

    return string.sub(Serialized, 1, -3)
end

return syntools
