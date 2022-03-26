local checks = {
    Continue = "for i = 1, 1 do continue; end return true",
    ArithOps = "local i = 0; i += 1; i *= 2; i ^= 2; i /= 2; i %= 2; return i == 0"
}

local pass, fails = true, {}
for k, v in pairs(checks) do
    local f = loadstring(v)
    if f then
        local success, ret = pcall(f)
        if not success or ret ~= true then
            fails[k] = false
        end
    else
        fails[k] = false
    end
end

return { Pass = pass, Fails = fails }