-- @Date    : 2015-11-02 22:32:24
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local args = ngx.var.args

local
function dealhandle()
	local tab_args = args
	local tab_taskid = {}

	if #tab_args ~= 6 then
		return -1
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

	if 0 == tab_args["gettype"] then
		tab_taskid = get_taskdeal(tab_args)
	elseif 1 ==  tab_args["gettype"] then
		tab_taskid = get_taskwait(tab_args)
	else
		return -1
	end


end


function get_taskdeal()
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskdeal_key = task_key..",sim_deal"

	local waittask_deal = 0
	local waittask_len,err = red:lrange(taskwait_key,0,100)
	if not waittask_len then
		return -1
	end
end


function get_taskwait()
	local tab_waittaskid = {}
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskwait_key = task_key..",sim_wait"
	local taskdeal_key = task_key..",sim_deal"
	local sim_cpunum = tab_args.cpunum
	local sim_pid = tab_args.pid

	local max_deal = 100
	if tab_args["leftnum"] < 100 then
		max_deal = tab_args["leftnum"]
	end 

	local waittask_deal = 0
	local waittask_len,err = red:llen(taskwait_key)
	if not waittask_len then
		return -1
	end
	if tonumber(waittask_len) == 0 then
		return 0
	end

	repeat
		waittask_deal = waittask_deal + 1
		local task_id, task_err = red:eval([[
	    	local taskid = redis.call('rpop', KEYS[1])
	    	if (taskid % KEYS[3]) == KEYS[4] then
	    		redis.call('lpush', KEYS[2],taskid)
	    		return taskid
	    	else:
	    		redis.call('lpush', KEYS[1],taskid)
	    		return nil
	    	end
	    	]], 3, taskwait_key,taskdeal_key,sim_cpunum,sim_pid)
		if task_id then
			max_deal = max_deal - 1
			table.insert(tab_waittaskid, task_id)
		end
		if waittask_deal > waittask_len then
			break
		end
	until(max_deal < 0)

	return tab_waittaskid
end