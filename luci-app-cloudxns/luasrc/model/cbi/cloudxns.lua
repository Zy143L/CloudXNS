--[[
LuCI - Lua Configuration Interface
Zy143L CloudXNS DDNS API Luci
]]--

require("luci.sys")

m = Map("cloudxns", translate("CloudXNS DDNS"), translate("使用CloudXNS的API达到DDNS效果 支持IPv4/6"))

s = m:section(TypedSection, "shizuku")
s.addremove = false
s.anonymous = true

xns = s:option(Flag, "cloudxns", translate("启用"))
xns.default = 0
xns.rmempty = false
xns.description = translate("启动CloudXNS DDNS")


API = s:option(Value, "API_KEY", translate("API_KEY"),"CloudXNS的API_KEY")
SECRET = s:option(Value, "SECRET_KEY", translate("SECRET_KEY"),"CloudXNS的SECRET_KEY")
SECRET.password = true
main = s:option(Value, "main_domain", translate("主域名"),"想要解析的主域名，例如:shizuku.com")
sub = s:option(Value, "sub_domain", translate("子域名"),"想要解析的子域名，例如:rbq")
IPv6 = s:option(ListValue, "ipv6", translate("IPv4/6选择"))
IPv6:value("0", translate("IPv4模式"))
IPv6:value("1", translate("IPv6模式"))
IPv6:value("2", translate("IPv4/6模式"))


local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/usr/share/cloudxns.sh &")
end

return m
