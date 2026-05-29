#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# 检查是否为root用户
[[ $EUID -ne 0 ]] && echo -e "${red}致命错误：${plain}请使用root权限运行此脚本\n " && exit 1

# 检查操作系统并设置发行版变量
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "检查系统操作系统失败，请联系作者！" >&2
    exit 1
fi
echo "操作系统发行版：$release"

arch3xui() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    armv8 | arm64 | aarch64) echo 'arm64' ;;
    *) echo -e "${green}不支持的CPU架构！${plain}" && rm -f install.sh && exit 1 ;;
    esac
}
echo "架构：$(arch3xui)"

os_version=""
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用CentOS 8或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red}请使用Ubuntu 20或更高版本！${plain}" && exit 1
    fi

elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red}请使用Fedora 36或更高版本！${plain}" && exit 1
    fi

elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 10 ]]; then
        echo -e "${red} 请使用Debian 10或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "arch" ]]; then
    echo "操作系统为ArchLinux"

else
    echo -e "${red}检查操作系统版本失败，请联系作者！${plain}" && exit 1
fi

install_base() {
    case "${release}" in
        centos|fedora)
            yum install -y -q wget curl tar
            ;;
        arch)
            pacman -Syu --noconfirm wget curl tar
            ;;
        *)
            apt install -y -q wget curl tar
            ;;
    esac
}

# 安装完成后配置面板（出于安全考虑）
config_after_install() {
    echo -e "${yellow}安装/更新完成！出于安全考虑，建议修改面板设置${plain}"
    read -p "是否继续修改设置 [y/n]？: " config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        read -p "请设置您的用户名：" config_account
        echo -e "${yellow}您的用户名将是：${config_account}${plain}"
        read -p "请设置您的密码：" config_password
        echo -e "${yellow}您的密码将是：${config_password}${plain}"
        read -p "请设置面板端口：" config_port
        echo -e "${yellow}您的面板端口是：${config_port}${plain}"
        echo -e "${yellow}正在初始化，请稍候...${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}用户名和密码设置成功！${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}面板端口设置成功！${plain}"
    else
        echo -e "${red}取消...${plain}"
        if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
            local usernameTemp=$(head -c 6 /dev/urandom | base64)
            local passwordTemp=$(head -c 6 /dev/urandom | base64)
            /usr/local/x-ui/x-ui setting -username ${usernameTemp} -password ${passwordTemp}
            echo -e "这是全新安装，出于安全考虑将生成随机登录信息："
            echo -e "###############################################"
            echo -e "${green}用户名：${usernameTemp}${plain}"
            echo -e "${green}密码：${passwordTemp}${plain}"
            echo -e "###############################################"
            echo -e "${red}如果您忘记了登录信息，可以在安装后输入x-ui命令然后选择7查看${plain}"
        else
            echo -e "${red} 这是升级操作，将保留旧设置，如果您忘记了登录信息，可以输入x-ui命令然后选择7查看${plain}"
        fi
    fi
    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}获取3X-UI版本失败，可能是Github API限制，请稍后再试${plain}"
            exit 1
        fi
        echo -e "已获取3X-UI最新版本：${last_version}，开始安装..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch3xui).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch3xui).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载3X-UI失败，请确保您的服务器能够访问Github ${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/MHSanaei/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch3xui).tar.gz"
        echo -e "开始安装3X-UI $1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch3xui).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载3X-UI $1失败，请检查该版本是否存在${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        echo -e "${yellow}检测到旧版本，正在强制清理...${plain}"
        systemctl stop x-ui 2>/dev/null || true
        systemctl disable x-ui 2>/dev/null || true
        rm -rf /usr/local/x-ui/
        rm -f /etc/systemd/system/x-ui.service
        systemctl daemon-reload 2>/dev/null || true
    fi

    tar zxvf x-ui-linux-$(arch3xui).tar.gz
    rm x-ui-linux-$(arch3xui).tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-$(arch3xui)
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}3X-UI ${last_version}${plain}安装完成，现在正在运行..."
    echo -e ""
    echo -e "3X-UI管理菜单用法："
    echo -e "----------------------------------------------"
    echo -e "x-ui              - 进入管理菜单"
    echo -e "x-ui start        - 启动3X-UI"
    echo -e "x-ui stop         - 停止3X-UI"
    echo -e "x-ui restart      - 重启3X-UI"
    echo -e "x-ui status       - 查看3X-UI状态"
    echo -e "x-ui enable       - 开机自启3X-UI"
    echo -e "x-ui disable      - 关闭开机自启3X-UI"
    echo -e "x-ui log          - 查看3X-UI日志"
    echo -e "x-ui banlog       - 查看Fail2ban封禁日志"
    echo -e "x-ui update       - 更新3X-UI"
    echo -e "x-ui install      - 安装3X-UI"
    echo -e "x-ui uninstall    - 卸载3X-UI"
    echo -e "----------------------------------------------"
}

echo -e "${green}正在运行...${plain}"
install_base
install_x-ui $1
