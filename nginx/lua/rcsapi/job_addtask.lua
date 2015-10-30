-- @Date    : 2015-10-27 23:00:34
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

-- get task info

-- data:md5str
-- data:sopcmd
-- data:surl
-- data:storepath
-- data:servers
-- data:filesize
-- data:server_type
-- data:itemid
-- data:ipinfo

-- 
local redis = require "common.simdis_redis"

local red = redis:new()
local ok, err = red:set("cat", "an ssss")
if not ok then
    ngx.say("failed to set dog: ", err)
    return
end

ngx.say("set result: ", ok)
