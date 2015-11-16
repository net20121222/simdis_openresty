-- @Date    : 2015-11-13 00:27:18
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


local eval_del = [[
	local taskinfo = redis.call('lrem',KEYS[1],1,KEYS[2])
	if taskinfo == 0 then
		return nil
	end
	local len = redis.call('rpush',KEYS[3],KEYS[2]) 
	return len
]]

local eval_modify = [[
	local taskinfo = redis.call('hget',KEYS[1],KEYS[2])
	local tab_taskinfo = cjson.decode(taskinfo)
	tab_taskinfo.sim_numdeal = tonumber(tab_taskinfo.sim_numdeal) + tonumber(KEYS[4])
	tab_taskinfo.sim_taskstate = KEYS[5]
	tab_taskinfo.sim_endtime = KEYS[3]
	tab_taskinfo.sim_speed = KEYS[6]
	local set_taskinfo = cjson.encode(tab_taskinfo)
	redis.call('hset',KEYS[1],KEYS[2],set_taskinfo)
	return 0
]]

local function dealhandle()
	local tab_json = data:get_table_jsondata()
	if not tab_json or not tab_json.report_detailinfo then
		local info = ERRORINFO.PEER_ERROR
		local desc = "post null or no report detail info"
		local response = errorhandle.sim_resp(info, desc)
		errorhandle.sim_log(info, desc)
		ngx.say(response)
		return 
	end

	local result = deal_report(tab_json.report_detailinfo)
	if next(result) ~= nil then
		local info = ERRORINFO.PEER_ERROR
		local desc = "report detail task error"
		local response = errorhandle.sim_resp(info, desc,result)
		errorhandle.sim_log(info, desc)
		ngx.say(response)
	else
		local info = ERRORINFO.SUCCESS
		local response = errorhandle.sim_resp(info)
		ngx.say(response)
	end
end


function check_lineinfo(report_info)
	if not report_info.opcmd then
		return nil,"necessary opcmd info missing"
	end
	if not report_info.storepath then
		return nil,"necessary storepath info missing"
	end
	if not report_info.server then
		return nil,"necessary server info missing"
	end
	if not report_info.taskstate then
		return nil,"necessary taskstate info missing"
	end
	if not report_info.numdeal then
		return nil,"necessary numdeal info missing"
	end
	if not report_info.speed then
		return nil,"necessary speed info missing"
	end
	if not report_info.startime then
		return nil,"necessary startime info missing"
	end
	if not report_info.endtime then
		return nil,"necessary endtime info missing"
	end
	if not report_info.servertype then
		return nil,"necessary servertype info missing"
	end
	if not report_info.peerip then
		return nil,"necessary peerip info missing"
	end
	if not report_info.taskid then
		return nil,"necessary taskid info missing"
	end
	if not report_info.parentip then
		return nil,"necessary parentip info missing"
	end
	return 0,nil
end


function deal_report(tab_reportinfo)
	local count_num = 0
	local err_info = {}
	for _,report_info in pairs(tab_reportinfo) do
		repeat
			if count_num > 5000 then
				table.insert(err_info, report_info)
				local info = ERRORINFO.PEER_ERROR
				local desc = "more reportinfo(maxsize is 5000)"
				errorhandle.sim_log(info, desc)
				break
			end
			local check_result,check_err = check_lineinfo(report_info)
			if not check_result then
				local info = ERRORINFO.PEER_ERROR
				local desc = check_err
				errorhandle.sim_log(info, desc)
				table.insert(err_info, report_info)
				break
			end

			local del_result,del_err = del_reportinfo(report_info)
			if not del_result then
				local info = ERRORINFO.PEER_ERROR
				local desc = del_err
				errorhandle.sim_log(info, desc)
				table.insert(err_info, report_info)
				break 
			end

			local modi_result,modi_err = modify_ipinfo(report_info)
			if not modi_result then
				local info = ERRORINFO.PEER_ERROR
				local desc = modi_err
				errorhandle.sim_log(info, desc)
				table.insert(err_info, report_info)
				break 
			end
			count_num = count_num + 1
		until true
	end
	return err_info
end


function del_reportinfo(report_info)
	local ipinfokey = "sim_peerip:"..report_info.peerip..",sim_servertype:"..report_info.servertype
	local donekey = ipinfokey..",sim_done"
	local dealkey = ipinfokey..",sim_deal"
	local taskid = report_info.taskid

	local result,err = red:eval(eval_del,3,dealkey,taskid,donekey)
	if not result and not err then
		result = 0
		local info = ERRORINFO.PEER_ERROR
		local desc = taskid..":taskid is not in deal list"
		errorhandle.sim_log(info, desc)
	end
	return result,err
end


function modify_ipinfo(report_info)
	local ipinfokey = "sim_peerip:"..report_info.peerip..",sim_servertype:"..report_info.servertype
	local endtime = report_info.endtime
	local taskid = report_info.taskid
	local numdeal = report_info.numdeal
	local taskstate = report_info.taskstate
	local speed = report_info.speed

	local result,err = red:eval(eval_modify,6,ipinfokey,taskid,endtime,numdeal,taskstate,speed)
	return result,err
end

dealhandle()