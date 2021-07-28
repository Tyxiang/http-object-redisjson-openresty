-- 获取基本输入
local method = ngx.req.get_method()
local uri =  ngx.var.uri -- 不带参数
local args = ngx.req.get_uri_args() 

uri = string.gsub(uri, "^/admin", "")

-- 连接 redis
local redis = require "resty.redis"
local redis_client = redis:new()
redis_client:set_timeouts(1000, 1000, 1000) -- 1 sec
local _, err = redis_client:connect(config["redis"]["host"], config["redis"]["port"])
if err ~= nil then
	ngx.log(ngx.ERR, err)
	ngx.say('{"success":false, "message":' .. err .. '"}')
	return
end

-- redis 验证
-- if config["redis"]["password"] ~= ngx.null then
-- 	local _, err = redis_client:auth(config["redis"]["password"])
-- 	if err ~= nil then
-- 		ngx.log(ngx.ERR, "failed to authenticate, ", err)
-- 		return
-- 	end
-- end

-- 路由
if (method == "POST") then
	-- get data
	ngx.req.read_body()
    local data = ngx.req.get_body_data()
    -- post to ovl
    if string.is_end_with(uri, "()") then
    	local uri = string.gsub(uri, "%(%)$", "")
	    local rejson_path = uri_to_rejson_path(uri)
	    local rejson_res, err = redis_client:json_arrappend(key_object, rejson_path, data)
	    if err ~= nil then
	    	ngx.log(ngx.ERR, err)
	    	ngx.say('{"success":false, "message":"' .. err .. '"}')
	    	return
	    end
	    ngx.say('{"success":true, "index":'.. rejson_res-1 ..'}')
	    return
	end
	-- post to else
    local rejson_path = uri_to_rejson_path(uri)
    local rejson_res, err = redis_client:json_set(key_object, rejson_path, data, "NX") -- 只在不存在时可以POST，已存在的话只能PUT
	if err ~= nil then
    	ngx.log(ngx.ERR, err)
    	ngx.say('{"success":false, "message":"' .. err .. '"}')
    	return
    end
    if rejson_res == ngx.null then
    	err = "key already exist"
    	ngx.log(ngx.ERR, err)
    	ngx.say('{"success":false, "message":"' .. err .. '"}')
    	return
    end
    ngx.say('{"success":true}')
    return
end

if (method == "GET") then 
	---- 属性 type
	if string.is_end_with(uri, ".type") then
		local uri = string.gsub(uri, ".type$", "")
		local rejson_path = uri_to_rejson_path(uri)
		local rejson_res, err = redis_client:json_type(key_object, rejson_path)
		if err ~= nil then
			ngx.log(ngx.ERR, err)
			ngx.say('{"success":false, "message":"' .. err .. '"}')
			return
		end
		ngx.say('{"success":true, "type":"' .. rejson_res .. '"}')
		return
	end
	---- 属性 strlen
	if string.is_end_with(uri, ".strlen") then
		local uri = string.gsub(uri, ".strlen$", "")
		local rejson_path = uri_to_rejson_path(uri)
		local rejson_res, err = redis_client:json_strlen(key_object, rejson_path)
		if err ~= nil then
			ngx.log(ngx.ERR, err)
			ngx.say('{"success":false, "message":"' .. err .. '"}')
			return
		end
		ngx.say('{"success":true, "strlen":' .. rejson_res .. '}')
		return
	end
	---- 属性 arrlen
	if string.is_end_with(uri, ".arrlen") then
		local uri = string.gsub(uri, ".arrlen$", "")
		local rejson_path = uri_to_rejson_path(uri)
		local rejson_res, err = redis_client:json_arrlen(key_object, rejson_path)
		if err ~= nil then
			ngx.log(ngx.ERR, err)
			ngx.say('{"success":false, "message":"' .. err .. '"}')
			return
		end
		ngx.say('{"success":true, "arrlen":' .. rejson_res .. '}')
		return
	end
	---- 属性 objlen
	if string.is_end_with(uri, ".objlen") then
		local uri = string.gsub(uri, ".objlen$", "")
		local rejson_path = uri_to_rejson_path(uri)
		local rejson_res, err = redis_client:json_objlen(key_object, rejson_path)
		if err ~= nil then
			ngx.log(ngx.ERR, err)
			ngx.say('{"success":false, "message":"' .. err .. '"}')
			return
		end
		ngx.say('{"success":true, "objlen":' .. rejson_res .. '}')
		return
	end
	---- 属性 keys
	if string.is_end_with(uri, ".keys") then
		local uri = string.gsub(uri, ".keys$", "")
		local rejson_path = uri_to_rejson_path(uri)
		local rejson_res, err = redis_client:json_objkeys(key_object, rejson_path)
		if err ~= nil then
			ngx.log(ngx.ERR, err)
			ngx.say('{"success":false, "message":"' .. err .. '"}')
			return
		end
		keys = cjson.encode(rejson_res)
		ngx.say('{"success":true, "keys":' .. keys .. '}')
		return
	end
	---- 属性 memory
	-- if string.is_end_with(uri, ".memory") then
	-- 	local uri = string.gsub(uri, ".memory$", "")
	-- 	local rejson_path = uri_to_rejson_path(uri)
	-- 	local rejson_res, err = redis_client:json_debug memory(key_object, rejson_path)
	---- 命令：json.debug memory key_object rejson_path
	-- 	if err ~= nil then
	-- 		ngx.log(ngx.ERR, err)
	-- 		ngx.say('{"success":false, "message":' .. err .. '"}')
	-- 		return
	-- 	end
	-- 	ngx.say('{"success":true, "data":"' .. rejson_res .. '"}')
	-- 	return
	-- end
	---- 键值
	local rejson_path = uri_to_rejson_path(uri)
	local rejson_res, err = redis_client:json_get(key_object, rejson_path)
	if err ~= nil then
		ngx.log(ngx.ERR, err)
		ngx.say('{"success":false, "message":"' .. err .. '"}')
		return
	end
	---- 查询
	if args["q"] ~= nil then
		table_res = cjson.decode(rejson_res)
		for query in string.gmatch(args["q"], "([^%s]+)") do -- 空格分割
			if string.is_start_with(query, "filter(") then
				-- table.pack(...)
				-- ngx.say("filter")
				-- ngx.say('{"success":true, "data":' .. rejson_res .. '}')
				return
			end
			if string.is_start_with(query, "search(") then
				ngx.say("search")
			end
		end
	end
	---- 统计
	if args["s"] ~= nil then
		rejson_res_table = cjson.decode(rejson_res)
		if string.is_start_with(args["s"], "count(") then
			count = #rejson_res_table
			ngx.say('{"success":true, "count":' .. count .. '}')
			return
		end
		if string.is_start_with(args["s"], "max(") then
			ngx.say("max")
		end
		if string.is_start_with(args["s"], "min(") then
			ngx.say("min")
		end
		if string.is_start_with(args["s"], "avg(") then
			ngx.say("avg")
		end
	end
	---- 响应
	ngx.say('{"success":true, "data":' .. rejson_res .. '}')
end

if (method == "PUT") then 
	-- get data
	ngx.req.read_body()
    local data = ngx.req.get_body_data()
    -- put
    local rejson_path = uri_to_rejson_path(uri)
    local rejson_res, err = redis_client:json_set(key_object, rejson_path, data, "XX") -- 只在已存在时设置
	if err ~= nil then
    	ngx.log(ngx.ERR, err)
    	ngx.say('{"success":false, "message":"' .. err .. '"}')
    	return
    end
    if rejson_res == ngx.null then
    	err = "may not exist"
    	ngx.log(ngx.ERR, err)
    	ngx.say('{"success":false, "message":"' .. err .. '"}')
    	return
    end
	ngx.say('{"success":true}')
    return 
end

if (method == "DELETE") then 
	-- delete
	local rejson_path = uri_to_rejson_path(uri)
	local rejson_res, err = redis_client:json_del(key_object, rejson_path)
	if err ~= nil then
    	ngx.log(ngx.ERR, err)
    	ngx.say('{"success":false, "message":"' .. err .. '"}')
    	return
    end
	if rejson_res == 0 then
		err = "nothing deleted"
		ngx.log(ngx.ERR, err)
		ngx.say('{"success":false, "message":"' .. err .. '"}')
		return
	end
	ngx.say('{"success":true, "qty":' .. rejson_res .. '}')
	return
end