-- @Date    : 2015-10-29 02:09:50
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local cjson = require "common.simdis_json"

local json = cjson:new()
ngx.req.read_body()
local strbody = ngx.req.get_body_data()

local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M:get_table_jsondata()
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


function _M:get_string_jsondata()
	local str_body = strbody
	if not str_body then
		--ngx.say("failed to get post data:", err)
		return nil
	else
		return str_body
	end
end


function _M:new()
	local self = {}
	setmetatable(self, mt)
	return self
end

return 	_M