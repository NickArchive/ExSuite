local reg = getreg()
if reg._ExSuiteLoaded then return unpack(reg._ExSuite); end

local ExSuite = {}
reg._ExSuite = ExSuite

