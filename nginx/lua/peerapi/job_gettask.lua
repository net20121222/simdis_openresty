-- @Date    : 2015-11-02 22:32:24
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0
-- @example : 
--			curl "127.0.0.1/peerapi/job/gettask?cpunum=12&pid=3&leftnum=10&servertype=asd&peerip=123123&gettype=0"
--			{"errcode":200,"errinfo":"success ","data":[{"sim_md5":1,"sim_taskid":"123","sim_filesize":123,"sim_url":"www.baidu.com\/checknull?a=4&b=4"},{"sim_md5":1,"sim_taskid":"15","sim_filesize":123,"sim_url":"www.baidu.com\/checknull?a=4&b=4"}]}

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local ERRORINFO	= require('common.simdiserr.errorinfo').info
local errorhandle = require("common.simdiserr.errorhandle")

local args = ngx.req.get_uri_args()


function check_api()
	local tab_args = args
	if data:get_tablelen(tab_args) ~= 6 then
		return nil,"necessary args size is six"
	end
	if not tab_args["cpunum"] then
		return nil,"necessary cpunum info missing"
	end
	if not tab_args["pid"] then
		return nil,"necessary pid info missing"
	end
	if not tab_args["leftnum"] then
		return nil,"necessary leftnum info missing"
	end
	if not tab_args["servertype"] then
		return nil,"necessary servertype info missing"
	end
	if not tab_args["peerip"] then
		return nil,"necessary peerip info missing"
	end
	if not tab_args["gettype"] then
		return nil,"necessary gettype info missing"
	end
	return 0,nil
end


local
function dealhandle()
	local tab_args = args
	local str_taskidinfo = {}
	local check_result,check_err = check_api()
	if not check_result then
		local info = ERRORINFO.PEER_ERROR
		local desc = check_err
		local response = errorhandle.sim_resp(info, desc)
		errorhandle.sim_log(info, desc)
		ngx.say(response)
		return 
	end
	
	if 0 == tonumber(tab_args["gettype"]) then
		str_taskidinfo = get_dealtask() 
	elseif 1 ==  tonumber(tab_args["gettype"]) then
		str_taskidinfo = get_waittask() 
	else
		local info = ERRORINFO.PEER_ERROR
		local desc = "gettype num is not 0 either 1"
		local response = errorhandle.sim_resp(info, desc)
		errorhandle.sim_log(info, desc)
		ngx.say(response)
		return 
	end

	if str_taskidinfo ~= nil and next(str_taskidinfo) ~= nil then
		local info = ERRORINFO.SUCCESS
		local response = errorhandle.sim_resp(info, "",str_taskidinfo)
		ngx.say(response)
	else
		local info = ERRORINFO.PEER_ERROR
		local desc = "num work to deal"
		local response = errorhandle.sim_resp(info, desc)
		ngx.say(response)	
	end
end


function get_dealtask()
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskdeal_key = task_key..",sim_deal"
	local sim_cpunum = tonumber(tab_args.cpunum)
	local sim_pid = tonumber(tab_args.pid)
	local max_deal = 10000

	local table_realtask = {}
	local table_taskid,taskiderr = red:lrange(taskdeal_key,0,max_deal)
	if not table_taskid then
		local info = ERRORINFO.RCS_ERROR
		local desc = taskiderr
		errorhandle.sim_log(info, desc)	
		return table_realtask
	end

	for _,taskid_value in pairs(table_taskid) do
		repeat
			local sig_taskinfo = {}

			local pid = tonumber(taskid_value) % sim_cpunum
			if pid ~= sim_pid then
				break
			end

			local str_taskinfo,taskinfoerr = red:hget(task_key,taskid_value)
			if not str_taskinfo then
				local info = ERRORINFO.RCS_ERROR
				local desc = taskinfoerr
				errorhandle.sim_log(info, desc)	
				break
			end
			local tab_taskinfo = json:json_decode(str_taskinfo)
			local sim_taskmd5 = tab_taskinfo["sim_taskmd5"]
			tab_taskinfo["sim_numdeal"] = tonumber(tab_taskinfo.sim_numdeal or 0) + 1
			tab_taskinfo["sim_taskstate"] = 1
			local str_settaskinfo = json:json_encode(tab_taskinfo)
			local result,err = red:hset(task_key,taskid_value,str_settaskinfo)
			if not result then
				local info = ERRORINFO.RCS_ERROR
				local desc = err
				errorhandle.sim_log(info, desc)	
				break
			end

			local str_info,infoerr = red:hget("taskinfo",sim_taskmd5)
			if not str_info then
				local info = ERRORINFO.RCS_ERROR
				local desc = infoerr
				errorhandle.sim_log(info, desc)
				break
			end
			local tab_info = json:json_decode(str_info)
			sig_taskinfo["sim_url"] = tab_info["sim_url"]
			sig_taskinfo["sim_filesize"] = tab_info["sim_filesize"]
			sig_taskinfo["sim_md5"] = tab_info["sim_md5"]
			sig_taskinfo["sim_taskid"] = taskid_value
			table.insert(table_realtask, sig_taskinfo)
		until true
	end
	return table_realtask
end

function get_waittask()
	local table_realtask = {}
	local tab_args = args
	local task_key = "sim_peerip:"..tab_args["peerip"]..",sim_servertype:"..tab_args["servertype"]
	local taskwait_key = task_key..",sim_wait"
	local taskdeal_key = task_key..",sim_deal"
	local sim_cpunum = tonumber(tab_args.cpunum)
	local sim_pid = tonumber(tab_args.pid)
	local time = tostring(ngx.time())

	local max_deal = 1000
	if tonumber(tab_args["leftnum"]) < max_deal then
		max_deal = tonumber(tab_args["leftnum"])
	end 

	local table_taskid,id_err = red:lrange(taskwait_key,0,max_deal)
	if not table_taskid then
		local info = ERRORINFO.RCS_ERROR
		local desc = id_err
		errorhandle.sim_log(info, desc)	
		return table_realtask
	end

	for _,taskid_value in pairs(table_taskid) do
		repeat
			local sig_taskinfo = {}

			local pid = tonumber(taskid_value) % sim_cpunum
			if pid ~= sim_pid then
				break
			end

			red:init_pipeline()
			red:lrem(taskwait_key,1,taskid_value)
			red:lpush(taskdeal_key,taskid_value)
			local result,err = red:commit_pipeline()
			if not result then
				local info = ERRORINFO.RCS_ERROR
				local desc = err
				errorhandle.sim_log(info, desc)
				break
			end

			local str_taskinfo,taskinfoerr= red:hget(task_key,taskid_value)
			if not str_taskinfo then
				local info = ERRORINFO.RCS_ERROR
				local desc = taskinfoerr
				errorhandle.sim_log(info, desc)
				break
			end

			local tab_taskinfo = json:json_decode(str_taskinfo)
			local sim_taskmd5 = tab_taskinfo["sim_taskmd5"]
			tab_taskinfo["sim_startime"] = time
			tab_taskinfo["sim_numdeal"] = tonumber(tab_taskinfo.sim_numdeal or 0) + 1
			tab_taskinfo["sim_taskstate"] = 1
			local str_settaskinfo = json:json_encode(tab_taskinfo)
			local str_settaskinfo,taskinfoerr= red:hset(task_key,taskid_value,str_settaskinfo)
			if not result then
				local info = ERRORINFO.RCS_ERROR
				local desc = taskinfoerr
				errorhandle.sim_log(info, desc)
				break
			end

			local str_info,infoerr = red:hget("taskinfo",sim_taskmd5)
			if not str_info then
				local info = ERRORINFO.RCS_ERROR
				local desc = infoerr
				errorhandle.sim_log(info, desc)
				break
			end
			local tab_info = json:json_decode(str_info)
			sig_taskinfo["sim_url"] = tab_info["sim_url"]
			sig_taskinfo["sim_filesize"] = tab_info["sim_filesize"]
			sig_taskinfo["sim_md5"] = tab_info["sim_md5"]
			sig_taskinfo["sim_taskid"] = taskid_value
			table.insert(table_realtask, sig_taskinfo)
		until true
	end
	
	return table_realtask
end


dealhandle()