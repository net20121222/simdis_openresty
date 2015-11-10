-- @Date    : 2015-10-28 20:30:26
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0
local handle = require("common.simdiserr.errorinfo").handler
local tbl = {"alpha","beta", "gamma"}
local ab = {a=1,b="sssdfsd",c={c1=1,c2=2},d={10,11},100}

local function test(value)
	for k,v in pairs(value) do
		if "table" == type(v) then
    		test(v)	
		else
			print(k,":",v)
		end
    end
end

local function is_number(n, ...)
    local arg = {...}
    print("n:",n)
    print(#arg)
    local num
    for _,v in ipairs(arg) do
        num = tonumber(v)
        if nil == num then
            return false
        end
    end

    return true
end


test(handle("5678"))