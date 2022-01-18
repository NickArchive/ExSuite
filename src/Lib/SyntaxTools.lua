-- SyntaxTools.lua
-- Generic tools for the Lua syntax.

local Table = loadstring(game:HttpGet("https://github.com/LegitH3x0R/Roblox/raw/main/src/Lib/TableTools.lua"))()

local Tools = {}
Tools.Symbols = {} do
    Tools.Symbols.IdentFirst = Table.Lookupify {
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

    Tools.Symbols.Ident = Table.Lookupify {
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

    Tools.Symbols.Numbers = Table.Lookupify {
        '0', '1', '2', '3', '4',
        '4', '6', '7', '8', '9',
    }

    Tools.Symbols.Escapes = Table.Lookupify {
        '\a', '\b', '\f', '\n', '\r',
        '\v'
    }

    Tools.Symbols.EscapeMap = Table.Lookupify {
        'a', 'b', 'f', 'n', 'r',
        'v'
    }
end

function Tools.IsValidVar(Name)
    local c = string.sub(Name, 1, 1)
    if not Tools.Symbols.IdentFirst[c] or Tools.Symbols.Numbers[c] then
        return false
    end

    for i = 2, #Name do
        if not Tools.Symbols.Ident[string.sub(Name, i, i)] then
            return false
        end
    end

    return true
end

function Tools.SerializeString(Str)
    return string.gsub(string.format("%q", Str), ".", function(c)
        if Tools.Symbols.Escapes[c] then
            return Tools.Symbols.EscapeMap[Tools.Symbols.Escapes[c]]
        end

        return c
    end)
end

function Tools.GetInstancePath(Inst) -- Because GetFullName is trash.
    local Path = ""
    repeat
        if Tools.IsValidVar(Inst.Name) then
            Path = string.format(".%s%s", Inst.Name, Path)
        else
            Path = string.format("[%s]%s", Tools.SerializeString(Inst.Name), Path)
        end
        Inst = Inst.Parent
    until Inst == nil or Inst.Parent == game -- There's two cases: The root is going to be either DataModel (game) or nil.

    if Inst == workspace then -- game:GetService("Workspace") is just weird.
        return "workspace"..Path
    elseif Inst == nil then
        return "Nil("..string.sub(Path, 2)..")"
    end

    return "game:GetService(\""..Inst.ClassName.."\")"..Path
end

function Tools.Serialize(Value)
	local Type = typeof(Value)
	if Type == "nil" then
		return Type
	elseif Type == "string" then
		return Tools.SerializeString(Value)
    elseif Type == "number" then
        if math.floor(Value) ~= Value then
            Value = string.format("%.2f", Value)
            if string.sub(Value, -3) == ".00" then
                Value = string.sub(Value, 1, -4)
            else
                Value = tostring(Value)
            end
        end

        if Value == "inf" then
            Value = "math.huge"
        elseif Value == "-inf" then
            return "-math.huge"
        elseif Value == "-nan(ind)" then -- Doesn't apply with Synapse's VM for some reason...interesting.
            return "1/0" -- undefined
        elseif Value == "-0" then
            return "0" -- bruh
        end

        return Value
    elseif Type == "boolean" then
        return tostring(Value)
    elseif Type == "userdata" then
        local Address = tonumber(string.split(tostring(Value), ": 0x")[2], 16)
        return string.format("Userdata(0x%x)", Address)
    elseif Type == "table" then
        return Tools.SerializeTable(Value)
    elseif Type == "function" then
        local Name = debug.getinfo(Value).name
        return string.format("Function(%s)", Tools.SerializeString((Name == "") and "anonymous function" or Name))
	elseif Type == "Instance" then
        return Tools.GetInstancePath(Value)
	elseif Type == "Vector2" then
		return string.format("Vector2.new(%s, %s)", Tools.Serialize(Value.X), Tools.Serialize(Value.Y))
    elseif Type == "Vector2int16" then
        return string.format("Vector2int16.new(%s, %s)", Tools.Serialize(Value.X), Tools.Serialize(Value.Y))
	elseif Type == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", Tools.Serialize(Value.X), Tools.Serialize(Value.Y), Tools.Serialize(Value.Z))
    elseif Type == "Vector3int16" then
        return string.format("Vector3int16.new(%s, %s, %s)", Tools.Serialize(Value.X), Tools.Serialize(Value.Y), Tools.Serialize(Value.Z))
    elseif Type == "CFrame" then
        local rX, rY, rZ = Value:ToOrientation()
        if rX == 0 and rY == 0 and rZ == 0 then
            return string.format("CFrame.new(%s, %s, %s)", Tools.Serialize(Value.X), Tools.Serialize(Value.Y), Tools.Serialize(Value.Z))
        end

        return string.format("CFrame.new(%s, %s, %s) * CFrame.Angles(math.rad(%s), math.rad(%s), math.rad(%s))",
            Tools.Serialize(Value.X), Tools.Serialize(Value.Y), Tools.Serialize(Value.Z),
            Tools.Serialize(math.deg(rX)), Tools.Serialize(math.deg(rY)), Tools.Serialize(math.deg(rZ))
        )
    elseif Type == "UDim" then
        return string.format("UDim.new(%s, %s)", Tools.Serialize(Value.Scale), Tools.Serialize(Value.Offset))
    elseif Type == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", Tools.Serialize(Value.X.Scale), Tools.Serialize(Value.X.Offset), Tools.Serialize(Value.Y.Scale), Tools.Serialize(Value.Y.Offset))
    elseif Type == "BrickColor" then
        return string.format("BrickColor.new(%q)", Value.Name)
    elseif Type == "Color3" then
        return string.format("Color3.fromRGB(%s, %s, %s)", Tools.Serialize(Value.R * 0xFF), Tools.Serialize(Value.G * 0xFF), Tools.Serialize(Value.B * 0xFF))
    elseif Type == "DateTime" then
        return string.format("DateTime.fromIsoDate(%q)", Value:ToIsoDate())
        --local UTC = Value:ToUniversalTime()
        --return "DateTime.fromUniversalTime("..UTC.Year..", "..UTC.Month..", "..UTC.Day..", "..UTC.Hour..", "..UTC.Minute..", "..UTC.Second..", "..UTC.Millisecond..")"
    elseif Type == "Enums" then
        return "Enum"
    elseif Type == "Enum" then
        return string.format("Enum.%s", tostring(Value))
    elseif Type == "EnumItem" then
        return tostring(Value)
    elseif Type == "Ray" then
        return string.format("Ray.new(%s, %s)", Tools.Serialize(Value.Origin), Tools.Serialize(Value.Direction))
    elseif Type == "RBXScriptSignal" then -- Possible guess functionality??
        return string.format("Signal(%q)", string.split(tostring(Value), " ")[2])
    elseif Type == "RBXScriptConnection" then -- Maybe scan GC for relative connections?
        return "Connection()"
    elseif Type == "Region3" then -- I'm failing to do simple math so ill just put fuzzy here.
        return string.format("FuzzyRegion3(%s, %s) --[[ Center, Area ]]", Tools.Serialize(Value.CFrame), Tools.Serialize(Value.Size))
	end

	return string.format("unk(\"%s\", %s)", Type, Tools.SerializeString(tostring(Value)))
end

function Tools.SerializeTable(t, Depth, Cache)
    if not Depth then
        Cache = table.create(100)
        Depth = 1
    end

    local Tab = string.rep("    ", Depth)
    local Tab2, Dump = "    "..Tab, "{\n"
    for k, v in pairs(t) do
        local Key = (type(k) ~= "table") and Tools.Serialize(k) or string.format("Table(%q)", tostring(k))
        if type(v) == "table" then
            if table.find(Cache, v) then
                Dump = Dump..string.format("%s[%s] = CyclicTable(%q),\n", Tab2, Key, tostring(v))
                continue;
            end

            Cache[#Cache + 1] = v
            Dump = Dump..string.format("%s[%s] = %s,\n", Tab2, Key, Tools.SerializeTable(v, Depth + 1, Cache))
            continue;
        end
        Dump = Dump..string.format("%s[%s] = %s,\n", Tab2, Key, Tools.Serialize(v))
    end

    return Dump..Tab.."}"
end

function Tools.SerializeUnpacked(...)
    local Serialized = ""
    for _, o in ipairs({...}) do
        Serialized = Serialized..Tools.Serialize(o)..", "
    end

    return string.sub(Serialized, 1, -3)
end

return Tools