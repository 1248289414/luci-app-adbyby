require "nixio.fs"
require "luci.sys"

local m, s, e, o
local adbyby_enabled=luci.sys.init.enabled("adbyby")
local adbyby_proxy=luci.sys.call("iptables-save -t nat | grep \"zone_lan_prerouting\" | grep \"ADBYBY_RULE\" > /dev/null")
local adbyby_state=luci.sys.call("pgrep /usr/share/adbyby/adbyby > /dev/null")
local adbyby_date1=luci.sys.exec("head -1 /usr/share/adbyby/data/lazy.txt  | awk -F' ' '{print $3,$4}'")
local adbyby_date2=luci.sys.exec("head -1 /usr/share/adbyby/data/video.txt | awk -F' ' '{print $3,$4}'")
local rule_lines=luci.sys.exec("wc -l /usr/share/adbyby/data/user.txt | awk -F' ' '{print $1}'")

m = Map("adbyby", translate("广告屏蔽大师"),
	translate("<strong><font color=\"red\">视频广告、网盟广告统统一扫光。</font></strong>"))

-- [[ 状态栏 ]]--
s = m:section(SimpleSection, translate("Adbyby 运行状态"))
s.addremove = false
s.anonymous = true
if adbyby_state == 0 then
	s:option(DummyValue, "_Status", nil, 
		translate("广告屏蔽大师正在运行"))
else
	s:option(DummyValue, "_Status", nil, 
		translate("<font color=\"red\"><strong>广告屏蔽大师未运行</strong></font>"))
end
if adbyby_proxy == 0 then
	s:option(DummyValue, "_proxy", nil, 
		translate("透明代理已添加"))
else
	s:option(DummyValue, "_proxy", nil, 
		translate("<font color=\"red\"><strong>透明代理未添加</strong></font>"))
end
s:option(DummyValue, "_Date1", nil, 
	translate("Lazy规则日期:"..adbyby_date1))
s:option(DummyValue, "_Date2", nil, 
	translate("Video规则日期:"..adbyby_date2))
s:option(DummyValue, "_lines", nil, 
	translate("自定义规则行数:"..rule_lines))

s = m:section(TypedSection, "adbyby", translate("Adbyby 设置"))
s.addremove = false
s.anonymous = true
s:tab("general", translate("基本设置"))
s:tab("user", translate("自定义规则"))
s:tab("config", translate("高级设置"))

-- [[ 基本设置 ]]--

o = s:taboption("general", Button, "endisable", nil, translate("启用/禁用ADBYBY"))
o.render = function(self, section, scope)
	if adbyby_enabled then
		self.title = translate("关闭ADBYBY")
		self.inputstyle = "reset"
	else
		self.title = translate("启用ADBYBY")
		self.inputstyle = "apply"
	end
	Button.render(self, section, scope)
end
o.write = function(self, section)
	if adbyby_enabled then
		adbyby_enabled=false
		luci.sys.init.stop("adbyby")
		luci.http.write("<script type=\"text/javascript\">location.replace(location)</script>")
		luci.http.close()
		return luci.sys.init.disable("adbyby")
	else
		adbyby_enabled=true
		luci.sys.init.start("adbyby")
		luci.sys.exec("sleep 2")
		luci.http.write("<script type=\"text/javascript\">location.replace(location)</script>")
		luci.http.close()
		return luci.sys.init.enable("adbyby")
	end
end

o = s:taboption("general", ListValue, "adbyby_mode", 
	translate("过滤模式"))
o:value("0", translate("全局过滤模式（过滤效果最好，对下载速度影响大——在7620A下最大支持60M宽带）"))
o:value("1", translate("<推荐>白名单模式（忽略列表外的设备，过滤列表中的设备）"))
o:value("2", translate("<推荐>黑名单模式（忽略列表中的设备，过滤列表外的设备）"))
o:value("3", translate("指定域名模式（仅过滤列表中的网站，如：\"v.youku.com\“）"))
o:value("4", translate("手动添加代理模式（最不影响速度模式，你需要手动在浏览器添加代理 \"路由器ip:8118\"）"))

o.rmempty = false
o.default = 0
o = s:taboption("general", DynamicList, "adbyby_list", 
	translate("IP列表"))
o.datatype = "ipaddr"
o:depends("adbyby_mode", 1)
o:depends("adbyby_mode", 2)
o = s:taboption("general", DynamicList, "host_list", 
	translate("域名列表"))
o:depends("adbyby_mode", 3)

s:taboption("general", DummyValue,"opennewwindow" , 
	translate("<br /><p align=\"justify\"><script type=\"text/javascript\"></script><input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"ADbyby官网\" onclick=\"window.open('http://www.adbyby.com/')\" /></p>"),
	"<strong><font color=\"blue\">www.adbyby.com</strong></font><br /><br /> \
	感谢xwhyc，幽涧山泉，ADBYBY大师傅等人无偿的工作，<br />为我们提供了全面高效的去广告服务！<br /> \
	如果你发现了未屏蔽的广告请加入QQ群进行反馈<br /><br />\
	<strong><font color=\"red\">加群链接:</font></strong><br /><br /> \
	<p align=\"justify\"><script type=\"text/javascript\"></script><input type=\"button\" class=\"cbi-button cbi-button-reset\" value=\"广告屏蔽大师①\" onclick=\"window.open('http://jq.qq.com/?_wv=1027&k=2945pN5')\" /></p><br /> \
	<p align=\"justify\"><script type=\"text/javascript\"></script><input type=\"button\" class=\"cbi-button cbi-button-reset\" value=\"广告屏蔽大师②\" onclick=\"window.open('http://jq.qq.com/?_wv=1027&k=2FAy9hP')\" /></p><br /> \
	<p align=\"justify\"><script type=\"text/javascript\"></script><input type=\"button\" class=\"cbi-button cbi-button-reset\" value=\"广告屏蔽大师③\" onclick=\"window.open('http://jq.qq.com/?_wv=1027&k=2H5PpUP')\" /></p>")

-- [[ 自定义规则 ]]--
o = s:taboption("user", DynamicList, "exdomain", 
		translate("域名白名单"), 
		translate("添加你不想过滤的域名，如adbyby.com"))
o = s:taboption("user", DynamicList, "address", 
		translate("第三方规则地址"), 
		translate("强烈不建议添加，会导致不可预料问题"))
o = s:taboption("user", DummyValue, "_tips", "自定义规则", 
		translate(
"<br />------------------------------ ADByby 自定义过滤语法简表---------------------------------<br /> \
  --------------  规则基于abp规则，并进行了字符替换部分的扩展-----------------------------<br /> \
  ABP规则请参考<a href=\"https://adblockplus.org/zh_CN/filters\">https://adblockplus.org/zh_CN/filters</a>，下面为大致摘要<br /> \
  \"!\" 为行注释符，注释行以该符号起始作为一行注释语义，用于规则描述<br /> \
  \"*\" 为字符通配符，能够匹配0长度或任意长度的字符串，该通配符不能与正则语法混用。<br /> \
  \"^\" 为分隔符，可以是除了字母、数字或者 _ - . % 之外的任何字符。<br /> \
  \"|\" 为管线符号，来表示地址的最前端或最末端<br /> \
  \"||\" 为子域通配符，方便匹配主域名下的所有子域。<br /> \
  \"~\" 为排除标识符，通配符能过滤大多数广告，但同时存在误杀, 可以通过排除标识符修正误杀链接。<br /> \
  \"##\" 为元素选择器标识符，后面跟需要隐藏元素的CSS样式例如 #ad_id  .ad_class<br /> \
  元素隐藏暂不支持全局规则和排除规则<br /> \
  字符替换扩展<br /> \
  文本替换选择器标识符，后面跟需要替换的文本数据，格式：$s@模式字符串@替换后的文本@<br /> \
  支持通配符*和？<br /> \
  -------------------------------------------------------------------------------------------<br />"))
o = s:taboption("user", TextValue, "_editconf_user", nil, 
translate("<strong>强者制定规则，弱者困守规则，勇者打破规则，智者游戏规则</strong>"))
o.rows = "*"
o.cols = "*"
o.wrap = "off"
function o.cfgvalue(self, section)
	return nixio.fs.readfile("/usr/share/adbyby/user.txt") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		nixio.fs.writefile("/usr/share/adbyby/user.txt", value)
	end
end

-- [[ 高级设置 ]]--
o = s:taboption("config", Value, "port", "过滤端口", "添加你想要额外过滤的端口，用英文\",\"隔开，如80,8118")
o.default = 80

o = s:taboption("config", TextValue, "_adbyby_config", nil, 
		translate("一般情况保持默认即可"))
o.rows = "*"
o.cols = "*"
o.wrap = "off"
function o.cfgvalue(self, section)
	return nixio.fs.readfile("/usr/share/adbyby/adhook.ini") or ""
end
function o.write(self, section, value)
	if value then
		value = value:gsub("\r\n?", "\n")
		nixio.fs.writefile("/usr/share/adbyby/adhook.ini", value)
	end
end

return m
