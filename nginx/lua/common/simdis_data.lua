-- @Date    : 2015-10-29 02:09:50
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local cjson = require "common.simdis_json"

local json = cjson:new()
ngx.req.read_body()
local strbody = ngx.req.get_body_data()
local say = ngx.say

local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M.get_table_jsondata(self)
	local str_body = strbody
	if not str_body then
		--ngx.say("failed to get post data:", err)
		return nil
	end

	local value, err = json:json_decode(str_body)
	if not value then
	    --ngx.say("body is post data")
	    return nil
	else
	    return value
	end
end


function _M.get_string_jsondata(self)
	local str_body = strbody
	if not str_body then
		--ngx.say("failed to get post data:", err)
		return nil
	else
		return str_body
	end
end


function _M.print_jsontable(self,value)
	if type(value) ~= "table" then
		return
	end
	for k,v in pairs(value) do
		if "table" == type(v) then
    		self:print_jsontable(v)	
		else
			ngx.say(k,":",v)
		end
    end
end


function _M.get_tablelen(self,value)
	if type(value) ~= "table" then
		return 0
	end
	local count = 0
	for _,v in pairs(value) do
		count = count + 1
    end
    return count
end


-- 对输入参数逐个进行校验，只要有一个不是数字类型，则返回 false
function _M.is_number(self,n, ...)
    local arg = {...}

    local num
    for _,v in ipairs(arg) do
        num = tonumber(v)
        if nil == num then
            return false
        end
    end

    return true
end


-- 对输入参数逐个进行校验，只要有一个不是数字类型，则返回 false
function _M.is_ip(self,n, ...)
    local arg = {...}
    --[[
    local num
    for _,v in ipairs(arg) do
        num = tonumber(v)
        if nil == num then
            return false
        end
    end
	--]]
    return true
end


function _M.say_err(self,tab_info,str_code)
	tab_info["errdetail"] = str_code
	local value = json:json_encode(tab_info)
	say(value)
end


function _M.new(self)
	return setmetatable({}, mt)
end

return 	_M