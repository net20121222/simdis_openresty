-- @Date    : 2015-10-27 23:00:34
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0
-- example	: curl -l -H "Content-type: application/json" -X POST -d '{"sim_md5":1,"sim_url":"ssasasas","sim_opcmd":"asd","sim_storepath":"123","sim_server":"sd","sim_filesize":123,"sim_servertype":"asd","sim_itemid":12,"sim_taskinfo":[{"sim_peerip":123123,"sim_taskid":123},{"sim_peerip":12312223222,"sim_taskid":123333}]}' '127.0.0.1/rcsapi/job/addtask'

local redis = require "common.simdis_redis"
local datas = require "common.simdis_data"
local cjson = require "common.simdis_json"

local red = redis:new()
local data = datas:new()
local json = cjson:new()

local ERRORINFO	= require('common.simdiserr.errorinfo').info
local errorhandle = require("common.simdiserr.errorhandle")

local eval_info = [[
	local result = redis.call('hexists',"taskinfo",KEYS[1])
	if tonumber(result) == 0 then
		redis.call('hset',"taskinfo",KEYS[1],KEYS[2])
	else
		local info= redis.call('hget',"taskinfo",KEYS[1])
		local tab_info = cjson.decode(info)
		tab_info["sim_taskid"][tostring(KEYS[3])] = tonumber(KEYS[3])
		local str_info = cjson.encode(tab_info)
		redis.call('hset',"taskinfo",KEYS[1],str_info)
	end
	return 0
]]


function check_api(basicTaskInfo)
	--check post task basic info
	if not basicTaskInfo.sim_md5 or basicTaskInfo.sim_md5 == ngx.null then 
		return nil,"necessary md5 info missing"
	end
	if not basicTaskInfo.sim_url or basicTaskInfo.sim_url == ngx.null then 
		return nil,"necessary url info missing"
	end
	if not basicTaskInfo.sim_opcmd or basicTaskInfo.sim_opcmd == ngx.null then 
		return nil,"necessary opcmd info missing"
	end
	if not basicTaskInfo.sim_storepath or basicTaskInfo.sim_storepath == ngx.null then 
		return nil,"necessary storepath info missing"
	end
	if not basicTaskInfo.sim_server or basicTaskInfo.sim_server == ngx.null then 
		return nil,"necessary server info missing"
	end
	if not basicTaskInfo.sim_filesize or basicTaskInfo.sim_filesize == ngx.null then 
		return nil,"necessary filesize info missing"
	end
	if not basicTaskInfo.sim_servertype or basicTaskInfo.sim_servertype == ngx.null then 
		return nil,"necessary servertype info missing"
	end
	if not basicTaskInfo.sim_itemid or basicTaskInfo.sim_itemid == ngx.null then 
		return nil,"necessary itemid info missing"
	end
	return 0,nil
end


local 
function dealhandle()
	-- post json date
	local tab_json = data:get_table_jsondata()
	if not tab_json or not tab_json.task_detailinfo then
		local info = ERRORINFO.RCS_ERROR
		local desc = "post null or no task_detailinfo info"
		local response = errorhandle.sim_resp(info, desc)
		errorhandle.sim_log(info, desc)
		ngx.say(response)
		return 
	end

	local tab_taskdetailinfo = tab_json.task_detailinfo
	for _,taskinfo_values in pairs(tab_taskdetailinfo) do
		repeat
			-- basic task info(md5,url,opcmd,storepath,servers,filesize,servertype,itemid)
			local basicTaskInfo = {}

			-- get md5 info
			basicTaskInfo["sim_md5"] = taskinfo_values["sim_md5"]
			-- get url info
			basicTaskInfo["sim_url"] = taskinfo_values["sim_url"]
			-- get opcmd info
			basicTaskInfo["sim_opcmd"] = taskinfo_values["sim_opcmd"]
			-- get storepath
			basicTaskInfo["sim_storepath"] = taskinfo_values["sim_storepath"]
			-- get server info 
			basicTaskInfo["sim_server"] = taskinfo_values["sim_server"]
			-- get filesize info 
			basicTaskInfo["sim_filesize"] = taskinfo_values["sim_filesize"]
			-- get servertype info 
			basicTaskInfo["sim_servertype"] = taskinfo_values["sim_servertype"]
			-- get itemid info 
			basicTaskInfo["sim_itemid"] = taskinfo_values["sim_itemid"]
			-- check basic info
			local check_result,check_status = check_api(basicTaskInfo)
			if not check_result then
				local info = ERRORINFO.RCS_ERROR
				local desc = check_status
				local response = errorhandle.sim_resp(info, desc)
				errorhandle.sim_log(info, desc)
				ngx.say(response)
				break
			end

			if not taskinfo_values["sim_ipidinfo"] or taskinfo_values["sim_ipidinfo"] == ngx.null then
				local info = ERRORINFO.RCS_ERROR
				local desc = "no task real work ip or id"
				local response = errorhandle.sim_resp(info, desc)
				errorhandle.sim_log(info, desc)
				ngx.say(response)
				break
			end

			local taskmd5 = ngx.md5(basicTaskInfo["sim_md5"]..basicTaskInfo["sim_url"]..basicTaskInfo["sim_opcmd"])
			local tab_taskinfo = taskinfo_values["sim_ipidinfo"]
			local error_ipid = add_taskinfo(taskmd5,tab_taskinfo,basicTaskInfo)
			if next(error_ipid) ~= nil then
				local info = ERRORINFO.RCS_ERROR
				local desc = "insert peerip and taskid error"
				basicTaskInfo["sim_ipidinfo"] = error_ipid
				local response = errorhandle.sim_resp(info, desc,basicTaskInfo)
				errorhandle.sim_log(info, response)
				ngx.say(response)
				break
			end
		until true
	end
end


function add_taskinfo(taskmd5,tab_taskinfo,basicTaskInfo)
	local task_info = tab_taskinfo
	local err_ipid = {}

	for _,ipidvalues in pairs(task_info) do
		repeat
			local sim_ip_checkresult = data:is_number(ipidvalues["sim_taskid"])
			local sim_id_checkresult = data:is_ip(ipidvalues["sim_peerip"])
			if not sim_ip_checkresult and not sim_ip_checkresult then
				table.insert(err_ipid, ipidvalues)
				break
			end

			local status_md5 = add_md5task(taskmd5,basicTaskInfo,ipidvalues["sim_taskid"])
			if not status_md5 then
				table.insert(err_ipid, ipidvalues)
				break
			end


			local iptask_key = "sim_peerip:"..ipidvalues["sim_peerip"]..",sim_servertype:"..basicTaskInfo["sim_servertype"]
			local status_detail = add_taskdetail(iptask_key,taskmd5,ipidvalues["sim_taskid"])
			if not status_detail then
				table.insert(err_ipid, ipidvalues)
				break
			end
		until true
	end
	return err_ipid
end


function add_md5task(taskmd5,basicTaskInfo,taskid)
	local tab_info = {}
	tab_info.sim_md5 = basicTaskInfo.sim_md5
	tab_info.sim_url = basicTaskInfo.sim_url
	tab_info.sim_opcmd = basicTaskInfo.sim_opcmd
	tab_info.sim_storepath = basicTaskInfo.sim_storepath
	tab_info.sim_server = basicTaskInfo.sim_server
	tab_info.sim_filesize = basicTaskInfo.sim_filesize
	tab_info.sim_servertype = basicTaskInfo.sim_servertype
	tab_info.sim_itemid = basicTaskInfo.sim_itemid
	tab_info.sim_taskid = {}

	tab_info["sim_taskid"][taskid] = tonumber(taskid)
	local str_basicinfo = json:json_encode(tab_info)
	local status, errinfo = red:eval(eval_info,3,taskmd5,str_basicinfo,taskid)
	if not status then
		ngx.say("failed to add_md5task: ", errinfo)
		return false
	end
	return true
end


function add_taskdetail(iptaskkey,taskmd5,taskid)
	local iptaskwait = iptaskkey..",wait"
	local iptask_value = {}
	iptask_value["sim_taskmd5"] = taskmd5
	iptask_value["sim_numdeal"] = 0
	iptask_value["sim_startime"] = 0
	iptask_value["sim_endtime"] = 0
	iptask_value["sim_taskstate"] = 0
	iptask_value["sim_speed"] = 0
	local iptask_strvalue
	local result,err = red:hexists(iptaskkey,taskid)
	if result == 0 then
		iptask_strvalue = json:json_encode(iptask_value)
	else
		--[[
		-- maybe do something when task is failed
		local ok,err = red:hget(iptask_key,iptask_field)
		if ok then
			local jsontabinfo = json:json_decode(ok)
			-- task is failed
			if 3 == jsontabinfo["taskstate"] then

			end
			local jsonstrinfo = json:json_encode(jsontabinfo)
			local ok,err = red:hset("taskinfo",taskkey,jsonstrinfo)
			if not ok then 
				return -1
			end
		end
		]]--
	end
	if not iptask_strvalue then
		return true
	end
	local ok, err = red:hset(tostring(iptaskkey),taskid,iptask_strvalue)
	if not ok then
		ngx.say("failed to add_taskdetail: ", err)
		return false
	end
	local status = add_taskwait(iptaskwait,taskid)
	if not status then
		return false
	end
	return true
end


function add_taskwait(iptaskkey,taskid)
	local ok, err = red:lpush(tostring(iptaskkey), taskid)
	if not ok then
		ngx.say("failed to add_taskwait: ", err)
		return false
	end
	return true
end

dealhandle()