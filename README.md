# HTTP 对象服务 http object service

## 1. 概述

基于 http 协议提供对象访问服务。

## 2. 引用

- [URI 数据访问规则](https://github.com/fimiking/uri-data-access-rule) 

## 3. 依赖

### 3.1. Redis-JSON

版本 ...

### 3.2. OpenResty

版本 ...

### 3.3. OpenResty 修改

内置的 lua redis 模块不支持自动生成带点的 redis 命令，所以手工修改 lualib/resty/redis.lua，在 320 行加入代码：`lua args[1] = args[1]:gsub("_", ".")`，自动将命令中的 "_" 转换为 "."。