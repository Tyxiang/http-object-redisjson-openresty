-- 获取基本输入
local method = ngx.req.get_method()
local uri =  ngx.var.uri -- 不带参数
local args = ngx.req.get_uri_args() 

if (method == "POST") then
	ngx.say("post") 
end

if (method == "GET") then 
	ngx.say("get")
end

if (method == "PUT") then 
	ngx.say("put") 
end

if (method == "DELETE") then 
	ngx.say("delete") 
end
