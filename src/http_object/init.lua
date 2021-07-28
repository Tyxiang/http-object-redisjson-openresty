-- 加载配置
cjson = require "cjson.safe"
local path = "http_object/config/config.json"
local file_config = io.open(path, "r")
if file_config == nil then
	ngx.log(ngx.ERR, "load config error!")
end
local string_config = file_config:read("*a") or "{}"
file_config:close()
config = cjson.decode(string_config)

key_object = "object"

function uri_to_rejson_path(uri)
	json_path = uri
	json_path = string.gsub(json_path, "^/", "")
	json_path = string.gsub(json_path, "/$", "")
	json_path = string.gsub(json_path, "/", ".")
	json_path = string.gsub(json_path, "%(", "[")
	json_path = string.gsub(json_path, "%)", "]")
	json_path = "." .. json_path 
	return json_path
end

function string.is_start_with(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

function string.is_end_with(String, End)
	return string.sub(String, -string.len(End)) == End
end

function string.split(String, Sep)
	
end