-- 获取基本输入
local method = ngx.req.get_method()
local uri =  ngx.var.uri -- 不带参数
local args = ngx.req.get_uri_args() 

if (method == "GET") then 
	local res = '{"success":true,"name":"http object service"}'
	ngx.say(res)
end
