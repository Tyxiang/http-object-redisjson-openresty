# 说明

## OpenResty 修改

内置的 lua redis 模块不支持自动生成带点的 redis 命令，所以手工修改 lualib/resty/redis.lua，在 320 行加入代码：`lua args[1] = args[1]:gsub("_", ".")`，自动将命令中的 "\_" 转换为 "."。
