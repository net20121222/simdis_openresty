-- @Date    : 2015-11-10 01:18:30
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local _M = {}

_M._VERSION = '0.0.1'

_M.info = {
    --	index			    code    desc
    --	SUCCESS
    ["SUCCESS"]			= { 200,   'success '},
    
    --	3th part Level ERROR
    ['REDIS_ERROR']		= { 30101, 'redis error for '},
    
    --	API Level ERROR
    ['RCS_ERROR']		= { 40101, 'rcs error for '},
    ['PEER_ERROR']       = { 40201, 'peer error for '},

    --  unknown error
    ['UNKNOWN_ERROR']		= { 50501, 'unknown reason '},
    --  lua internal error
    ['LUA_UNKNOWN_ERROR']       = { 50502, 'lua unknown reason '},
}

return _M
