-- @Date    : 2015-10-27 23:11:09
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.redis_iresty"
local json = require("cjson")


local red = redis:new()
local ok, err = red:set("cat", "an ssss")
if not ok then
    ngx.say("failed to set dog: ", err)
    return
end

ngx.say("set result: ", ok)