#!/bin/bash
export LANG=en_US.UTF-8
sred='\033[5;31m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
bblue='\033[0;34m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit
stty erase $'\b' 2>/dev/null || stty erase '^H' 2>/dev/null
#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "alpine"; then
release="alpine"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
#if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
if [[ $(echo "$op" | grep -i -E "arch") ]]; then
red "脚本不支持当前的 $op 系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
version=$(uname -r | cut -d "-" -f1)
[[ -z $(systemd-detect-virt 2>/dev/null) ]] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) red "目前脚本不支持$(uname -m)架构" && exit;;
esac
if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then
bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`
elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then
bbr="Openvz版bbr-plus"
else
bbr="Openvz/Lxc"
fi
if [ ! -f xuiyg_update ]; then
green "首次安装x-ui-yg脚本必要的依赖……"
if [[ x"${release}" == x"alpine" ]]; then
apk update
apk add wget curl tar jq tzdata openssl expect git socat iproute2 coreutils util-linux dcron
apk add virt-what
else
if [[ $release = Centos && ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
cd
fi
if [ -x "$(command -v apt-get)" ]; then
apt update -y
apt install jq tzdata socat cron coreutils util-linux -y
elif [ -x "$(command -v yum)" ]; then
yum update -y && yum install epel-release -y
yum install jq tzdata socat coreutils util-linux -y
elif [ -x "$(command -v dnf)" ]; then
dnf update -y
dnf install jq tzdata socat coreutils util-linux -y
fi
if [ -x "$(command -v yum)" ] || [ -x "$(command -v dnf)" ]; then
if ! command -v "cronie" &> /dev/null; then
if [ -x "$(command -v yum)" ]; then
yum install -y cronie
elif [ -x "$(command -v dnf)" ]; then
dnf install -y cronie
fi
fi
fi
fi
packages=("curl" "openssl" "tar" "expect" "xxd" "python3" "wget" "git")
inspackages=("curl" "openssl" "tar" "expect" "xxd" "python3" "wget" "git")
for i in "${!packages[@]}"; do
package="${packages[$i]}"
inspackage="${inspackages[$i]}"
if ! command -v "$package" &> /dev/null; then
if [ -x "$(command -v apt-get)" ]; then
apt-get install -y "$inspackage"
elif [ -x "$(command -v yum)" ]; then
yum install -y "$inspackage"
elif [ -x "$(command -v dnf)" ]; then
dnf install -y "$inspackage"
fi
fi
done
fi
touch xuiyg_update
fi
if [[ $vi = openvz ]]; then
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
red "检测到未开启TUN，现尝试添加TUN支持" && sleep 4
cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
green "添加TUN支持失败，建议与VPS厂商沟通或后台设置开启" && exit
else
echo '#!/bin/bash' > /root/tun.sh && echo 'cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun' >> /root/tun.sh && chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN守护功能已启动"
fi
fi
fi
argopid(){
ym=$(cat /usr/local/x-ui/xuiargoympid.log 2>/dev/null)
ls=$(cat /usr/local/x-ui/xuiargopid.log 2>/dev/null)
}
v4v6(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
v4dq=$(curl -s4m5 -k https://myip.ipip.net | awk -F'来自于：' '{print $2}' 2>/dev/null)
#v4dq=$(curl -s4m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null)
v6dq=$(curl -s6m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null)
}
warpcheck(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
v6(){
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4=$(curl -s4m5 icanhazip.com -k)
if [ -z $v4 ]; then
yellow "检测到 纯IPV6 VPS，添加nat64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
fi
}
serinstall(){
green "下载并安装x-ui相关组件……"
cd /usr/local/
#curl -L -o /usr/local/x-ui-linux-${cpu}.tar.gz --insecure https://gitlab.com/rwkgyg/x-ui-yg/raw/main/x-ui-linux-${cpu}.tar.gz
curl -L -o /usr/local/x-ui-linux-${cpu}.tar.gz -# --retry 2 --insecure https://github.com/yonggekkk/x-ui-yg/releases/download/xui_yg/x-ui-linux-${cpu}.tar.gz
tar zxvf x-ui-linux-${cpu}.tar.gz > /dev/null 2>&1
rm x-ui-linux-${cpu}.tar.gz -f
cd x-ui
chmod +x x-ui bin/xray-linux-${cpu}
cp -f x-ui.service /etc/systemd/system/ >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
systemctl enable x-ui >/dev/null 2>&1
systemctl start x-ui >/dev/null 2>&1
cd
rm /usr/bin/x-ui -f
#curl -L -o /usr/bin/x-ui --insecure https://gitlab.com/rwkgyg/x-ui-yg/raw/main/1install.sh >/dev/null 2>&1
curl -L -o /usr/bin/x-ui -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh
chmod +x /usr/bin/x-ui
if [[ x"${release}" == x"alpine" ]]; then
echo '#!/sbin/openrc-run
name="x-ui"
command="/usr/local/x-ui/x-ui"
directory="/usr/local/${name}"
pidfile="/var/run/${name}.pid"
command_background="yes"
depend() {
need networking 
}' > /etc/init.d/x-ui
chmod +x /etc/init.d/x-ui
rc-update add x-ui default
rc-service x-ui start
fi
if [[ -f /usr/bin/x-ui && -f /usr/local/x-ui/bin/xray-linux-${cpu} ]]; then
green "下载成功"
else
red "下载失败，请检测VPS网络是否正常，脚本退出"
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui stop
rc-update del x-ui default
rm /etc/init.d/x-ui -f
else
systemctl stop x-ui
systemctl disable x-ui
rm /etc/systemd/system/x-ui.service -f
systemctl daemon-reload
systemctl reset-failed
fi
rm /usr/bin/x-ui -f
rm /etc/x-ui-yg/ -rf
rm /usr/local/x-ui/ -rf
rm -rf xuiyg_update
exit
fi
}
userinstall(){
readp "设置 x-ui 登录用户名（回车跳过为随机6位字符）：" username
sleep 1
if [[ -z ${username} ]]; then
username=`date +%s%N |md5sum | cut -c 1-6`
fi
while true; do
if [[ ${username} == *admin* ]]; then
red "不支持包含有 admin 字样的用户名，请重新设置" && readp "设置 x-ui 登录用户名（回车跳过为随机6位字符）：" username
else
break
fi
done
sleep 1
green "x-ui登录用户名：${username}"
echo
readp "设置 x-ui 登录密码（回车跳过为随机6位字符）：" password
sleep 1
if [[ -z ${password} ]]; then
password=`date +%s%N |md5sum | cut -c 1-6`
fi
while true; do
if [[ ${password} == *admin* ]]; then
red "不支持包含有 admin 字样的密码，请重新设置" && readp "设置 x-ui 登录密码（回车跳过为随机6位字符）：" password
else
break
fi
done
sleep 1
green "x-ui登录密码：${password}"
/usr/local/x-ui/x-ui setting -username ${username} -password ${password} >/dev/null 2>&1
}
portinstall(){
echo
readp "设置 x-ui 登录端口[1-65535]（回车跳过为10000-65535之间的随机端口）：" port
sleep 1
if [[ -z $port ]]; then
port=$(shuf -i 10000-65535 -n 1)
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] 
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" port
done
else
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n端口被占用，请重新输入端口" && readp "自定义端口:" port
done
fi
sleep 1
/usr/local/x-ui/x-ui setting -port $port >/dev/null 2>&1
green "x-ui登录端口：${port}"
}
pathinstall(){
echo
readp "设置 x-ui 登录根路径（回车跳过为随机3位字符）：" path
sleep 1
if [[ -z $path ]]; then
path=`date +%s%N |md5sum | cut -c 1-3`
fi
/usr/local/x-ui/x-ui setting -webBasePath ${path} >/dev/null 2>&1
green "x-ui登录根路径：${path}"
}
showxuiip(){
xuilogin(){
v4v6
if [[ -z $v4 ]]; then
echo "[$v6]" > /usr/local/x-ui/xip
elif [[ -n $v4 && -n $v6 ]]; then
echo "$v4" > /usr/local/x-ui/xip
echo "[$v6]" >> /usr/local/x-ui/xip
else
echo "$v4" > /usr/local/x-ui/xip
fi
}
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
xuilogin
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
xuilogin
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
}
resinstall(){
echo "----------------------------------------------------------------------"
restart
#curl -sL https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version | awk -F "更新内容" '{print $1}' | head -n 1 > /usr/local/x-ui/v
curl -sL https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/version | awk -F "更新内容" '{print $1}' | head -n 1 > /usr/local/x-ui/v
showxuiip
sleep 2
xuigo
cronxui
echo "----------------------------------------------------------------------"
blue "x-ui-yg $(cat /usr/local/x-ui/v 2>/dev/null) 安装成功，自动进入 x-ui 显示管理菜单" && sleep 4
echo
show_menu
}
xuiinstall(){
v6
echo "----------------------------------------------------------------------"
openyn
echo "----------------------------------------------------------------------"
serinstall
echo "----------------------------------------------------------------------"
userinstall
portinstall
pathinstall
resinstall
}
update() {
yellow "升级也有可能出意外哦，建议如下："
yellow "一、点击x-ui面版中的备份与恢复，下载备份文件x-ui-yg.db"
yellow "二、在 /etc/x-ui-yg 路径导出备份文件x-ui-yg.db"
readp "确定升级，请按回车(退出请按ctrl+c):" ins
if [[ -z $ins ]]; then
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui stop
else
systemctl stop x-ui
fi
serinstall && sleep 2
restart
#curl -sL https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version | awk -F "更新内容" '{print $1}' | head -n 1 > /usr/local/x-ui/v
curl -sL https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/version | awk -F "更新内容" '{print $1}' | head -n 1 > /usr/local/x-ui/v
green "x-ui更新完成" && sleep 2 && x-ui
else
red "输入有误" && update
fi
}
uninstall() {
yellow "本次卸载将清除所有数据，建议如下："
yellow "一、点击x-ui面版中的备份与恢复，下载备份文件x-ui-yg.db"
yellow "二、在 /etc/x-ui-yg 路径导出备份文件x-ui-yg.db"
readp "确定卸载，请按回车(退出请按ctrl+c):" ins
if [[ -z $ins ]]; then
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui stop
rc-update del x-ui default
rm /etc/init.d/x-ui -f
else
systemctl stop x-ui
systemctl disable x-ui
rm /etc/systemd/system/x-ui.service -f
systemctl daemon-reload
systemctl reset-failed
fi
kill -15 $(cat /usr/local/x-ui/xuiargopid.log 2>/dev/null) >/dev/null 2>&1
kill -15 $(cat /usr/local/x-ui/xuiargoympid.log 2>/dev/null) >/dev/null 2>&1
kill -15 $(cat /usr/local/x-ui/xuiwpphid.log 2>/dev/null) >/dev/null 2>&1
rm /usr/bin/x-ui -f
rm /etc/x-ui-yg/ -rf
rm /usr/local/x-ui/ -rf
uncronxui
rm -rf xuiyg_update
echo
green "x-ui已卸载完成"
echo
blue "欢迎继续使用x-ui-yg脚本：bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh)"
echo
else
red "输入有误" && uninstall
fi
}
reset_config() {
/usr/local/x-ui/x-ui setting -reset
sleep 1 
portinstall
pathinstall
}
stop() {
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui stop
else
systemctl stop x-ui
fi
check_status
if [[ $? == 1 ]]; then
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/goxui.sh/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
green "x-ui停止成功"
else
red "x-ui停止失败，请运行 x-ui log 查看日志并反馈" && exit
fi
}
restart() {
yellow "请稍等……"
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui restart
else
systemctl restart x-ui
fi
sleep 2
check_status
if [[ $? == 0 ]]; then
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/goxui.sh/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
crontab -l 2>/dev/null > /tmp/crontab.tmp
echo "* * * * * /usr/local/x-ui/goxui.sh" >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
green "x-ui重启成功"
else
red "x-ui重启失败，请运行 x-ui log 查看日志并反馈" && exit
fi
}
show_log() {
if [[ x"${release}" == x"alpine" ]]; then
yellow "暂不支持alpine查看日志"
else
journalctl -u x-ui.service -e --no-pager -f
fi
}
get_char(){
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
back(){
white "------------------------------------------------------------------------------------"
white " 回x-ui主菜单，请按任意键"
white " 退出脚本，请按Ctrl+C"
get_char && show_menu
}
acme() {
#bash <(curl -Ls https://gitlab.com/rwkgyg/acme-script/raw/main/acme.sh)
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/acme-yg/main/acme.sh)
back
}
bbr() {
bash <(curl -Ls https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
back
}
cfwarp() {
#bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh)
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh)
back
}
xuirestop(){
echo
readp "1. 停止 x-ui \n2. 重启 x-ui \n0. 返回主菜单\n请选择：" action
if [[ $action == "1" ]]; then
stop
elif [[ $action == "2" ]]; then
restart
else
show_menu
fi
}
xuichange(){
echo
readp "1. 更改 x-ui 用户名与密码 \n2. 更改 x-ui 面板登录端口\n3. 更改 x-ui 面板根路径\n4. 重置 x-ui 面板设置（面板设置选项中所有设置都恢复出厂设置，登录端口与面板根路径将重新自定义，账号密码不变）\n0. 返回主菜单\n请选择：" action
if [[ $action == "1" ]]; then
userinstall && restart
elif [[ $action == "2" ]]; then
portinstall && restart
elif [[ $action == "3" ]]; then
pathinstall && restart
elif [[ $action == "4" ]]; then
reset_config && restart
else
show_menu
fi
}
show_status(){
check_status
if [[ $? == 0 ]]; then
green "x-ui运行状态：正常运行"
else
red "x-ui运行状态：未运行"
fi
}
check_status() {
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui status >/dev/null 2>&1
return $?
else
systemctl is-active --quiet x-ui
return $?
fi
}
openyn(){
if [[ -e /usr/local/x-ui/x-ui.db && -e /usr/local/x-ui/x-ui ]]; then
yellow "检测到已安装 x-ui"
yellow "1. 保留原数据库并覆盖更新"
yellow "2. 删除原数据库全新安装"
yellow "0. 退出脚本"
readp "请选择：" yn
case $yn in
1) green "保留原数据库覆盖更新……" && rm /usr/local/x-ui/bin -rf && rm /usr/local/x-ui/x-ui -f;;
2) red "删除原数据库全新安装……" && rm /usr/local/x-ui -rf;;
0) exit;;
*) red "输入有误，请重新输入" && openyn;;
esac
fi
}
cronxui(){
if [[ ! -e /usr/local/x-ui/goxui.sh ]]; then
echo '#!/bin/bash' > /usr/local/x-ui/goxui.sh
echo 'systemctl restart x-ui >/dev/null 2>&1' >> /usr/local/x-ui/goxui.sh
chmod +x /usr/local/x-ui/goxui.sh
fi
}
uncronxui(){
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/goxui.sh/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
}
xuigo(){
check_status
if [[ $? != 0 ]]; then
restart
fi
}
show_menu(){
clear
blue "================================================================"
white "甬哥侃侃侃x-ui精简修改版一键脚本，面板中的相关设置与原作者[vaxilu]保持一致"
white "博客地址：https://ygkkk.blogspot.com"
white "Youtube 频道：甬哥侃侃侃"
white "交流群组：https://t.me/+jZHc6-A-1QQ5ZGVl"
blue "================================================================"
if [[ -e /usr/local/x-ui/x-ui ]]; then
show_status
white "----------------------------------------------------------------"
blue " x-ui-yg $(cat /usr/local/x-ui/v 2>/dev/null) 管理菜单"
white "----------------------------------------------------------------"
green " 1. 更新 x-ui"
yellow " 2. 卸载 x-ui"
white "----------------------------------------------------------------"
green " 3. 停止 x-ui"
green " 4. 重启 x-ui"
green " 5. 查看 x-ui 日志"
white "----------------------------------------------------------------"
green " 6. 修改 x-ui 账号密码"
green " 7. 修改 x-ui 面板端口"
green " 8. 修改 x-ui 面板根路径"
green " 9. 重置 x-ui 面板设置"
white "----------------------------------------------------------------"
green " 10. 查看 x-ui 面板信息"
green " 11. 配置 WARP 代理"
green " 12. 配置 WARP 免费 VPN"
white "----------------------------------------------------------------"
green " 13. 申请证书"
green " 14. 安装 BBR"
white "----------------------------------------------------------------"
blue " 0. 退出脚本"
echo
readp "请输入数字 [0-14]:" num
case $num in
1) update;;
2) uninstall;;
3) stop && back;;
4) restart && back;;
5) show_log && back;;
6) xuichange;;
7) xuichange;;
8) xuichange;;
9) xuichange;;
10) showxuiip && echo && cat /usr/local/x-ui/xip && echo && back;;
11) cfwarp;;
12) cfwarp;;
13) acme;;
14) bbr;;
0) exit;;
*) red "请输入正确数字 [0-14]" && sleep 2 && show_menu;;
esac
else
white "----------------------------------------------------------------"
blue " x-ui-yg 安装菜单"
white "----------------------------------------------------------------"
green " 1. 安装 x-ui"
white "----------------------------------------------------------------"
blue " 0. 退出脚本"
echo
readp "请输入数字 [0-1]:" num
case $num in
1) xuiinstall;;
0) exit;;
*) red "请输入正确数字 [0-1]" && sleep 2 && show_menu;;
esac
fi
}
if [ ! -f /usr/bin/x-ui ]; then
show_menu
else
show_menu
fi
