-- @Date    : 2015-10-27 23:11:09
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local ERRORINFO	= require('common.simdiserr.errorinfo').info
local errorhandle = require("common.simdiserr.errorhandle")

local tab_json = data:get_table_jsondata()

local test = '{"report_detailinfo":[{"opcmd":asd,"storepath":"test","server":"123","taskstate":4,"numdeal":5,"speed":132,"startime":"123123","endtime":"1234124","servertype":"asd","peerip":"123123","taskid":123,"parentip":"123123"}]}'
local ok,err = json:json_decode(test)


if ok then
	print_jsontable(ok)
else
	ngx.say("nil:",err)
end

--local tab_json = {asd="test",{1,2,3}}
--data:print_jsontable(tab_json)
--local x = json:json_encode(tab_json)

--local testjson = [[{"task_detailinfo":[{"url":"test_url","ipidinfo":[{"ip":"testip","id":"testid"}]}]}]]

--local x = json:json_decode(testjson)
--data:print_jsontable(x)

--[[
local test11 = {"a","b","c","d","e","f","g"}
local ok, err = red:hget("test","12a053d8ac439fb011fe1c61cbe1f732")
if not ok then
    ngx.say("failed to set test: ", err)
    return
end
ngx.say(ok)
]]--

