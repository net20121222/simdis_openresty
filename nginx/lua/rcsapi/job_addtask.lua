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


local 
function dealhandle()
	-- basic task info(md5,url,opcmd,storepath,servers,filesize,servertype,itemid)
	local basicTaskInfo = {} 
	-- post json date
	local tab_json = data:get_table_jsondata()
	-- get md5 info
	if tab_json["sim_md5"] then
		basicTaskInfo["sim_md5"] = tab_json["sim_md5"]
	end
	-- get url info
	if tab_json["sim_url"] then
		basicTaskInfo["sim_url"] = tab_json["sim_url"]
	end
	-- get opcmd info
	if tab_json["sim_opcmd"] then
		basicTaskInfo["sim_opcmd"] = tab_json["sim_url"]
	end
	-- get storepath
	if tab_json["sim_storepath"] then
		basicTaskInfo["sim_storepath"] = tab_json["sim_storepath"]
	end
	-- get server info 
	if tab_json["sim_server"] then
		basicTaskInfo["sim_server"] = tab_json["sim_server"]
	end
	-- get filesize info 
	if tab_json["sim_filesize"] then
		basicTaskInfo["sim_filesize"] = tab_json["sim_filesize"]
	end
	-- get servertype info 
	if tab_json["sim_servertype"] then
		basicTaskInfo["sim_servertype"] = tab_json["sim_servertype"]
	end
	-- get itemid info 
	if tab_json["sim_itemid"] then
		basicTaskInfo["sim_itemid"] = tab_json["sim_itemid"]
	end
	
	if tab_json["sim_taskinfo"] then
		local taskMD5 = ngx.md5(basicTaskInfo["sim_md5"]..basicTaskInfo["sim_url"]..basicTaskInfo["sim_opcmd"])
		local tab_taskinfo = tab_json["sim_taskinfo"]

		for _,taskipinfo in pairs(tab_taskinfo) do
			repeat
				local sim_ip_checkresult = data:is_number(taskipinfo["sim_taskid"])
				local sim_id_checkresult = data:is_ip(taskipinfo["sim_peerip"])
				if not sim_ip_checkresult and not sim_ip_checkresult then
					local tab_err = basicTaskInfo
					tab_err["sim_peerip"] = taskipinfo["sim_peerip"]
					tab_err["sim_taskid"] = taskipinfo["sim_taskid"]
					data:say_err(tab_err,"check error")
					break
				end
				-- get work task info
				local jsonstrinfo = get_addtaskinfo(taskipinfo["sim_taskid"],basicTaskInfo,taskMD5)
				-- get add ip task info
				local iptaskkey = "sim_peerip:"..taskipinfo["sim_peerip"]..",sim_servertype:"..basicTaskInfo["sim_servertype"]
				local str_iptask,str_wait = get_addiptaskinfo(iptaskkey,taskipinfo["sim_taskid"],taskMD5)
				--if str_iptask == nil or str_wait == nil or jsonstrinfo == nil then
				if jsonstrinfo == nil then
					local tab_err = basicTaskInfo
					tab_err["sim_peerip"] = taskipinfo["sim_peerip"]
					tab_err["sim_taskid"] = taskipinfo["sim_taskid"]
					data:say_err(tab_err,"get error")
					break
				end

				local set_taskresult = set_addtaskinfo(taskMD5,jsonstrinfo)
				local set_iptaskresult = set_addiptaskinfo(iptaskkey,str_iptask,str_wait)
				if not set_taskresult and not set_taskresult then
					local tab_err = basicTaskInfo
					tab_err["sim_peerip"] = taskipinfo["sim_peerip"]
					tab_err["sim_taskid"] = taskipinfo["sim_taskid"]
					data:say_err(tab_err,"set error")
					break
				end
			until true
		end
	end
end


function set_addtaskinfo(taskMD5,jsonstrinfo)
	if jsonstrinfo == nil or taskMD5 == nil then 
		return false
	end
	local ok, err = red:hset("taskinfo",taskMD5,jsonstrinfo)
	if not ok then
    	ngx.say("failed to set taskinfo: ", err)
    	return false
	end
	return true
end


function set_addiptaskinfo(iptaskkey,str_iptask,str_wait)
	if iptaskkey == nil or str_iptask == nil or str_wait == nil then 
		return false
	end

	local iptask_wait = iptaskkey..",sim_wait"

	local ok, err = red:hset(tostring(iptaskkey),str_wait,str_iptask)
	if not ok then
		ngx.say("failed to set iptaskkey: ", err)
		return false
	end

	local ok, err = red:lpush(tostring(iptask_wait), str_wait)
	if not ok then
		ngx.say("failed to set taskinfo: ", err)
		return false
	end
	return true
end


-- get add task info hash in redis
function get_addtaskinfo(sim_taskid,basicTaskInfo,taskMD5)
	local taskkey = taskMD5
	local taskinfo = basicTaskInfo
	local result,err = red:hexists("taskinfo",taskkey)
	local jsonstrinfo
	-- task is not set 
	if result == 0 then
		local tab_taskid = {}
		tab_taskid[tostring(sim_taskid)] = sim_taskid
		taskinfo["sim_taskid"] = tab_taskid
		jsonstrinfo = json:json_encode(taskinfo)
	-- task has been set 
	else
		local ok,err = red:hget("taskinfo",taskkey)
		if ok then
			local jsontabinfo = json:json_decode(ok)
			jsontabinfo["sim_taskid"][tostring(sim_taskid)] = sim_taskid
			jsonstrinfo = json:json_encode(jsontabinfo)
		end
	end
	return jsonstrinfo
end


function get_addiptaskinfo(iptaskkey,iptaskfield,taskMD5)
	local iptask_key = tostring(iptaskkey)
	local iptask_field = tostring(iptaskfield)
	local iptask_value = {}
	iptask_value["sim_taskmd5"] = taskMD5
	iptask_value["sim_numdeal"] = 0
	iptask_value["sim_startime"] = 0
	iptask_value["sim_endtime"] = 0
	iptask_value["sim_taskstate"] = 0
	iptask_value["sim_speed"] = 0

	local str_wait = nil
	local str_iptask = nil
	local result,err = red:hexists(iptask_key,iptask_field)
	if result == 0 then
		local jsoniptask_value = json:json_encode(iptask_value)
		str_iptask = jsoniptask_value
		str_wait = iptaskfield
	else
		--[[
		-- maybe do something when task is filed
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
	return str_iptask,str_wait
end


dealhandle()