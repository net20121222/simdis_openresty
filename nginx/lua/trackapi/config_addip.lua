-- @Date    : 2015-10-27 23:11:09
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local function print_jsontable(value)
	if type(value) ~= "table" then
		return
	end
	for k,v in pairs(value) do
		if "table" == type(v) then
    		print_jsontable(v)	
		else
			ngx.say(k,":",v)
		end
    end
end

local tab_json = data:get_table_jsondata()
--[[
ngx.say(string_json)
if tab_json then
	print_jsontable(tab_json)
else
	ngx.say("nil")
end
]]--

local x = json:json_encode(tab_json)
local ok, err = red:sadd("test", x)
if not ok then
    ngx.say("failed to set dog: ", err)
    return
end
ngx.say("set result: ", ok)
local ok, err = red:smembers ("test")
if not ok then
    ngx.say("failed to set dog: ", err)
    return
end
ngx.say("get result: ", ok)

