-- @Date    : 2015-10-27 23:11:09
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()


--local tab_json = data:get_table_jsondata()
--[[
ngx.say(string_json)
if tab_json then
	print_jsontable(tab_json)
else
	ngx.say("nil")
end
]]--
--local tab_json = {asd="test",{1,2,3}}
--data:print_jsontable(tab_json)
--local x = json:json_encode(tab_json)



ngx.say("ok: ", 1)

local test11 = {"a","b","c","d","e","f","g"}
local ok, err = red:hget("taskinfo","12a053d8ac439fb011fe1c61cbe1f732")
if not ok then
    ngx.say("failed to set test: ", err)
    return
end
local b = {"12","sw"}
local a["1"] = b
ngx.say("ok: ", a)

