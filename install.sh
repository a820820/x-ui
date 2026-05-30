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
[[ $EUID -ne 0 ]] && yellow "璇蜂互root妯″紡杩愯鑴氭湰" && exit
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
red "涓嶆敮鎸佸綋鍓嶇殑绯荤粺锛岃閫夋嫨浣跨敤Ubuntu,Debian,Centos绯荤粺銆? && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
#if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
if [[ $(echo "$op" | grep -i -E "arch") ]]; then
red "鑴氭湰涓嶆敮鎸佸綋鍓嶇殑 $op 绯荤粺锛岃閫夋嫨浣跨敤Ubuntu,Debian,Centos绯荤粺銆? && exit
fi
version=$(uname -r | cut -d "-" -f1)
[[ -z $(systemd-detect-virt 2>/dev/null) ]] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) red "鐩墠鑴氭湰涓嶆敮鎸?(uname -m)鏋舵瀯" && exit;;
esac

if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then
bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`
elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then
bbr="Openvz鐗坆br-plus"
else
bbr="Openvz/Lxc"
fi

if [ ! -f xuiyg_update ]; then
green "棣栨瀹夎x-ui-yg鑴氭湰蹇呰鐨勪緷璧栤€︹€?
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
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '澶勪簬閿欒鐘舵€? ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
red "妫€娴嬪埌鏈紑鍚疶UN锛岀幇灏濊瘯娣诲姞TUN鏀寔" && sleep 4
cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '澶勪簬閿欒鐘舵€? ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
green "娣诲姞TUN鏀寔澶辫触锛屽缓璁笌VPS鍘傚晢娌熼€氭垨鍚庡彴璁剧疆寮€鍚? && exit
else
echo '#!/bin/bash' > /root/tun.sh && echo 'cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun' >> /root/tun.sh && chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN瀹堟姢鍔熻兘宸插惎鍔?
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
v4dq=$(curl -s4m5 -k https://myip.ipip.net | awk -F'鏉ヨ嚜浜庯細' '{print $2}' 2>/dev/null)
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
yellow "妫€娴嬪埌 绾疘PV6 VPS锛屾坊鍔爊at64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
fi
}

serinstall(){
green "涓嬭浇骞跺畨瑁厁-ui鐩稿叧缁勪欢鈥︹€?
cd /usr/local/
#curl -L -o /usr/local/x-ui-linux-${cpu}.tar.gz https://gitlab.com/rwkgyg/x-ui-yg/raw/main/x-ui-linux-${cpu}.tar.gz
curl -L -o /usr/local/x-ui-linux-${cpu}.tar.gz -# --retry 2 https://github.com/yonggekkk/x-ui-yg/releases/download/xui_yg/x-ui-linux-${cpu}.tar.gz
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
#curl -L -o /usr/bin/x-ui https://gitlab.com/rwkgyg/x-ui-yg/raw/main/1install.sh >/dev/null 2>&1
curl -L -o /usr/bin/x-ui -# --retry 2 https://raw.githubusercontent.com/a820820/x-ui/main/install.sh
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
green "涓嬭浇鎴愬姛"
curl -sL https://raw.githubusercontent.com/a820820/x-ui/main/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1 > /usr/local/x-ui/v
else
red "涓嬭浇澶辫触锛岃妫€娴媀PS缃戠粶鏄惁姝ｅ父锛岃剼鏈€€鍑?
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
readp "璁剧疆 x-ui 鐧诲綍鐢ㄦ埛鍚嶏紙鍥炶溅璺宠繃涓洪殢鏈?浣嶅瓧绗︼級锛? username
sleep 1
if [[ -z ${username} ]]; then
username=`date +%s%N |md5sum | cut -c 1-6`
fi
while true; do
if [[ ${username} == *admin* ]]; then
red "涓嶆敮鎸佸寘鍚湁 admin 瀛楁牱鐨勭敤鎴峰悕锛岃閲嶆柊璁剧疆" && readp "璁剧疆 x-ui 鐧诲綍鐢ㄦ埛鍚嶏紙鍥炶溅璺宠繃涓洪殢鏈?浣嶅瓧绗︼級锛? username
else
break
fi
done
sleep 1
green "x-ui鐧诲綍鐢ㄦ埛鍚嶏細${username}"
echo
readp "璁剧疆 x-ui 鐧诲綍瀵嗙爜锛堝洖杞﹁烦杩囦负闅忔満6浣嶅瓧绗︼級锛? password
sleep 1
if [[ -z ${password} ]]; then
password=`date +%s%N |md5sum | cut -c 1-6`
fi
while true; do
if [[ ${password} == *admin* ]]; then
red "涓嶆敮鎸佸寘鍚湁 admin 瀛楁牱鐨勫瘑鐮侊紝璇烽噸鏂拌缃? && readp "璁剧疆 x-ui 鐧诲綍瀵嗙爜锛堝洖杞﹁烦杩囦负闅忔満6浣嶅瓧绗︼級锛? password
else
break
fi
done
sleep 1
green "x-ui鐧诲綍瀵嗙爜锛?{password}"
/usr/local/x-ui/x-ui setting -username ${username} -password ${password} >/dev/null 2>&1
}

portinstall(){
echo
readp "璁剧疆 x-ui 鐧诲綍绔彛[1-65535]锛堝洖杞﹁烦杩囦负10000-65535涔嬮棿鐨勯殢鏈虹鍙ｏ級锛? port
sleep 1
if [[ -z $port ]]; then
port=$(shuf -i 10000-65535 -n 1)
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] 
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n绔彛琚崰鐢紝璇烽噸鏂拌緭鍏ョ鍙? && readp "鑷畾涔夌鍙?" port
done
else
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n绔彛琚崰鐢紝璇烽噸鏂拌緭鍏ョ鍙? && readp "鑷畾涔夌鍙?" port
done
fi
sleep 1
/usr/local/x-ui/x-ui setting -port $port >/dev/null 2>&1
green "x-ui鐧诲綍绔彛锛?{port}"
}

pathinstall(){
echo
readp "璁剧疆 x-ui 鐧诲綍鏍硅矾寰勶紙鍥炶溅璺宠繃涓洪殢鏈?浣嶅瓧绗︼級锛? path
sleep 1
if [[ -z $path ]]; then
path=`date +%s%N |md5sum | cut -c 1-3`
fi
/usr/local/x-ui/x-ui setting -webBasePath ${path} >/dev/null 2>&1
green "x-ui鐧诲綍鏍硅矾寰勶細${path}"
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
#curl -sL https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1 > /usr/local/x-ui/v
curl -sL https://raw.githubusercontent.com/a820820/x-ui/main/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1 > /usr/local/x-ui/v
showxuiip
sleep 2
xuigo
cronxui
echo "----------------------------------------------------------------------"
blue "x-ui-yg $(cat /usr/local/x-ui/v 2>/dev/null) 瀹夎鎴愬姛锛岃嚜鍔ㄨ繘鍏?x-ui 鏄剧ず绠＄悊鑿滃崟" && sleep 4
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
#[[ -e /etc/gai.conf ]] && grep -qE '^ *precedence ::ffff:0:0/96  100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf 2>/dev/null
}

update() {
yellow "鍗囩骇涔熸湁鍙兘鍑烘剰澶栧摝锛屽缓璁涓嬶細"
yellow "涓€銆佺偣鍑粁-ui闈㈢増涓殑澶囦唤涓庢仮澶嶏紝涓嬭浇澶囦唤鏂囦欢x-ui-yg.db"
yellow "浜屻€佸湪 /etc/x-ui-yg 璺緞瀵煎嚭澶囦唤鏂囦欢x-ui-yg.db"
readp "纭畾鍗囩骇锛岃鎸夊洖杞?閫€鍑鸿鎸塩trl+c):" ins
if [[ -z $ins ]]; then
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui stop
else
systemctl stop x-ui
fi
serinstall && sleep 2
restart
#curl -sL https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1 > /usr/local/x-ui/v
curl -sL https://raw.githubusercontent.com/a820820/x-ui/main/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1 > /usr/local/x-ui/v
green "x-ui鏇存柊瀹屾垚" && sleep 2 && x-ui
else
red "杈撳叆鏈夎" && update
fi
}

uninstall() {
yellow "鏈鍗歌浇灏嗘竻闄ゆ墍鏈夋暟鎹紝寤鸿濡備笅锛?
yellow "涓€銆佺偣鍑粁-ui闈㈢増涓殑澶囦唤涓庢仮澶嶏紝涓嬭浇澶囦唤鏂囦欢x-ui-yg.db"
yellow "浜屻€佸湪 /etc/x-ui-yg 璺緞瀵煎嚭澶囦唤鏂囦欢x-ui-yg.db"
readp "纭畾鍗歌浇锛岃鎸夊洖杞?閫€鍑鸿鎸塩trl+c):" ins
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
#sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf 2>/dev/null
echo
green "x-ui宸插嵏杞藉畬鎴?
echo
blue "娆㈣繋缁х画浣跨敤x-ui-yg鑴氭湰锛歜ash <(curl -Ls https://raw.githubusercontent.com/a820820/x-ui/main/install.sh)"
echo
else
red "杈撳叆鏈夎" && uninstall
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
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/goxui.sh/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "x-ui鍋滄鎴愬姛"
else
red "x-ui鍋滄澶辫触锛岃杩愯 x-ui log 鏌ョ湅鏃ュ織骞跺弽棣? && exit
fi
}

restart() {
yellow "璇风◢绛夆€︹€?
if [[ x"${release}" == x"alpine" ]]; then
rc-service x-ui restart
else
systemctl restart x-ui
fi
sleep 2
check_status
if [[ $? == 0 ]]; then
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/goxui.sh/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
echo "* * * * * /usr/local/x-ui/goxui.sh" >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "x-ui閲嶅惎鎴愬姛"
else
red "x-ui閲嶅惎澶辫触锛岃杩愯 x-ui log 鏌ョ湅鏃ュ織骞跺弽棣? && exit
fi
}

show_log() {
if [[ x"${release}" == x"alpine" ]]; then
yellow "鏆備笉鏀寔alpine鏌ョ湅鏃ュ織"
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
white " 鍥瀤-ui涓昏彍鍗曪紝璇锋寜浠绘剰閿?
white " 閫€鍑鸿剼鏈紝璇锋寜Ctrl+C"
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
readp "1. 鍋滄 x-ui \n2. 閲嶅惎 x-ui \n0. 杩斿洖涓昏彍鍗昞n璇烽€夋嫨锛? action
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
readp "1. 鏇存敼 x-ui 鐢ㄦ埛鍚嶄笌瀵嗙爜 \n2. 鏇存敼 x-ui 闈㈡澘鐧诲綍绔彛\n3. 鏇存敼 x-ui 闈㈡澘鏍硅矾寰刓n4. 閲嶇疆 x-ui 闈㈡澘璁剧疆锛堥潰鏉胯缃€夐」涓墍鏈夎缃兘鎭㈠鍑哄巶璁剧疆锛岀櫥褰曠鍙ｄ笌闈㈡澘鏍硅矾寰勫皢閲嶆柊鑷畾涔夛紝璐﹀彿瀵嗙爜涓嶅彉锛塡n0. 杩斿洖涓昏彍鍗昞n璇烽€夋嫨锛? action
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

check_status() {
if [[ x"${release}" == x"alpine" ]]; then
if [[ ! -f /etc/init.d/x-ui ]]; then
return 2
fi
temp=$(rc-service x-ui status | awk '{print $3}')
if [[ x"${temp}" == x"started" ]]; then
return 0
else
return 1
fi
else
if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
return 2
fi
temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ x"${temp}" == x"running" ]]; then
return 0
else
return 1
fi
fi
}

check_enabled() {
if [[ x"${release}" == x"alpine" ]]; then
temp=$(rc-status default | grep x-ui | awk '{print $1}')
if [[ x"${temp}" == x"x-ui" ]]; then
return 0
else
return 1
fi
else
temp=$(systemctl is-enabled x-ui)
if [[ x"${temp}" == x"enabled" ]]; then
return 0
else
return 1
fi
fi
}

check_uninstall() {
check_status
if [[ $? != 2 ]]; then
yellow "x-ui宸插畨瑁咃紝鍙厛閫夋嫨2鍗歌浇锛屽啀瀹夎" && sleep 3
if [[ $# == 0 ]]; then
show_menu
fi
return 1
else
return 0
fi
}

check_install() {
check_status
if [[ $? == 2 ]]; then
yellow "鏈畨瑁厁-ui锛岃鍏堝畨瑁厁-ui" && sleep 3
if [[ $# == 0 ]]; then
show_menu
fi
return 1
else
return 0
fi
}

show_status() {
check_status
case $? in
0)
echo -e "x-ui鐘舵€? $blue宸茶繍琛?plain"
show_enable_status
;;
1)
echo -e "x-ui鐘舵€? $yellow鏈繍琛?plain"
show_enable_status
;;
2)
echo -e "x-ui鐘舵€? $red鏈畨瑁?plain"
esac
show_xray_status
}

show_enable_status() {
check_enabled
if [[ $? == 0 ]]; then
echo -e "x-ui鑷惎: $blue鏄?plain"
else
echo -e "x-ui鑷惎: $red鍚?plain"
fi
}

check_xray_status() {
count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
if [[ count -ne 0 ]]; then
return 0
else
return 1
fi
}

show_xray_status() {
check_xray_status
if [[ $? == 0 ]]; then
echo -e "xray鐘舵€? $blue宸插惎鍔?plain"
else
echo -e "xray鐘舵€? $red鏈惎鍔?plain"
fi
}

xuigo(){
cat>/usr/local/x-ui/goxui.sh<<-\EOF
#!/bin/bash
xui=`ps -aux |grep "x-ui" |grep -v "grep" |wc -l`
xray=`ps -aux |grep "xray" |grep -v "grep" |wc -l`
if [ $xui = 0 ];then
systemctl restart x-ui
fi
if [ $xray = 0 ];then
systemctl restart x-ui
fi
EOF
chmod +x /usr/local/x-ui/goxui.sh
}

cronxui(){
uncronxui
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
echo "* * * * * /usr/local/x-ui/goxui.sh" >> /root/.xui_crontab.tmp
echo "0 2 * * * systemctl restart x-ui" >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
}

uncronxui(){
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/goxui.sh/d' /root/.xui_crontab.tmp
sed -i '/systemctl restart x-ui/d' /root/.xui_crontab.tmp
sed -i '/xuiargoport.log/d' /root/.xui_crontab.tmp
sed -i '/xuiargopid.log/d' /root/.xui_crontab.tmp
sed -i '/xuiargoympid/d' /root/.xui_crontab.tmp
sed -i '/xuiwpphid.log/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
}

close(){
systemctl stop firewalld.service >/dev/null 2>&1
systemctl disable firewalld.service >/dev/null 2>&1
setenforce 0 >/dev/null 2>&1
ufw disable >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -t mangle -F >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -X >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
if [[ -n $(apachectl -v 2>/dev/null) ]]; then
systemctl stop httpd.service >/dev/null 2>&1
systemctl disable httpd.service >/dev/null 2>&1
service apache2 stop >/dev/null 2>&1
systemctl disable apache2 >/dev/null 2>&1
fi
sleep 1
green "鎵ц寮€鏀剧鍙ｏ紝鍏抽棴闃茬伀澧欏畬姣?
}

openyn(){
echo
readp "鏄惁寮€鏀剧鍙ｏ紝鍏抽棴闃茬伀澧欙紵\n1銆佹槸锛屾墽琛?鍥炶溅榛樿)\n2銆佸惁锛岃烦杩囷紒鑷澶勭悊\n璇烽€夋嫨锛? action
if [[ -z $action ]] || [[ $action == "1" ]]; then
close
elif [[ $action == "2" ]]; then
echo
else
red "杈撳叆閿欒,璇烽噸鏂伴€夋嫨" && openyn
fi
}

changeserv(){
echo
readp "1锛氳缃瓵rgo涓存椂銆佸浐瀹氶毀閬揬n2锛氳缃畍mess涓巚less鑺傜偣鍦ㄨ闃呴摼鎺ヤ腑鐨勪紭閫塈P鍦板潃\n3锛氳缃瓽itlab璁㈤槄鍒嗕韩閾炬帴\n4锛氳幏鍙杦arp-wireguard鏅€氳处鍙烽厤缃甛n0锛氳繑鍥炰笂灞俓n璇烽€夋嫨銆?-4銆戯細" menu
if [ "$menu" = "1" ];then
xuiargo
elif [ "$menu" = "2" ];then
xuicfadd
elif [ "$menu" = "3" ];then
gitlabsub
elif [ "$menu" = "4" ];then
warpwg
else 
show_menu
fi
}

warpwg(){
warpcode(){
reg(){
keypair=$(openssl genpkey -algorithm X25519|openssl pkey -text -noout)
private_key=$(echo "$keypair" | awk '/priv:/{flag=1; next} /pub:/{flag=0} flag' | tr -d '[:space:]' | xxd -r -p | base64)
public_key=$(echo "$keypair" | awk '/pub:/{flag=1} flag' | tr -d '[:space:]' | xxd -r -p | base64)
curl -X POST 'https://api.cloudflareclient.com/v0a2158/reg' -sL --tlsv1.3 \
-H 'CF-Client-Version: a-7.21-0721' -H 'Content-Type: application/json' \
-d \
'{
"key":"'${public_key}'",
"tos":"'$(date +"%Y-%m-%dT%H:%M:%S.000Z")'"
}' \
| python3 -m json.tool | sed "/\"account_type\"/i\         \"private_key\": \"$private_key\","
}
reserved(){
reserved_str=$(echo "$warp_info" | grep 'client_id' | cut -d\" -f4)
reserved_hex=$(echo "$reserved_str" | base64 -d | xxd -p)
reserved_dec=$(echo "$reserved_hex" | fold -w2 | while read HEX; do printf '%d ' "0x${HEX}"; done | awk '{print "["$1", "$2", "$3"]"}')
echo -e "{\n    \"reserved_dec\": $reserved_dec,"
echo -e "    \"reserved_hex\": \"0x$reserved_hex\","
echo -e "    \"reserved_str\": \"$reserved_str\"\n}"
}
result() {
echo "$warp_reserved" | grep -P "reserved" | sed "s/ //g" | sed 's/:"/: "/g' | sed 's/:\[/: \[/g' | sed 's/\([0-9]\+\),\([0-9]\+\),\([0-9]\+\)/\1, \2, \3/' | sed 's/^"/    "/g' | sed 's/"$/",/g'
echo "$warp_info" | grep -P "(private_key|public_key|\"v4\": \"172.16.0.2\"|\"v6\": \"2)" | sed "s/ //g" | sed 's/:"/: "/g' | sed 's/^"/    "/g'
echo "}"
}
warp_info=$(reg) 
warp_reserved=$(reserved) 
result
}
output=$(warpcode)
if ! echo "$output" 2>/dev/null | grep -w "private_key" > /dev/null; then
v6=2606:4700:110:8f20:f22e:2c8d:d8ee:fe7
pvk=SGU6hx3CJAWGMr6XYoChvnrKV61hxAw2S4VlgBAxzFs=
res=[15,242,244]
else
pvk=$(echo "$output" | sed -n 4p | awk '{print $2}' | tr -d ' "' | sed 's/.$//')
v6=$(echo "$output" | sed -n 7p | awk '{print $2}' | tr -d ' "')
res=$(echo "$output" | sed -n 1p | awk -F":" '{print $NF}' | tr -d ' ' | sed 's/.$//')
fi
green "鎴愬姛鐢熸垚warp-wireguard鏅€氳处鍙烽厤缃紝杩涘叆x-ui闈㈡澘-闈㈡澘璁剧疆-Xray閰嶇疆鍑虹珯璁剧疆锛岃繘琛屼笁瑕佺礌鏇挎崲"
blue "Private_key绉侀挜锛?pvk"
blue "IPV6鍦板潃锛?v6"
blue "reserved鍊硷細$res"
}

cloudflaredargo(){
if [ ! -e /usr/local/x-ui/cloudflared ]; then
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
#aarch64) cpu=car;;
#x86_64) cpu=cam;;
esac
curl -L -o /usr/local/x-ui/cloudflared -# --retry 2 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
#curl -L -o /usr/local/x-ui/cloudflared -# --retry 2 https://gitlab.com/rwkgyg/sing-box-yg/-/raw/main/$cpu
chmod +x /usr/local/x-ui/cloudflared
fi
}

xuiargo(){
echo
yellow "寮€鍚疉rgo闅ч亾鑺傜偣鐨勪笁涓墠鎻愯姹傦細"
green "涓€銆佽妭鐐圭殑浼犺緭鍗忚鏄疻S"
green "浜屻€佽妭鐐圭殑TLS蹇呴』鍏抽棴"
green "涓夈€佽妭鐐圭殑璇锋眰澶寸暀绌轰笉璁?
green "鑺傜偣绫诲埆鍙€夛細vmess-ws銆乿less-ws銆乼rojan-ws銆乻hadowsocks-ws銆傛帹鑽恦mess-ws"
echo
yellow "1锛氳缃瓵rgo涓存椂闅ч亾"
yellow "2锛氳缃瓵rgo鍥哄畾闅ч亾"
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-2銆戯細" menu
if [ "$menu" = "1" ]; then
cfargo
elif [ "$menu" = "2" ]; then
cfargoym
else
changeserv
fi
}

cfargo(){
echo
yellow "1锛氶噸缃瓵rgo涓存椂闅ч亾鍩熷悕"
yellow "2锛氬仠姝rgo涓存椂闅ч亾"
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-2銆戯細" menu
if [ "$menu" = "1" ]; then
readp "璇疯緭鍏rgo鐩戝惉鐨刉S鑺傜偣绔彛锛? port
echo "$port" > /usr/local/x-ui/xuiargoport.log
cloudflaredargo
i=0
while [ $i -le 4 ]; do let i++
yellow "绗?i娆″埛鏂伴獙璇丆loudflared Argo闅ч亾鍩熷悕鏈夋晥鎬э紝璇风◢绛夆€︹€?
if [[ -n $(ps -e | grep cloudflared) ]]; then
kill -15 $(cat /usr/local/x-ui/xuiargopid.log 2>/dev/null) >/dev/null 2>&1
fi
/usr/local/x-ui/cloudflared tunnel --url http://localhost:$port --edge-ip-version auto --no-autoupdate --protocol http2 > /usr/local/x-ui/argo.log 2>&1 &
echo "$!" > /usr/local/x-ui/xuiargopid.log
sleep 20
if [[ -n $(curl -sL https://$(cat /usr/local/x-ui/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')/ -I | awk 'NR==1 && /404|400|503/') ]]; then
argo=$(cat /usr/local/x-ui/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
blue "Argo闅ч亾鐢宠鎴愬姛锛屽煙鍚嶉獙璇佹湁鏁堬細$argo" && sleep 2
break
fi
if [ $i -eq 5 ]; then
red "璇锋敞鎰?
yellow "1锛氳纭繚浣犺緭鍏ョ殑绔彛鏄痻-ui宸插垱寤篧S鍗忚绔彛"
yellow "2锛欰rgo鍩熷悕楠岃瘉鏆備笉鍙敤锛岀◢鍚庡彲鑳戒細鑷姩鎭㈠锛屾垨鑰呭啀娆￠噸缃? && sleep 2
fi
done
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiargoport.log/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "/usr/local/x-ui/cloudflared tunnel --url http://localhost:$(cat /usr/local/x-ui/xuiargoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > /usr/local/x-ui/argo.log 2>&1 & pid=\$! && echo \$pid > /usr/local/x-ui/xuiargopid.log"' >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
elif [ "$menu" = "2" ]; then
kill -15 $(cat /usr/local/x-ui/xuiargopid.log 2>/dev/null) >/dev/null 2>&1
rm -rf /usr/local/x-ui/argo.log /usr/local/x-ui/xuiargopid.log /usr/local/x-ui/xuiargoport.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiargopid.log/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "宸插嵏杞紸rgo涓存椂闅ч亾"
else
xuiargo
fi
}

cfargoym(){
echo
if [[ -f /usr/local/x-ui/xuiargotoken.log && -f /usr/local/x-ui/xuiargoym.log ]]; then
green "褰撳墠Argo鍥哄畾闅ч亾鍩熷悕锛?(cat /usr/local/x-ui/xuiargoym.log 2>/dev/null)"
green "褰撳墠Argo鍥哄畾闅ч亾Token锛?(cat /usr/local/x-ui/xuiargotoken.log 2>/dev/null)"
fi
echo
green "璇风‘淇滳loudflare瀹樼綉 --- Zero Trust --- Networks --- Tunnels宸茶缃畬鎴?
yellow "1锛氶噸缃?璁剧疆Argo鍥哄畾闅ч亾鍩熷悕"
yellow "2锛氬仠姝rgo鍥哄畾闅ч亾"
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-2銆戯細" menu
if [ "$menu" = "1" ]; then
readp "璇疯緭鍏rgo鐩戝惉鐨刉S鑺傜偣绔彛锛? port
echo "$port" > /usr/local/x-ui/xuiargoymport.log
cloudflaredargo
readp "杈撳叆Argo鍥哄畾闅ч亾Token: " argotoken
readp "杈撳叆Argo鍥哄畾闅ч亾鍩熷悕: " argoym
if [[ -n $(ps -e | grep cloudflared) ]]; then
kill -15 $(cat /usr/local/x-ui/xuiargoympid.log 2>/dev/null) >/dev/null 2>&1
fi
echo
if [[ -n "${argotoken}" && -n "${argoym}" ]]; then
nohup setsid /usr/local/x-ui/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${argotoken} >/dev/null 2>&1 & echo "$!" > /usr/local/x-ui/xuiargoympid.log
sleep 20
fi
echo ${argoym} > /usr/local/x-ui/xuiargoym.log
echo ${argotoken} > /usr/local/x-ui/xuiargotoken.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiargoympid/d' /root/.xui_crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "nohup setsid /usr/local/x-ui/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat /usr/local/x-ui/xuiargotoken.log 2>/dev/null) >/dev/null 2>&1 & pid=\$! && echo \$pid > /usr/local/x-ui/xuiargoympid.log"' >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
argo=$(cat /usr/local/x-ui/xuiargoym.log 2>/dev/null)
blue "Argo鍥哄畾闅ч亾璁剧疆瀹屾垚锛屽浐瀹氬煙鍚嶏細$argo"
elif [ "$menu" = "2" ]; then
kill -15 $(cat /usr/local/x-ui/xuiargoympid.log 2>/dev/null) >/dev/null 2>&1
rm -rf /usr/local/x-ui/xuiargoym.log /usr/local/x-ui/xuiargoymport.log /usr/local/x-ui/xuiargoympid.log /usr/local/x-ui/xuiargotoken.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiargoympid/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "宸插嵏杞紸rgo鍥哄畾闅ч亾"
else
xuiargo
fi
}

xuicfadd(){
[[ -s /usr/local/x-ui/bin/xuicdnip_ws.txt ]] && cdnwsname=$(cat /usr/local/x-ui/bin/xuicdnip_ws.txt 2>/dev/null)  || cdnwsname='鍩熷悕鎴朓P鐩磋繛'
[[ -s /usr/local/x-ui/bin/xuicdnip_argo.txt ]] && cdnargoname=$(cat /usr/local/x-ui/bin/xuicdnip_argo.txt 2>/dev/null)  || cdnargoname=www.visa.com.sg
echo
green "鎺ㄨ崘浣跨敤绋冲畾鐨勪笘鐣屽ぇ鍘傛垨缁勭粐鐨凜DN缃戠珯浣滀负瀹㈡埛绔紭閫塈P鍦板潃锛?
blue "www.visa.com.sg"
blue "www.wto.org"
blue "www.web.com"
echo
yellow "1锛氳缃墍鏈変富鑺傜偣vmess/vless璁㈤槄鑺傜偣瀹㈡埛绔紭閫塈P鍦板潃 銆愬綋鍓嶆浣跨敤锛?cdnwsname銆?
yellow "2锛氳缃瓵rgo鑺傜偣vmess/vless璁㈤槄鑺傜偣瀹㈡埛绔紭閫塈P鍦板潃 銆愬綋鍓嶆浣跨敤锛?cdnargoname銆?
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-2銆戯細" menu
if [ "$menu" = "1" ]; then
red "璇风‘淇濇湰鍦癐P宸茶В鏋愬埌CF鎵樼鐨勫煙鍚嶄笂锛岃妭鐐圭鍙ｅ凡璁剧疆涓?3涓狢F鏍囧噯绔彛锛?
red "鍏硉ls绔彛锛?052銆?082銆?086銆?095銆?0銆?880銆?080"
red "寮€tls绔彛锛?053銆?083銆?087銆?096銆?443銆?43"
red "濡傛灉VPS涓嶆敮鎸佷互涓?3涓狢F鏍囧噯绔彛锛圢AT绫籚PS锛夛紝璇峰湪CF瑙勫垯椤甸潰---Origin Rules椤甸潰涓嬭缃ソ鍥炴簮瑙勫垯" && sleep 2
echo
readp "杈撳叆鑷畾涔夌殑浼橀€塈P/鍩熷悕 (鍥炶溅璺宠繃琛ㄧず鎭㈠鏈湴IP鐩磋繛)锛? menu
[[ -z "$menu" ]] && > /usr/local/x-ui/bin/xuicdnip_ws.txt || echo "$menu" > /usr/local/x-ui/bin/xuicdnip_ws.txt
green "璁剧疆鎴愬姛锛屽彲閫夋嫨7鍒锋柊" && sleep 2 && show_menu
elif [ "$menu" = "2" ]; then
red "璇风‘淇滱rgo涓存椂闅ч亾鎴栬€呭浐瀹氶毀閬撶殑鑺傜偣鍔熻兘宸插惎鐢? && sleep 2
readp "杈撳叆鑷畾涔夌殑浼橀€塈P/鍩熷悕 (鍥炶溅璺宠繃琛ㄧず鐢ㄩ粯璁や紭閫夊煙鍚嶏細www.visa.com.sg)锛? menu
[[ -z "$menu" ]] && > /usr/local/x-ui/bin/xuicdnip_argo.txt || echo "$menu" > /usr/local/x-ui/bin/xuicdnip_argo.txt
green "璁剧疆鎴愬姛锛屽彲閫夋嫨7鍒锋柊" && sleep 2 && show_menu
else
changeserv
fi
}

gitlabsub(){
echo
green "璇风‘淇滸itlab瀹樼綉涓婂凡寤虹珛椤圭洰锛屽凡寮€鍚帹閫佸姛鑳斤紝宸茶幏鍙栬闂护鐗?
yellow "1锛氶噸缃?璁剧疆Gitlab璁㈤槄閾炬帴"
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-1銆戯細" menu
if [ "$menu" = "1" ]; then
chown -R root:root /usr/local/x-ui/bin /usr/local/x-ui
cd /usr/local/x-ui/bin
readp "杈撳叆鐧诲綍閭: " email
readp "杈撳叆璁块棶浠ょ墝: " token
readp "杈撳叆鐢ㄦ埛鍚? " userid
readp "杈撳叆椤圭洰鍚? " project
echo
green "澶氬彴VPS鍙叡鐢ㄤ竴涓护鐗屽強椤圭洰鍚嶏紝鍙垱寤哄涓垎鏀闃呴摼鎺?
green "鍥炶溅璺宠繃琛ㄧず涓嶆柊寤猴紝浠呬娇鐢ㄤ富鍒嗘敮main璁㈤槄閾炬帴(棣栧彴VPS寤鸿鍥炶溅璺宠繃)"
readp "鏂板缓鍒嗘敮鍚嶇О(鍙殢鎰忓～鍐?: " gitlabml
echo
sharesub_sbcl >/dev/null 2>&1
if [[ -z "$gitlabml" ]]; then
gitlab_ml=''
git_sk=main
rm -rf /usr/local/x-ui/bin/gitlab_ml_ml
else
gitlab_ml=":${gitlabml}"
git_sk="${gitlabml}"
echo "${gitlab_ml}" > /usr/local/x-ui/bin/gitlab_ml_ml
fi
echo "$token" > /usr/local/x-ui/bin/gitlabtoken.txt
rm -rf /usr/local/x-ui/bin/.git
git init >/dev/null 2>&1
git add xui_singbox.json xui_clashmeta.yaml xui_ty.txt>/dev/null 2>&1
git config --global user.email "${email}" >/dev/null 2>&1
git config --global user.name "${userid}" >/dev/null 2>&1
git commit -m "commit_add_$(date +"%F %T")" >/dev/null 2>&1
branches=$(git branch)
if [[ $branches == *master* ]]; then
git branch -m master main >/dev/null 2>&1
fi
git remote add origin https://${token}@gitlab.com/${userid}/${project}.git >/dev/null 2>&1
if [[ $(ls -a | grep '^\.git$') ]]; then
cat > /usr/local/x-ui/bin/gitpush.sh <<EOF
#!/usr/bin/expect
spawn bash -c "git push -f origin main${gitlab_ml}"
expect "Password for 'https://$(cat /usr/local/x-ui/bin/gitlabtoken.txt 2>/dev/null)@gitlab.com':"
send "$(cat /usr/local/x-ui/bin/gitlabtoken.txt 2>/dev/null)\r"
interact
EOF
chmod +x gitpush.sh
./gitpush.sh "git push -f origin main${gitlab_ml}" cat /usr/local/x-ui/bin/gitlabtoken.txt >/dev/null 2>&1
echo "https://gitlab.com/api/v4/projects/${userid}%2F${project}/repository/files/xui_singbox.json/raw?ref=${git_sk}&private_token=${token}" > /usr/local/x-ui/bin/sing_box_gitlab.txt
echo "https://gitlab.com/api/v4/projects/${userid}%2F${project}/repository/files/xui_clashmeta.yaml/raw?ref=${git_sk}&private_token=${token}" > /usr/local/x-ui/bin/clash_meta_gitlab.txt
echo "https://gitlab.com/api/v4/projects/${userid}%2F${project}/repository/files/xui_ty.txt/raw?ref=${git_sk}&private_token=${token}" > /usr/local/x-ui/bin/xui_ty_gitlab.txt
sharesubshow
else
yellow "璁剧疆Gitlab璁㈤槄閾炬帴澶辫触锛岃鍙嶉"
fi
cd
else
changeserv
fi
}

sharesubshow(){
green "褰撳墠X-ui-Sing-box鑺傜偣宸叉洿鏂板苟鎺ㄩ€?
green "Sing-box璁㈤槄閾炬帴濡備笅锛?
blue "$(cat /usr/local/x-ui/bin/sing_box_gitlab.txt 2>/dev/null)"
echo
green "Sing-box璁㈤槄閾炬帴浜岀淮鐮佸涓嬶細"
qrencode -o - -t ANSIUTF8 "$(cat /usr/local/x-ui/bin/sing_box_gitlab.txt 2>/dev/null)"
sleep 3
echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
green "褰撳墠X-ui-Clash-meta鑺傜偣閰嶇疆宸叉洿鏂板苟鎺ㄩ€?
green "Clash-meta璁㈤槄閾炬帴濡備笅锛?
blue "$(cat /usr/local/x-ui/bin/clash_meta_gitlab.txt 2>/dev/null)"
echo
green "Clash-meta璁㈤槄閾炬帴浜岀淮鐮佸涓嬶細"
qrencode -o - -t ANSIUTF8 "$(cat /usr/local/x-ui/bin/clash_meta_gitlab.txt 2>/dev/null)"
sleep 3
echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
green "褰撳墠X-ui鑱氬悎閫氱敤鑺傜偣閰嶇疆宸叉洿鏂板苟鎺ㄩ€?
green "鑱氬悎閫氱敤鑺傜偣璁㈤槄閾炬帴濡備笅锛?
blue "$(cat /usr/local/x-ui/bin/xui_ty_gitlab.txt 2>/dev/null)"
sleep 3
echo
yellow "鍙互鍦ㄧ綉椤典笂杈撳叆浠ヤ笂涓変釜璁㈤槄閾炬帴鏌ョ湅閰嶇疆鍐呭锛屽鏋滄棤閰嶇疆鍐呭锛岃鑷Gitlab鐩稿叧璁剧疆骞堕噸缃?
echo
}

sharesub(){
sharesub_sbcl
echo
red "Gitlab璁㈤槄閾炬帴濡備笅锛?
echo
cd /usr/local/x-ui/bin
if [[ $(ls -a | grep '^\.git$') ]]; then
if [ -f /usr/local/x-ui/bin/gitlab_ml_ml ]; then
gitlab_ml=$(cat /usr/local/x-ui/bin/gitlab_ml_ml)
fi
git rm --cached xui_singbox.json xui_clashmeta.yaml xui_ty.txt >/dev/null 2>&1
git commit -m "commit_rm_$(date +"%F %T")" >/dev/null 2>&1
git add xui_singbox.json xui_clashmeta.yaml xui_ty.txt >/dev/null 2>&1
git commit -m "commit_add_$(date +"%F %T")" >/dev/null 2>&1
chmod +x gitpush.sh
./gitpush.sh "git push -f origin main${gitlab_ml}" cat /usr/local/x-ui/bin/gitlabtoken.txt >/dev/null 2>&1
sharesubshow
else
yellow "鏈缃瓽itlab璁㈤槄閾炬帴"
fi
cd
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "馃殌X-UI鑱氬悎閫氱敤鑺傜偣鍒嗕韩閾炬帴鏄剧ず濡備笅锛?
red "鏂囦欢鐩綍 /usr/local/x-ui/bin/xui_ty.txt 锛屽彲鐩存帴鍦ㄥ鎴风鍓垏鏉垮鍏ユ坊鍔? && sleep 2
echo
cat /usr/local/x-ui/bin/xui_ty.txt
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "馃殌X-UI-Clash-Meta閰嶇疆鏂囦欢鎿嶄綔濡備笅锛?
red "鏂囦欢鐩綍 /usr/local/x-ui/bin/xui_clashmeta.yaml 锛屽鍒惰嚜寤轰互yaml鏂囦欢鏍煎紡涓哄噯" 
echo
red "杈撳叆锛歝at /usr/local/x-ui/bin/xui_clashmeta.yaml 鍗冲彲鏄剧ず閰嶇疆鍐呭" && sleep 2
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "馃殌XUI-Sing-box-SFA/SFI/SFW閰嶇疆鏂囦欢鎿嶄綔濡備笅锛?
red "鏂囦欢鐩綍 /usr/local/x-ui/bin/xui_singbox.json 锛屽鍒惰嚜寤轰互json鏂囦欢鏍煎紡涓哄噯"
echo
red "杈撳叆锛歝at /usr/local/x-ui/bin/xui_singbox.json 鍗冲彲鏄剧ず閰嶇疆鍐呭" && sleep 2
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}

sharesub_sbcl(){
if [[ -s /usr/local/x-ui/bin/xuicdnip_argo.txt ]]; then
cdnargo=$(cat /usr/local/x-ui/bin/xuicdnip_argo.txt 2>/dev/null)
else
cdnargo=www.visa.com.sg
fi
green "璇风◢绛夆€︹€?
xip1=$(cat /usr/local/x-ui/xip 2>/dev/null | sed -n 1p)
if [[ "$xip1" =~ : ]]; then
dnsip='tls://[2001:4860:4860::8888]/dns-query'
else
dnsip='tls://8.8.8.8/dns-query'
fi
cat > /usr/local/x-ui/bin/xui_singbox.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "external_ui": "ui",
      "external_ui_download_url": "",
      "external_ui_download_detour": "",
      "secret": "",
      "default_mode": "Rule"
       },
      "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "store_fakeip": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "proxydns",
                "address": "$dnsip",
                "detour": "select"
            },
            {
                "tag": "localdns",
                "address": "h3://223.5.5.5/dns-query",
                "detour": "direct"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "localdns",
                "disable_cache": true
            },
            {
                "clash_mode": "Global",
                "server": "proxydns"
            },
            {
                "clash_mode": "Direct",
                "server": "localdns"
            },
            {
                "rule_set": "geosite-cn",
                "server": "localdns"
            },
            {
                 "rule_set": "geosite-geolocation-!cn",
                 "server": "proxydns"
            },
             {
                "rule_set": "geosite-geolocation-!cn",         
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_fakeip"
            }
          ],
           "fakeip": {
           "enabled": true,
           "inet4_range": "198.18.0.0/15",
           "inet6_range": "fc00::/18"
         },
          "independent_cache": true,
          "final": "proxydns"
        },
      "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "address": [
      "172.19.0.1/30",
      "fd00::1/126"
      ],
      "auto_route": true,
      "strict_route": true,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "prefer_ipv4"
    }
  ],
  "outbounds": [

//_0

    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "select",
      "type": "selector",
      "default": "auto",
      "outbounds": [
        "auto",

//_1

      ]
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [

//_2

      ],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50,
      "interrupt_exist_connections": false
    }
  ],
  "route": {
      "rule_set": [
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-!cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            }
        ],
    "auto_detect_interface": true,
    "final": "select",
    "rules": [
      {
      "inbound": "tun-in",
      "action": "sniff"
      },
      {
      "protocol": "dns",
      "action": "hijack-dns"
      },
      {
      "port": 443,
      "network": "udp",
      "action": "reject"
      },
      {
        "clash_mode": "Direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "Global",
        "outbound": "select"
      },
      {
        "rule_set": "geoip-cn",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-cn",
        "outbound": "direct"
      },
      {
      "ip_is_private": true,
      "outbound": "direct"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "outbound": "select"
      }
    ]
  },
    "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m",
    "detour": "direct"
  }
}
EOF

cat > /usr/local/x-ui/bin/xui_clashmeta.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
global-client-fingerprint: chrome
dns:
  enable: false
  listen: :53
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver: 
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - tls://dns.google
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

proxies:

#_0

proxy-groups:
- name: 璐熻浇鍧囪　
  type: load-balance
  url: https://www.gstatic.com/generate_204
  interval: 300
  strategy: round-robin
  proxies: 

#_1


- name: 鑷姩閫夋嫨
  type: url-test
  url: https://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:  

#_2                         
    
- name: 馃實閫夋嫨浠ｇ悊鑺傜偣
  type: select
  proxies:
    - 璐熻浇鍧囪　                                         
    - 鑷姩閫夋嫨
    - DIRECT

#_3

rules:
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,馃實閫夋嫨浠ｇ悊鑺傜偣
EOF

xui_sb_cl(){
sed -i "/#_0/r /usr/local/x-ui/bin/cl${i}.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - $tag" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - $tag" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - $tag" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sb${i}.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"$tag\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"$tag\"," /usr/local/x-ui/bin/xui_singbox.json
}

tag_count=$(jq '.inbounds | map(select(.protocol == "vless" or .protocol == "vmess" or .protocol == "trojan" or .protocol == "shadowsocks")) | length' /usr/local/x-ui/bin/config.json)
for ((i=0; i<tag_count; i++))
do
jq -c ".inbounds | map(select(.protocol == \"vless\" or .protocol == \"vmess\" or .protocol == \"trojan\" or .protocol == \"shadowsocks\"))[$i]" /usr/local/x-ui/bin/config.json > "/usr/local/x-ui/bin/$((i+1)).log"
done
rm -rf /usr/local/x-ui/bin/ty.txt
xip1=$(cat /usr/local/x-ui/xip 2>/dev/null | sed -n 1p)
ymip=$(cat /root/ygkkkca/ca.log 2>/dev/null)
directory="/usr/local/x-ui/bin/"
for i in $(seq 1 $tag_count); do
file="${directory}${i}.log"
if [ -f "$file" ]; then
#vless-reality-vision
if grep -q "vless" "$file" && grep -q "reality" "$file" && grep -q "vision" "$file"; then
finger=$(jq -r '.streamSettings.realitySettings.fingerprint' /usr/local/x-ui/bin/${i}.log)
vl_name=$(jq -r '.streamSettings.realitySettings.serverNames[0]' /usr/local/x-ui/bin/${i}.log)
public_key=$(jq -r '.streamSettings.realitySettings.publicKey' /usr/local/x-ui/bin/${i}.log)
short_id=$(jq -r '.streamSettings.realitySettings.shortIds[0]' /usr/local/x-ui/bin/${i}.log)
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vl_port-vless-reality-vision
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

 {
      "type": "vless",
      "tag": "$tag",
      "server": "$xip1",
      "server_port": $vl_port,
      "uuid": "$uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$vl_name",
        "utls": {
          "enabled": true,
          "fingerprint": "$finger"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key",
          "short_id": "$short_id"
        }
      }
    },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag               
  type: vless
  server: $xip1                           
  port: $vl_port                                
  uuid: $uuid   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $vl_name                 
  reality-opts: 
    public-key: $public_key    
    short-id: $short_id                      
  client-fingerprint: $finger   

EOF
echo "vless://$uuid@$xip1:$vl_port?type=tcp&security=reality&sni=$vl_name&pbk=$public_key&flow=xtls-rprx-vision&sid=$short_id&fp=$finger#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#vless-tcp-vision
elif grep -q "vless" "$file" && grep -q "vision" "$file" && grep -q "keyFile" "$file"; then
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vl_port-vless-tcp-vision
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vl_port,
            "tag": "$tag",
            "tls": {
                "enabled": true,
                "insecure": false
            },
            "type": "vless",
            "flow": "xtls-rprx-vision",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag           
  type: vless
  server: $servip                     
  port: $vl_port                                  
  uuid: $uuid  
  network: tcp
  tls: true
  udp: true
  flow: xtls-rprx-vision


EOF
echo "vless://$uuid@$servip:$vl_port?type=tcp&security=tls&flow=xtls-rprx-vision#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#vless-ws
elif grep -q "vless" "$file" && grep -q "ws" "$file" && ! grep -qw "{}}}" "$file"; then
ws_path=$(jq -r '.streamSettings.wsSettings.path' /usr/local/x-ui/bin/${i}.log)
tls=$(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
if [[ $tls == 'tls' ]]; then
tls=true 
tlsw=tls
else
tls=false 
tlsw=''
fi
if ! [[ "$vl_port" =~ ^(2052|2082|2086|2095|80|8880|8080|2053|2083|2087|2096|8443|443)$ ]] && [[ -s /usr/local/x-ui/bin/xuicdnip_ws.txt ]]; then
servip=$(cat /usr/local/x-ui/bin/xuicdnip_ws.txt 2>/dev/null)
if [[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]]; then
vl_port=8443
tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-鍥炴簮-vless-ws-tls
else
vl_port=8880
tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-鍥炴簮-vless-ws
fi
elif [[ "$vl_port" =~ ^(2052|2082|2086|2095|80|8880|8080|2053|2083|2087|2096|8443|443)$ ]] && [[ -s /usr/local/x-ui/bin/xuicdnip_ws.txt ]]; then
servip=$(cat /usr/local/x-ui/bin/xuicdnip_ws.txt 2>/dev/null)
[[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]] && tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vless-ws-tls || tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vless-ws
else
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
[[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]] && tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vless-ws-tls || tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vless-ws
fi
vl_name=$(jq -r '.streamSettings.wsSettings.headers.Host' /usr/local/x-ui/bin/${i}.log)
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)



cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vl_port,
            "tag": "$tag",
            "tls": {
                "enabled": $tls,
                "server_name": "$vl_name",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$vl_name"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: vless
  server: $servip                       
  port: $vl_port                                     
  uuid: $uuid     
  udp: true
  tls: $tls
  network: ws
  servername: $vl_name                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $vl_name 

EOF
echo "vless://$uuid@$servip:$vl_port?type=ws&security=$tlsw&sni=$vl_name&path=$ws_path&host=$vl_name#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#vmess-ws
elif grep -q "vmess" "$file" && grep -q "ws" "$file" && ! grep -qw "{}}}" "$file"; then
ws_path=$(jq -r '.streamSettings.wsSettings.path' /usr/local/x-ui/bin/${i}.log)
vm_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tls=$(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log)
if [[ $tls == 'tls' ]]; then
tls=true 
tlsw=tls
else
tls=false 
tlsw=''
fi
if ! [[ "$vm_port" =~ ^(2052|2082|2086|2095|80|8880|8080|2053|2083|2087|2096|8443|443)$ ]] && [[ -s /usr/local/x-ui/bin/xuicdnip_ws.txt ]]; then
servip=$(cat /usr/local/x-ui/bin/xuicdnip_ws.txt 2>/dev/null)
if [[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]]; then
vm_port=8443
tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-鍥炴簮-vmess-ws-tls
else
vm_port=8880
tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-鍥炴簮-vmess-ws
fi
elif [[ "$vm_port" =~ ^(2052|2082|2086|2095|80|8880|8080|2053|2083|2087|2096|8443|443)$ ]] && [[ -s /usr/local/x-ui/bin/xuicdnip_ws.txt ]]; then
servip=$(cat /usr/local/x-ui/bin/xuicdnip_ws.txt 2>/dev/null)
[[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]] && tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vmess-ws-tls || tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vmess-ws
else
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
[[ $(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log) == 'tls' ]] && tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vmess-ws-tls || tag=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)-vmess-ws
fi
vm_name=$(jq -r '.streamSettings.wsSettings.headers.Host' /usr/local/x-ui/bin/${i}.log)
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vm_port,
            "tag": "$tag",
            "tls": {
                "enabled": $tls,
                "server_name": "$vm_name",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$vm_name"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: vmess
  server: $servip                        
  port: $vm_port                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: $tls
  network: ws
  servername: $vm_name                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $vm_name

EOF
echo -e "vmess://$(echo '{"add":"'$servip'","aid":"0","host":"'$vm_name'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"'$vm_port'","ps":"'$tag'","tls":"'$tlsw'","sni":"'$vm_name'","type":"none","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#vmess-tcp
elif grep -q "vmess" "$file" && grep -q "tcp" "$file"; then
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
tls=$(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log)
if [[ $tls == 'tls' ]]; then
tls=true 
tlst=tls
else
tls=false 
tlst=''
fi
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)
vm_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vm_port-vmess-tcp
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vm_port,
            "tag": "$tag",
            "tls": {
                "enabled": $tls,
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: vmess
  server: $servip                        
  port: $vm_port                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: $tls

EOF
echo -e "vmess://$(echo '{"add":"'$servip'","aid":"0","id":"'$uuid'","net":"tcp","port":"'$vm_port'","ps":"'$tag'","tls":"'$tlst'","type":"none","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#vless-tcp
elif grep -q "vless" "$file" && grep -q "tcp" "$file"; then
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
tls=$(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log)
if [[ $tls == 'tls' ]]; then
tls=true 
tlst=tls
else
tls=false 
tlst=''
fi
uuid=$(jq -r '.settings.clients[0].id' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vl_port-vless-tcp
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vl_port,
            "tag": "$tag",
            "tls": {
                "enabled": $tls,
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: vless
  server: $servip                       
  port: $vl_port                                     
  uuid: $uuid     
  udp: true
  tls: $tls

EOF
echo "vless://$uuid@$servip:$vl_port?type=tcp&security=$tlst#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#trojan-tcp-tls
elif grep -q "trojan" "$file" && grep -q "tcp" "$file" && grep -q "keyFile" "$file"; then
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
password=$(jq -r '.settings.clients[0].password' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vl_port-trojan-tcp-tls
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vl_port,
            "tag": "$tag",
            "tls": {
                "enabled": true,
                "insecure": false
            },
            "type": "trojan",
            "password": "$password"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: trojan
  server: $servip                       
  port: $vl_port                                     
  password: $password    
  udp: true
  sni: $servip
  skip-cert-verify: false

EOF
echo "trojan://$password@$servip:$vl_port?security=tls&type=tcp#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#trojan-ws-tls
elif grep -q "trojan" "$file" && grep -q "ws" "$file" && grep -q "keyFile" "$file"; then
ws_path=$(jq -r '.streamSettings.wsSettings.path' /usr/local/x-ui/bin/${i}.log)
vm_name=$(jq -r '.streamSettings.wsSettings.headers.Host' /usr/local/x-ui/bin/${i}.log)
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
tls=$(jq -r '.streamSettings.security' /usr/local/x-ui/bin/${i}.log)
[[ $tls == 'tls' ]] && tls=true || tls=false
password=$(jq -r '.settings.clients[0].password' /usr/local/x-ui/bin/${i}.log)
vl_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
tag=$vl_port-trojan-ws-tls
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
            "server": "$servip",
            "server_port": $vl_port,
            "tag": "$tag",
            "tls": {
                "enabled": $tls,
                "insecure": false
            },
            "transport": {
                "headers": {
                    "Host": [
                        "$vm_name"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "trojan",
            "password": "$password"
        },
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: trojan
  server: $servip                       
  port: $vl_port                                     
  password: $password    
  udp: true
  sni: $servip
  skip-cert-verify: false
  network: ws                 
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $vm_name

EOF
echo "trojan://$password@$servip:$vl_port?security=tls&type=ws&path=$ws_path&host=$vm_name#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl

#shadowsocks-tcp
elif grep -q "shadowsocks" "$file" && grep -q "tcp" "$file"; then
[[ -n $ymip ]] && servip=$ymip || servip=$xip1
password=$(jq -r '.settings.password' /usr/local/x-ui/bin/${i}.log)
vm_port=$(jq -r '.port' /usr/local/x-ui/bin/${i}.log)
ssmethod=$(jq -r '.settings.method' /usr/local/x-ui/bin/${i}.log)
tag=$vm_port-ss-tcp
cat > /usr/local/x-ui/bin/sb${i}.log <<EOF

{
      "type": "shadowsocks",
      "tag": "$tag",
      "server": "$servip",
      "server_port": $vm_port,
      "method": "$ssmethod",
      "password": "$password"
},
EOF

cat > /usr/local/x-ui/bin/cl${i}.log <<EOF

- name: $tag                         
  type: ss
  server: $servip                        
  port: $vm_port                                     
  password: $password
  cipher: $ssmethod
  udp: true

EOF
echo -e "ss://$ssmethod:$password@$servip:$vm_port#$tag" >>/usr/local/x-ui/bin/ty.txt
xui_sb_cl
fi
else
red "褰撳墠x-ui鏈缃湁鏁堢殑鑺傜偣閰嶇疆" && exit
fi
done

argopid
argoprotocol=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .protocol' /usr/local/x-ui/bin/config.json 2>/dev/null)
uuid=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].id' /usr/local/x-ui/bin/config.json 2>/dev/null)
ws_path=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.wsSettings.path' /usr/local/x-ui/bin/config.json 2>/dev/null)
argotls=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.security' /usr/local/x-ui/bin/config.json 2>/dev/null)
argolsym=$(cat /usr/local/x-ui/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [[ -n $(ps -e | grep -w $ls 2>/dev/null) ]] && [[ -f /usr/local/x-ui/xuiargoport.log ]] && [[ $argoprotocol =~ vless|vmess ]] && [[ ! "$argotls" = "tls" ]]; then
if [[ $argoprotocol = vless ]]; then
#vless-ws-tls-argo涓存椂
cat > /usr/local/x-ui/bin/sbvltargo.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8443,
            "tag": "vl-tls-argo涓存椂-8443",
            "tls": {
                "enabled": true,
                "server_name": "$argolsym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argolsym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvltargo.log <<EOF

- name: vl-tls-argo涓存椂-8443                         
  type: vless
  server: $cdnargo                       
  port: 8443                                     
  uuid: $uuid     
  udp: true
  tls: true
  network: ws
  servername: $argolsym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argolsym 

EOF

#vless-ws-argo涓存椂
cat > /usr/local/x-ui/bin/sbvlargo.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8880,
            "tag": "vl-argo涓存椂-8880",
            "tls": {
                "enabled": false,
                "server_name": "$argolsym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argolsym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvlargo.log <<EOF

- name: vl-argo涓存椂-8880                         
  type: vless
  server: $cdnargo                       
  port: 8880                                     
  uuid: $uuid     
  udp: true
  tls: false
  network: ws
  servername: $argolsym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argolsym 

EOF
sed -i "/#_0/r /usr/local/x-ui/bin/clvltargo.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vl-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vl-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vl-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_0/r /usr/local/x-ui/bin/clvlargo.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vl-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vl-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vl-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvltargo.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vl-tls-argo涓存椂-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vl-tls-argo涓存椂-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvlargo.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vl-argo涓存椂-8880\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vl-argo涓存椂-8880\"," /usr/local/x-ui/bin/xui_singbox.json
echo "vless://$uuid@$cdnargo:8880?type=ws&security=none&path=$ws_path&host=$argolsym#vl-argo涓存椂-8880" >>/usr/local/x-ui/bin/ty.txt
echo "vless://$uuid@$cdnargo:8443?type=ws&security=tls&path=$ws_path&host=$argolsym#vl-tls-argo涓存椂-8443" >>/usr/local/x-ui/bin/ty.txt

elif [[ $argoprotocol = vmess ]]; then
#vmess-ws-tls-argo涓存椂
cat > /usr/local/x-ui/bin/sbvmtargo.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8443,
            "tag": "vm-tls-argo涓存椂-8443",
            "tls": {
                "enabled": true,
                "server_name": "$argolsym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argolsym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvmtargo.log <<EOF

- name: vm-tls-argo涓存椂-8443                        
  type: vmess
  server: $cdnargo                        
  port: 8443                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argolsym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argolsym

EOF

#vmess-ws-argo涓存椂
cat > /usr/local/x-ui/bin/sbvmargo.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8880,
            "tag": "vm-argo涓存椂-8880",
            "tls": {
                "enabled": false,
                "server_name": "$argolsym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argolsym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvmargo.log <<EOF

- name: vm-argo涓存椂-8880                         
  type: vmess
  server: $cdnargo                       
  port: 8880                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argolsym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argolsym

EOF
sed -i "/#_0/r /usr/local/x-ui/bin/clvmtargo.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vm-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vm-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vm-tls-argo涓存椂-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_0/r /usr/local/x-ui/bin/clvmargo.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vm-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vm-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vm-argo涓存椂-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvmtargo.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vm-tls-argo涓存椂-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vm-tls-argo涓存椂-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvmargo.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vm-argo涓存椂-8880\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vm-argo涓存椂-8880\"," /usr/local/x-ui/bin/xui_singbox.json
echo -e "vmess://$(echo '{"add":"'$cdnargo'","aid":"0","host":"'$argolsym'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"8880","ps":"vm-argo涓存椂-8880","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
echo -e "vmess://$(echo '{"add":"'$cdnargo'","aid":"0","host":"'$argolsym'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"8443","ps":"vm-tls-argo涓存椂-8443","tls":"tls","sni":"'$argolsym'","type":"none","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
fi
fi

argoprotocol=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .protocol' /usr/local/x-ui/bin/config.json 2>/dev/null)
uuid=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].id' /usr/local/x-ui/bin/config.json 2>/dev/null)
ws_path=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.wsSettings.path' /usr/local/x-ui/bin/config.json 2>/dev/null)
argotls=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.security' /usr/local/x-ui/bin/config.json 2>/dev/null)
argoym=$(cat /usr/local/x-ui/xuiargoym.log 2>/dev/null)
if [[ -n $(ps -e | grep -w $ym 2>/dev/null) ]] && [[ -f /usr/local/x-ui/xuiargoymport.log ]] && [[ $argoprotocol =~ vless|vmess ]] && [[ ! "$argotls" = "tls" ]]; then
if [[ $argoprotocol = vless ]]; then
#vless-ws-tls-argo鍥哄畾
cat > /usr/local/x-ui/bin/sbvltargoym.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8443,
            "tag": "vl-tls-argo鍥哄畾-8443",
            "tls": {
                "enabled": true,
                "server_name": "$argoym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argoym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvltargoym.log <<EOF

- name: vl-tls-argo鍥哄畾-8443                         
  type: vless
  server: $cdnargo                       
  port: 8443                                     
  uuid: $uuid     
  udp: true
  tls: true
  network: ws
  servername: $argoym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argoym 

EOF

#vless-ws-argo鍥哄畾
cat > /usr/local/x-ui/bin/sbvlargoym.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8880,
            "tag": "vl-argo鍥哄畾-8880",
            "tls": {
                "enabled": false,
                "server_name": "$argoym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argoym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vless",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvlargoym.log <<EOF

- name: vl-argo鍥哄畾-8880                         
  type: vless
  server: $cdnargo                       
  port: 8880                                     
  uuid: $uuid     
  udp: true
  tls: false
  network: ws
  servername: $argoym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argoym 

EOF
sed -i "/#_0/r /usr/local/x-ui/bin/clvltargoym.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vl-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vl-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vl-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_0/r /usr/local/x-ui/bin/clvlargoym.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vl-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vl-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vl-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvltargoym.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vl-tls-argo鍥哄畾-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vl-tls-argo鍥哄畾-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvlargoym.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vl-argo鍥哄畾-8880\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vl-argo鍥哄畾-8880\"," /usr/local/x-ui/bin/xui_singbox.json
echo "vless://$uuid@$cdnargo:8880?type=ws&security=none&path=$ws_path&host=$argoym#vl-argo涓存椂-8880" >>/usr/local/x-ui/bin/ty.txt
echo "vless://$uuid@$cdnargo:8443?type=ws&security=tls&path=$ws_path&host=$argoym#vl-tls-argo涓存椂-8443" >>/usr/local/x-ui/bin/ty.txt

elif [[ $argoprotocol = vmess ]]; then
#vmess-ws-tls-argo鍥哄畾
cat > /usr/local/x-ui/bin/sbvmtargoym.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8443,
            "tag": "vm-tls-argo鍥哄畾-8443",
            "tls": {
                "enabled": true,
                "server_name": "$argoym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argoym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvmtargoym.log <<EOF

- name: vm-tls-argo鍥哄畾-8443                        
  type: vmess
  server: $cdnargo                        
  port: 8443                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argoym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argoym

EOF

#vmess-ws-argo鍥哄畾
cat > /usr/local/x-ui/bin/sbvmargoym.log <<EOF

{
            "server": "$cdnargo",
            "server_port": 8880,
            "tag": "vm-argo鍥哄畾-8880",
            "tls": {
                "enabled": false,
                "server_name": "$argoym",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argoym"
                    ]
                },
                "path": "$ws_path",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF

cat > /usr/local/x-ui/bin/clvmargoym.log <<EOF

- name: vm-argo鍥哄畾-8880                         
  type: vmess
  server: $cdnargo                       
  port: 8880                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argoym                    
  ws-opts:
    path: "$ws_path"                             
    headers:
      Host: $argoym

EOF
sed -i "/#_0/r /usr/local/x-ui/bin/clvmtargoym.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vm-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vm-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vm-tls-argo鍥哄畾-8443" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_0/r /usr/local/x-ui/bin/clvmargoym.log" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_1/ i\\    - vm-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_2/ i\\    - vm-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/#_3/ i\\    - vm-argo鍥哄畾-8880" /usr/local/x-ui/bin/xui_clashmeta.yaml
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvmtargoym.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vm-tls-argo鍥哄畾-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vm-tls-argo鍥哄畾-8443\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_0/r /usr/local/x-ui/bin/sbvmargoym.log" /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_1/ i\\ \"vm-argo鍥哄畾-8880\"," /usr/local/x-ui/bin/xui_singbox.json
sed -i "/\/\/_2/ i\\ \"vm-argo鍥哄畾-8880\"," /usr/local/x-ui/bin/xui_singbox.json
echo -e "vmess://$(echo '{"add":"'$cdnargo'","aid":"0","host":"'$argoym'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"8880","ps":"vm-argo鍥哄畾-8880","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
echo -e "vmess://$(echo '{"add":"'$cdnargo'","aid":"0","host":"'$argoym'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"8443","ps":"vm-tls-argo鍥哄畾-8443","tls":"tls","sni":"'$argoym'","type":"none","v":"2"}' | base64 -w 0)" >>/usr/local/x-ui/bin/ty.txt
fi
fi
line=$(grep -B1 "//_1" /usr/local/x-ui/bin/xui_singbox.json | grep -v "//_1")
new_line=$(echo "$line" | sed 's/,//g')
sed -i "/^$line$/s/.*/$new_line/g" /usr/local/x-ui/bin/xui_singbox.json
sed -i '/\/\/_0\|\/\/_1\|\/\/_2/d' /usr/local/x-ui/bin/xui_singbox.json
sed -i '/#_0\|#_1\|#_2\|#_3/d' /usr/local/x-ui/bin/xui_clashmeta.yaml
find /usr/local/x-ui/bin -type f -name "*.log" -delete
baseurl=$(base64 -w 0 < /usr/local/x-ui/bin/ty.txt 2>/dev/null)
v2sub=$(cat /usr/local/x-ui/bin/ty.txt 2>/dev/null)
echo "$v2sub" > /usr/local/x-ui/bin/xui_ty.txt
}

insxuiwpph(){
ins(){
if [ ! -e /usr/local/x-ui/xuiwpph ]; then
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
esac
curl -L -o /usr/local/x-ui/xuiwpph -# --retry 2 https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/xuiwpph_$cpu
chmod +x /usr/local/x-ui/xuiwpph
fi
if [[ -n $(ps -e | grep xuiwpph) ]]; then
kill -15 $(cat /usr/local/x-ui/xuiwpphid.log 2>/dev/null) >/dev/null 2>&1
fi
v4v6
if [[ -n $v4 ]]; then
sw46=4
else
red "IPV4涓嶅瓨鍦紝纭繚瀹夎杩嘩ARP-IPV4妯″紡"
sw46=6
fi
echo
readp "璁剧疆WARP-plus-Socks5绔彛锛堝洖杞﹁烦杩囩鍙ｉ粯璁?0000锛夛細" port
if [[ -z $port ]]; then
port=40000
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] 
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n绔彛琚崰鐢紝璇烽噸鏂拌緭鍏ョ鍙? && readp "鑷畾涔夌鍙?" port
done
else
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\n绔彛琚崰鐢紝璇烽噸鏂拌緭鍏ョ鍙? && readp "鑷畾涔夌鍙?" port
done
fi
}
unins(){
kill -15 $(cat /usr/local/x-ui/xuiwpphid.log 2>/dev/null) >/dev/null 2>&1
rm -rf /usr/local/x-ui/xuiwpph.log /usr/local/x-ui/xuiwpphid.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiwpphid.log/d' /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
}
echo
yellow "1锛氶噸缃惎鐢╓ARP-plus-Socks5鏈湴Warp浠ｇ悊妯″紡"
yellow "2锛氶噸缃惎鐢╓ARP-plus-Socks5澶氬湴鍖篜siphon浠ｇ悊妯″紡"
yellow "3锛氬仠姝ARP-plus-Socks5浠ｇ悊妯″紡"
yellow "0锛氳繑鍥炰笂灞?
readp "璇烽€夋嫨銆?-3銆戯細" menu
if [ "$menu" = "1" ]; then
ins
nohup setsid /usr/local/x-ui/xuiwpph -b 127.0.0.1:$port -$sw46 --endpoint 162.159.192.1:2408 >/dev/null 2>&1 & echo "$!" > /usr/local/x-ui/xuiwpphid.log
green "鐢宠IP涓€︹€﹁绋嶇瓑鈥︹€? && sleep 20
resv1=$(curl -s --socks5 localhost:$port icanhazip.com)
resv2=$(curl -sx socks5h://localhost:$port icanhazip.com)
if [[ -z $resv1 && -z $resv2 ]]; then
red "WARP-plus-Socks5鐨処P鑾峰彇澶辫触" && unins && exit
else
echo "/usr/local/x-ui/xuiwpph -b 127.0.0.1:$port -$sw46 --endpoint 162.159.192.1:2408 >/dev/null 2>&1" > /usr/local/x-ui/xuiwpph.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiwpphid.log/d' /root/.xui_crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "nohup setsid $(cat /usr/local/x-ui/xuiwpph.log 2>/dev/null) & pid=\$! && echo \$pid > /usr/local/x-ui/xuiwpphid.log"' >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "WARP-plus-Socks5鐨処P鑾峰彇鎴愬姛锛屽彲杩涜Socks5浠ｇ悊鍒嗘祦"
fi
elif [ "$menu" = "2" ]; then
ins
echo '
濂ュ湴鍒╋紙AT锛?婢冲ぇ鍒╀簹锛圓U锛?姣斿埄鏃讹紙BE锛?淇濆姞鍒╀簹锛圔G锛?鍔犳嬁澶э紙CA锛?鐟炲＋锛圕H锛?鎹峰厠 (CZ)
寰峰浗锛圖E锛?涓归害锛圖K锛?鐖辨矙灏间簹锛圗E锛?瑗跨彮鐗欙紙ES锛?鑺叞锛團I锛?娉曞浗锛團R锛?鑻卞浗锛圙B锛?鍏嬬綏鍦颁簹锛圚R锛?鍖堢墮鍒?(HU)
鐖卞皵鍏帮紙IE锛?鍗板害锛圛N锛?鎰忓ぇ鍒?(IT)
鏃ユ湰锛圝P锛?绔嬮櫠瀹涳紙LT锛?鎷夎劚缁翠簹锛圠V锛?鑽峰叞锛圢L锛?鎸▉ (NO)
娉㈠叞锛圥L锛?钁¤悇鐗欙紙PT锛?缃楅┈灏间簹 (RO)
濉炲皵缁翠簹锛圧S锛?鐟炲吀锛圫E锛?鏂板姞鍧?(SG)
鏂礇浼愬厠锛圫K锛?缇庡浗锛圲S锛?'
readp "鍙€夋嫨鍥藉鍦板尯锛堣緭鍏ユ湯灏句袱涓ぇ鍐欏瓧姣嶏紝濡傜編鍥斤紝鍒欒緭鍏S锛夛細" guojia
nohup setsid /usr/local/x-ui/xuiwpph -b 127.0.0.1:$port --cfon --country $guojia -$sw46 --endpoint 162.159.192.1:2408 >/dev/null 2>&1 & echo "$!" > /usr/local/x-ui/xuiwpphid.log
green "鐢宠IP涓€︹€﹁绋嶇瓑鈥︹€? && sleep 20
resv1=$(curl -s --socks5 localhost:$port icanhazip.com)
resv2=$(curl -sx socks5h://localhost:$port icanhazip.com)
if [[ -z $resv1 && -z $resv2 ]]; then
red "WARP-plus-Socks5鐨処P鑾峰彇澶辫触锛屽皾璇曟崲涓浗瀹跺湴鍖哄惂" && unins && exit
else
echo "/usr/local/x-ui/xuiwpph -b 127.0.0.1:$port --cfon --country $guojia -$sw46 --endpoint 162.159.192.1:2408 >/dev/null 2>&1" > /usr/local/x-ui/xuiwpph.log
crontab -l 2>/dev/null > /root/.xui_crontab.tmp
sed -i '/xuiwpphid.log/d' /root/.xui_crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "nohup setsid $(cat /usr/local/x-ui/xuiwpph.log 2>/dev/null) & pid=\$! && echo \$pid > /usr/local/x-ui/xuiwpphid.log"' >> /root/.xui_crontab.tmp
crontab /root/.xui_crontab.tmp >/dev/null 2>&1
rm /root/.xui_crontab.tmp
green "WARP-plus-Socks5鐨処P鑾峰彇鎴愬姛锛屽彲杩涜Socks5浠ｇ悊鍒嗘祦"
fi
elif [ "$menu" = "3" ]; then
unins && green "宸插仠姝ARP-plus-Socks5浠ｇ悊鍔熻兘"
else
show_menu
fi
}


show_menu(){
clear
white "x-ui-yg鑴氭湰蹇嵎鏂瑰紡锛歺-ui"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
green " 1. 涓€閿畨瑁?x-ui"
green " 2. 鍒犻櫎鍗歌浇 x-ui"
echo "----------------------------------------------------------------------------------"
green " 3. 鍏朵粬璁剧疆 銆怉rgo鍙岄毀閬撱€佽闃呬紭閫塈P銆丟itlab璁㈤槄閾炬帴銆佽幏鍙杦arp-wireguard璐﹀彿閰嶇疆銆?
green " 4. 鍙樻洿 x-ui 闈㈡澘璁剧疆 銆愮敤鎴峰悕瀵嗙爜銆佺櫥褰曠鍙ｃ€佹牴璺緞銆佽繕鍘熼潰鏉裤€?
green " 5. 鍏抽棴銆侀噸鍚?x-ui"
green " 6. 鏇存柊 x-ui 鑴氭湰"
echo "----------------------------------------------------------------------------------"
green " 7. 鏇存柊骞舵煡鐪嬭仛鍚堥€氱敤鑺傜偣銆乧lash-meta涓巗ing-box瀹㈡埛绔厤缃強璁㈤槄閾炬帴"
green " 8. 鏌ョ湅 x-ui 杩愯鏃ュ織"
green " 9. 涓€閿師鐗圔BR+FQ鍔犻€?
green "10. 绠＄悊 Acme 鐢宠鍩熷悕璇佷功"
green "11. 绠＄悊 Warp 鏌ョ湅鏈湴Netflix銆丆hatGPT瑙ｉ攣鎯呭喌"
green "12. 娣诲姞WARP-plus-Socks5浠ｇ悊妯″紡 銆愭湰鍦癢arp/澶氬湴鍖篜siphon-VPN銆?
green "13. 鍒锋柊IP閰嶇疆鍙婂弬鏁版樉绀?
echo "----------------------------------------------------------------------------------"
green " 0. 閫€鍑鸿剼鏈?
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
insV=$(cat /usr/local/x-ui/v 2>/dev/null)
#latestV=$(curl -s https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1)
latestV=$(curl -sL https://raw.githubusercontent.com/a820820/x-ui/main/version | awk -F "鏇存柊鍐呭" '{print $1}' | head -n 1)
if [[ -f /usr/local/x-ui/v ]]; then
if [ "$insV" = "$latestV" ]; then
echo -e "褰撳墠 x-ui-yg 鑴氭湰鏈€鏂扮増锛?{bblue}${insV}${plain} (宸插畨瑁?"
else
echo -e "褰撳墠 x-ui-yg 鑴氭湰鐗堟湰鍙凤細${bblue}${insV}${plain}"
echo -e "妫€娴嬪埌鏈€鏂?x-ui-yg 鑴氭湰鐗堟湰鍙凤細${yellow}${latestV}${plain} (鍙€夋嫨6杩涜鏇存柊)"
echo -e "${yellow}$(curl -sL https://raw.githubusercontent.com/a820820/x-ui/main/version)${plain}"
#echo -e "${yellow}$(curl -sL https://gitlab.com/rwkgyg/x-ui-yg/-/raw/main/version/version)${plain}"
fi
else
echo -e "褰撳墠 x-ui-yg 鑴氭湰鐗堟湰鍙凤細${bblue}${latestV}${plain}"
echo -e "璇峰厛閫夋嫨 1 锛屽畨瑁?x-ui-yg 鑴氭湰"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo -e "VPS鐘舵€佸涓嬶細"
echo -e "绯荤粺:$blue$op$plain  \c";echo -e "鍐呮牳:$blue$version$plain  \c";echo -e "澶勭悊鍣?$blue$cpu$plain  \c";echo -e "铏氭嫙鍖?$blue$vi$plain  \c";echo -e "BBR绠楁硶:$blue$bbr$plain"
v4v6
if [[ "$v6" == "2a09"* ]]; then
w6="銆怶ARP銆?
fi
if [[ "$v4" == "104.28"* ]]; then
w4="銆怶ARP銆?
fi
if [[ -z $v4 ]]; then
vps_ipv4='鏃營PV4'      
vps_ipv6="$v6"
location="$v6dq"
elif [[ -n $v4 && -n $v6 ]]; then
vps_ipv4="$v4"    
vps_ipv6="$v6"
location="$v4dq"
else
vps_ipv4="$v4"    
vps_ipv6='鏃營PV6'
location="$v4dq"
fi
echo -e "鏈湴IPV4鍦板潃锛?blue$vps_ipv4$w4$plain   鏈湴IPV6鍦板潃锛?blue$vps_ipv6$w6$plain"
echo -e "鏈嶅姟鍣ㄥ湴鍖猴細$blue$location$plain"
echo "------------------------------------------------------------------------------------"
if [[ -n $(ps -e | grep xuiwpph) ]]; then
s5port=$(cat /usr/local/x-ui/xuiwpph.log 2>/dev/null | awk '{print $3}'| awk -F":" '{print $NF}')
s5gj=$(cat /usr/local/x-ui/xuiwpph.log 2>/dev/null | awk '{print $6}')
case "$s5gj" in
AT) showgj="濂ュ湴鍒? ;;
AU) showgj="婢冲ぇ鍒╀簹" ;;
BE) showgj="姣斿埄鏃? ;;
BG) showgj="淇濆姞鍒╀簹" ;;
CA) showgj="鍔犳嬁澶? ;;
CH) showgj="鐟炲＋" ;;
CZ) showgj="鎹峰厠" ;;
DE) showgj="寰峰浗" ;;
DK) showgj="涓归害" ;;
EE) showgj="鐖辨矙灏间簹" ;;
ES) showgj="瑗跨彮鐗? ;;
FI) showgj="鑺叞" ;;
FR) showgj="娉曞浗" ;;
GB) showgj="鑻卞浗" ;;
HR) showgj="鍏嬬綏鍦颁簹" ;;
HU) showgj="鍖堢墮鍒? ;;
IE) showgj="鐖卞皵鍏? ;;
IN) showgj="鍗板害" ;;
IT) showgj="鎰忓ぇ鍒? ;;
JP) showgj="鏃ユ湰" ;;
LT) showgj="绔嬮櫠瀹? ;;
LV) showgj="鎷夎劚缁翠簹" ;;
NL) showgj="鑽峰叞" ;;
NO) showgj="鎸▉" ;;
PL) showgj="娉㈠叞" ;;
PT) showgj="钁¤悇鐗? ;;
RO) showgj="缃楅┈灏间簹" ;;
RS) showgj="濉炲皵缁翠簹" ;;
SE) showgj="鐟炲吀" ;;
SG) showgj="鏂板姞鍧? ;;
SK) showgj="鏂礇浼愬厠" ;;
US) showgj="缇庡浗" ;;
esac
grep -q "country" /usr/local/x-ui/xuiwpph.log 2>/dev/null && s5ms="澶氬湴鍖篜siphon浠ｇ悊妯″紡 (绔彛:$s5port  鍥藉:$showgj)" || s5ms="鏈湴Warp浠ｇ悊妯″紡 (绔彛:$s5port)"
echo -e "WARP-plus-Socks5鐘舵€侊細$blue宸插惎鍔?$s5ms$plain"
else
echo -e "WARP-plus-Socks5鐘舵€侊細$blue鏈惎鍔?plain"
fi
echo "------------------------------------------------------------------------------------"
argopid
if [[ -n $(ps -e | grep -w $ym 2>/dev/null) || -n $(ps -e | grep -w $ls 2>/dev/null) ]]; then
if [[ -f /usr/local/x-ui/xuiargoport.log ]]; then
argoprotocol=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .protocol' /usr/local/x-ui/bin/config.json)
echo -e "Argo涓存椂闅ч亾鐘舵€侊細$blue宸插惎鍔?銆愮洃鍚?yellow${argoprotocol}-ws$plain$blue鑺傜偣鐨勭鍙?$plain$yellow$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)$plain$blue銆?plain$plain"
argotro=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].password' /usr/local/x-ui/bin/config.json)
argoss=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.password' /usr/local/x-ui/bin/config.json)
argouuid=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].id' /usr/local/x-ui/bin/config.json)
argopath=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.wsSettings.path' /usr/local/x-ui/bin/config.json)
if [[ ! $argouuid = "null" ]]; then
argoma=$argouuid
elif [[ ! $argoss = "null" ]]; then
argoma=$argoss
else
argoma=$argotro
fi
argotls=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.security' /usr/local/x-ui/bin/config.json)
if [[ -n $argouuid ]]; then
if [[ "$argotls" = "tls" ]]; then
echo -e "閿欒鍙嶉锛?red闈㈡澘鍒涘缓鐨剋s鑺傜偣寮€鍚簡tls锛屼笉鏀寔Argo锛岃鍦ㄩ潰鏉垮搴旂殑鑺傜偣涓叧闂璽ls$plain"
else
echo -e "Argo瀵嗙爜/UUID锛?blue$argoma$plain"
echo -e "Argo璺緞path锛?blue$argopath$plain"
argolsym=$(cat /usr/local/x-ui/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
[[ $(echo "$argolsym" | grep -w "api.trycloudflare.com/tunnel") ]] && argolsyms='鐢熸垚澶辫触锛岃閲嶇疆' || argolsyms=$argolsym
echo -e "Argo涓存椂鍩熷悕锛?blue$argolsyms$plain"
fi
else
echo -e "閿欒鍙嶉锛?red闈㈡澘灏氭湭鍒涘缓涓€涓鍙ｄ负$yellow$(cat /usr/local/x-ui/xuiargoport.log 2>/dev/null)$plain$red鐨剋s鑺傜偣锛屾帹鑽恦mess-ws$plain$plain"
fi
fi
if [[ -f /usr/local/x-ui/xuiargoymport.log && -f /usr/local/x-ui/xuiargoport.log ]]; then
echo "--------------------------"
fi
if [[ -f /usr/local/x-ui/xuiargoymport.log ]]; then
argoprotocol=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .protocol' /usr/local/x-ui/bin/config.json)
echo -e "Argo鍥哄畾闅ч亾鐘舵€侊細$blue宸插惎鍔?銆愮洃鍚?yellow${argoprotocol}-ws$plain$blue鑺傜偣鐨勭鍙?$plain$yellow$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)$plain$blue銆?plain$plain"
argotro=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].password' /usr/local/x-ui/bin/config.json)
argoss=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.password' /usr/local/x-ui/bin/config.json)
argouuid=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .settings.clients[0].id' /usr/local/x-ui/bin/config.json)
argopath=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.wsSettings.path' /usr/local/x-ui/bin/config.json)
if [[ ! $argouuid = "null" ]]; then
argoma=$argouuid
elif [[ ! $argoss = "null" ]]; then
argoma=$argoss
else
argoma=$argotro
fi
argotls=$(jq -r --arg port "$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)" '.inbounds[] | select(.port == ($port | tonumber)) | .streamSettings.security' /usr/local/x-ui/bin/config.json)
if [[ -n $argouuid ]]; then
if [[ "$argotls" = "tls" ]]; then
echo -e "閿欒鍙嶉锛?red闈㈡澘鍒涘缓鐨剋s鑺傜偣寮€鍚簡tls锛屼笉鏀寔Argo锛岃鍦ㄩ潰鏉垮搴旂殑鑺傜偣涓叧闂璽ls$plain"
else
echo -e "Argo瀵嗙爜/UUID锛?blue$argoma$plain"
echo -e "Argo璺緞path锛?blue$argopath$plain"
echo -e "Argo鍥哄畾鍩熷悕锛?blue$(cat /usr/local/x-ui/xuiargoym.log 2>/dev/null)$plain"
fi
else
echo -e "閿欒鍙嶉锛?red闈㈡澘灏氭湭鍒涘缓涓€涓鍙ｄ负$yellow$(cat /usr/local/x-ui/xuiargoymport.log 2>/dev/null)$plain$red鐨剋s鑺傜偣锛屾帹鑽恦mess-ws$plain$plain"
fi
fi
else
echo -e "Argo鐘舵€侊細$blue鏈惎鍔?plain"
fi
echo "------------------------------------------------------------------------------------"
show_status
echo "------------------------------------------------------------------------------------"
acp=$(/usr/local/x-ui/x-ui setting -show 2>/dev/null)
if [[ -n $acp ]]; then
if [[ $acp == *admin*  ]]; then
red "x-ui鍑洪敊锛岃閫夋嫨4閲嶇疆鐢ㄦ埛鍚嶅瘑鐮佹垨鑰呭嵏杞介噸瑁厁-ui"
else
xpath=$(echo $acp | awk '{print $8}')
xport=$(echo $acp | awk '{print $6}')
xip1=$(cat /usr/local/x-ui/xip 2>/dev/null | sed -n 1p)
xip2=$(cat /usr/local/x-ui/xip 2>/dev/null | sed -n 2p)
if [ "$xpath" == "/" ]; then
pathk="$sred銆愪弗閲嶅畨鍏ㄦ彁绀? 璇疯繘鍏ラ潰鏉胯缃紝娣诲姞url鏍硅矾寰勩€?plain"
fi
echo -e "x-ui鐧诲綍淇℃伅濡備笅锛?
echo -e "$blue$acp$pathk$plain" 
if [[ -n $xip2 ]]; then
xuimb="http://${xip1}:${xport}${xpath} 鎴栬€?http://${xip2}:${xport}${xpath}"
else
xuimb="http://${xip1}:${xport}${xpath}"
fi
echo -e "$blue鐧诲綍鍦板潃(瑁窱P娉勯湶妯″紡-闈炲畨鍏?锛?xuimb$plain"
if [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key && -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]]; then
ym=`bash ~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}'`
echo $ym > /root/ygkkkca/ca.log
fi
if [[ -f /root/ygkkkca/ca.log ]]; then
echo -e "$blue鐧诲綍鍦板潃(鍩熷悕鍔犲瘑妯″紡-瀹夊叏)锛歨ttps://$(cat /root/ygkkkca/ca.log 2>/dev/null):${xport}${xpath}$plain"
else
echo -e "$sred寮虹儓寤鸿鐢宠鍩熷悕璇佷功骞跺紑鍚煙鍚?https)鐧诲綍鏂瑰紡锛屼互纭繚闈㈡澘鏁版嵁瀹夊叏$plain"
fi
fi
else
echo -e "x-ui鐧诲綍淇℃伅濡備笅锛?
echo -e "$red鏈畨瑁厁-ui锛屾棤鏄剧ず$plain"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo
readp "璇疯緭鍏ユ暟瀛椼€?-13銆?" Input
case "$Input" in     
 1 ) check_uninstall && xuiinstall;;
 2 ) check_install && uninstall;;
 3 ) check_install && changeserv;;
 4 ) check_install && xuichange;;
 5 ) check_install && xuirestop;;
 6 ) check_install && update;;
 7 ) check_install && sharesub;;
 8 ) check_install && show_log;;
 9 ) bbr;;
 10  ) acme;;
 11 ) cfwarp;;
 12 ) check_install && insxuiwpph;;
 13 ) check_install && showxuiip && show_menu;;
 * ) exit 
esac
}
show_menu
