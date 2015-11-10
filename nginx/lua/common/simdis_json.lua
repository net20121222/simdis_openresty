-- @Date    : 2015-10-28 19:58:26
-- @Author  : miaolian (mike19890421@163.com)
-- @Version : 1.0

local c_json = require "cjson"

local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M.json_decode( self,str )
    local json_value = nil
    pcall(function (str) json_value = c_json.decode(str) end, str)
    return json_value
end


function _M.json_encode(self, str, empty_table_as_object )
  --Lua的数据类型里面，array和dict是同一个东西。对应到json encode的时候，就会有不同的判断
  --对于linux，我们用的是cjson库：A Lua table with only positive integer keys of type number will be encoded as a JSON array. All other tables will be encoded as a JSON object.
  --cjson对于空的table，就会被处理为object，也就是{}
  --dkjson默认对空table会处理为array，也就是[]
  --处理方法：对于cjson，使用encode_empty_table_as_object这个方法。文档里面没有，看源码
  --对于dkjson，需要设置meta信息。local a= {}；a.s = {};a.b='中文';setmetatable(a.s,  { __jsontype = 'object' });ngx.say(comm.json_encode(a))

    local json_value = nil
    if c_json.encode_empty_table_as_object then
        c_json.encode_empty_table_as_object(empty_table_as_object or false) -- 空的table默认为array
    end
    c_json.encode_sparse_array(true)

    pcall(function (str) json_value = c_json.encode(str) end, str)
    return json_value
end


function _M.new(self)
	return setmetatable({}, mt)
end

return 	_M