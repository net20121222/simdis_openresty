-- @Date    : 2015-11-10 01:56:19
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0
local cjson = require "common.simdis_json"
local json = cjson:new()

local ERRORINFO = require('common.simdiserr.errorinfo').info

local _M = {}

_M._VERSION = '0.0.1'

function _M.handler(errinfo)
    local info 
    if type(errinfo) == 'table' then
        info = errinfo
    elseif type(errinfo) == 'string' then
        info = {ERRORINFO.LUA_UNKNOWN_ERROR, errinfo}
    else
        info = {ERRORINFO.UNKNOWN_ERROR, }
    end
    local errstack = debug.traceback()
    return {info, errstack}
end

function _M.sim_log(info, desc, data, errstack)
    local errlog = ''
    local code, err = info[1], info[2]
    local errcode = code
    local errinfo = desc and err..desc or err 
    
    errlog = errlog .. ' rcode : '..errcode
    errlog = errlog .. ', rinfo : '..errinfo
    if data then
        errlog = errlog .. ', extrainfo : '..data
    end
    if errstack then
        errlog = errlog .. ', errstack : '..errstack
    end
    ngx.log(ngx.ERR, errlog)
end

function _M.sim_resp(info, desc, data)
    local response = {}
    
    local code = info[1]
    local err  = info[2]
    response.rcode = code
    response.rinfo = desc and err..desc or err 
    if data then 
        response.data = data 
    end
    
    return json:json_encode(response)
end

return _M