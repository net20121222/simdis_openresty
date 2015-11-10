-- @Date    : 2015-11-10 01:18:30
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0
local local cjson = require "common.simdis_json"
local json = cjson:new()
local _M = {}

_M._VERSION = '0.0.1'

_M.info = {
    --	index			    code    desc
    --	SUCCESS
    ["SUCCESS"]			= { 200,   'success '},
    
    --	System Level ERROR
    ['REDIS_ERROR']		= { 40101, 'redis error for '},
    
    --  unknown reason
    ['UNKNOWN_ERROR']		= { 50501, 'unknown reason '},
}


function _M.handler(errinfo)
    local info 
    if type(errinfo) == 'table' then
        info = errinfo
    elseif type(errinfo) == 'string' then
        info = {{ 30101, 'api error '}, errinfo}
    else
        info = {{ 50501, 'unknown reason '}, }
    end
    local errstack = "1234"
    --local errstack = debug.traceback()
    return {info, errstack}
end

function _M.sim_log(info, desc, data, errstack)
    local errlog = ''
    local code, err = info[1], info[2]
    local errcode = code
    local errinfo = desc and err..desc or err 
    
    errlog = errlog .. ' errcode : '..errcode
    errlog = errlog .. ', errinfo : '..errinfo
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
    response.errcode = code
    response.errinfo = desc and err..desc or err 
    if data then 
        response.data = data 
    end
    
    return json:json_encode(response)
end

return _M