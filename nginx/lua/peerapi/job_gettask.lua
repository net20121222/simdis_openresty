-- @Date    : 2015-11-02 22:32:24
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local state_handing = 1
local args = ngx.req.get_uri_args()

local str_waiteval = [[
	local table_realtask = {}
	local limit_len = tonumber(KEYS[5])
	local wait_len = redis.call('llen', KEYS[1])
	if wait_len > limit_len then
		wait_len = limit_len
	else
		wait_len = -1
	end
	
	local table_taskid = redis.call('lrange',KEYS[1],0,wait_len)
	for _,taskid_value in pairs(table_taskid) do
		repeat
			local sig_taskinfo = {}

			local pid = tonumber(taskid_value) % tonumber(KEYS[3])
			if pid ~= tonumber(KEYS[4]) then
				break
			end
			redis.call('lrem',KEYS[1],1,taskid_value)
			redis.call('lpush',KEYS[2],taskid_value)

			local str_taskinfo = redis.call('hget',KEYS[6],taskid_value)
			local tab_taskinfo = cjson.decode(str_taskinfo)
			local sim_taskmd5 = tab_taskinfo["sim_taskmd5"]
			tab_taskinfo["sim_startime"] = KEYS[7]
			tab_taskinfo["sim_numdeal"] = tonumber(tab_taskinfo.sim_numdeal or 0) + 1
			tab_taskinfo["sim_taskstate"] = 1
			local str_settaskinfo = cjson.encode(tab_taskinfo)
			redis.call('hset',KEYS[6],taskid_value,str_settaskinfo)

			local str_info = redis.call('hget',"taskinfo",sim_taskmd5)
			local tab_info = cjson.decode(str_info)
			sig_taskinfo["sim_url"] = tab_info["sim_url"]
			sig_taskinfo["sim_filesize"] = tab_info["sim_filesize"]
			sig_taskinfo["sim_md5"] = tab_info["sim_md5"]
			sig_taskinfo["sim_taskid"] = taskid_value
			table.insert(table_realtask, sig_taskinfo)
		until true
	end
	local str_realtask = cjson.encode(table_realtask)
	return str_realtask
]]

local str_dealeval = [[
	local table_realtask = {}

	local limit_len = tonumber(KEYS[4])
	local wait_len = redis.call('llen', KEYS[1])
	if wait_len > limit_len then
		wait_len = limit_len
	else
		wait_len = -1
	end
	
	local table_taskid = redis.call('lrange',KEYS[1],0,wait_len)
	for _,taskid_value in pairs(table_taskid) do
		repeat
			local sig_taskinfo = {}

			local pid = tonumber(taskid_value) % tonumber(KEYS[2])
			if pid ~= tonumber(KEYS[3]) then
				break
			end

			local str_taskinfo = redis.call('hget',KEYS[5],taskid_value)
			local tab_taskinfo = cjson.decode(str_taskinfo)
			local sim_taskmd5 = tab_taskinfo["sim_taskmd5"]
			tab_taskinfo["sim_numdeal"] = tonumber(tab_taskinfo.sim_numdeal or 0) + 1
			tab_taskinfo["sim_taskstate"] = 1
			local str_settaskinfo = cjson.encode(tab_taskinfo)
			redis.call('hset',KEYS[5],taskid_value,str_settaskinfo)

			local str_info = redis.call('hget',"taskinfo",sim_taskmd5)
			local tab_info = cjson.decode(str_info)
			sig_taskinfo["sim_url"] = tab_info["sim_url"]
			sig_taskinfo["sim_filesize"] = tab_info["sim_filesize"]
			sig_taskinfo["sim_md5"] = tab_info["sim_md5"]
			sig_taskinfo["sim_taskid"] = taskid_value
			table.insert(table_realtask, sig_taskinfo)
		until true
	end
	local str_realtask = cjson.encode(table_realtask)
	return str_realtask
]]


function check_api()
	local tab_args = args
	if data:get_tablelen(tab_args) ~= 6 then
		return -1
	end
	if not tab_args["cpunum"] then
		return -1
	end
	if not tab_args["pid"] then
		return -1
	end
	if not tab_args["leftnum"] then
		return -1
	end
	if not tab_args["servertype"] then
		return -1
	end
	if not tab_args["peerip"] then
		return -1
	end
	if not tab_args["gettype"] then
		return -1
	end
	return 0
end

local
function dealhandle()
	local tab_args = args
	local str_taskidinfo
	local check_result = check_api()
	if check_result == -1 then
		return 
	end
	

	if 0 == tonumber(tab_args["gettype"]) then
		str_taskidinfo = get_taskdeal() 
	elseif 1 ==  tonumber(tab_args["gettype"]) then
		str_taskidinfo = get_taskwait() 
	else
		return 
	end
	ngx.say(str_taskidinfo)
	--[[
	if next(tab_taskid) ~= nil then
		local jsondata = json:json_encode(tab_taskid)
		if jsondata then
			ngx.say("jsondata",jsondata)
		else
			ngx.say("json error")
		end
	else
		ngx.say("task id nil")
	end
	]]--
	
end


function get_taskdeal()
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskdeal_key = task_key..",sim_deal"
	local sim_cpunum = tonumber(tab_args.cpunum)
	local sim_pid = tonumber(tab_args.pid)
	local max_deal = 10000

	local tab_waittaskidinfo, task_err = red:eval(str_dealeval, 5,taskdeal_key,sim_cpunum,sim_pid,max_deal,task_key)
	if not tab_waittaskidinfo then
		ngx.say("task_err:",task_err)
	end

	return tab_waittaskidinfo
end


function get_taskwait()
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskwait_key = task_key..",sim_wait"
	local taskdeal_key = task_key..",sim_deal"
	local sim_cpunum = tab_args.cpunum
	local sim_pid = tab_args.pid
	local time = tostring(ngx.time())

	local max_deal = 1000
	if tonumber(tab_args["leftnum"]) < max_deal then
		max_deal = tonumber(tab_args["leftnum"])
	end 

	local tab_waittaskidinfo, task_err = red:eval(str_waiteval, 7, taskwait_key,taskdeal_key,sim_cpunum,sim_pid,max_deal,task_key,time)
	if not tab_waittaskidinfo then
		ngx.say("task_err:",task_err)
	end
	return  tab_waittaskidinfo
end

dealhandle()