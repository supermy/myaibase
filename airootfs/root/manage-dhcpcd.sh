#!/bin/bash

# dhcpcd 自动管理脚本
# 功能：启动、停止、重启、查看状态 dhcpcd 服务，并检查网络接口配置
# 注意：建议使用 root 权限执行

# 颜色定义（用于输出）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 默认网络接口，可根据需要修改（如 eth0, wlan0）
INTERFACE="eth0"

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误：此脚本必须以 root 权限运行。请使用 sudo 或切换至 root 用户。${NC}" >&2
        exit 1
    fi
}

# 检查 dhcpcd 是否安装
check_dhcpcd_installed() {
    if ! command -v dhcpcd &> /dev/null; then
        echo -e "${RED}错误：未找到 dhcpcd。请先安装 dhcpcd 包。${NC}"
        echo -e "在 Arch Linux 上，可以使用：${YELLOW}pacman -S dhcpcd${NC} 安装"
        exit 1
    fi
}

# 启动 dhcpcd
start_dhcpcd() {
    echo -e "${BLUE}正在启动 dhcpcd 服务...${NC}"
    systemctl start dhcpcd.service
    systemctl enable dhcpcd.service &>/dev/null # 尝试设置开机启动，忽略输出
    echo -e "${GREEN}已启动 dhcpcd 服务。${NC}"
}

# 停止 dhcpcd
stop_dhcpcd() {
    echo -e "${BLUE}正在停止 dhcpcd 服务...${NC}"
    systemctl stop dhcpcd.service
    systemctl disable dhcpcd.service &>/dev/null # 尝试禁用开机启动，忽略输出
    echo -e "${YELLOW}已停止 dhcpcd 服务。${NC}"
}

# 重启 dhcpcd
restart_dhcpcd() {
    echo -e "${BLUE}正在重启 dhcpcd 服务...${NC}"
    systemctl restart dhcpcd.service
    echo -e "${GREEN}已重启 dhcpcd 服务。${NC}"
}

# 查看 dhcpcd 状态和接口信息
status_dhcpcd() {
    echo -e "${BLUE}=== dhcpcd 服务状态 ===${NC}"
    systemctl status dhcpcd.service --no-pager -l

    echo -e "\n${BLUE}=== 网络接口 $INTERFACE 信息 ===${NC}"
    # 检查接口是否存在
    if ip link show dev "$INTERFACE" &> /dev/null; then
        ip addr show dev "$INTERFACE"
        echo -e "\n${BLUE}=== 当前租约信息（如果存在） ===${NC}"
        # 尝试查看租约文件，如果存在且可读
        if [ -f /var/lib/dhcpcd/dhcpcd-"$INTERFACE".lease ]; then
            cat /var/lib/dhcpcd/dhcpcd-"$INTERFACE".lease | tail -n 20
        else
            echo -e "${YELLOW}未找到 $INTERFACE 的租约文件。${NC}"
        fi
    else
        echo -e "${RED}错误：网络接口 $INTERFACE 未找到。请检查接口名。${NC}"
        echo -e "可用的接口："
        ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}'
    fi
}

# 显示用法
usage() {
    echo -e "\n${GREEN}用法: $0 [选项]${NC}"
    echo -e "选项:"
    echo -e "  ${YELLOW}start${NC}   启动 dhcpcd 服务"
    echo -e "  ${YELLOW}stop${NC}    停止 dhcpcd 服务"
    echo -e "  ${YELLOW}restart${NC} 重启 dhcpcd 服务"
    echo -e "  ${YELLOW}status${NC}  查看 dhcpcd 状态和网络接口信息"
    echo -e "  ${YELLOW}menu${NC}    显示交互式菜单（默认选项）"
    echo -e ""
    echo -e "注意：默认管理的网络接口为 ${BLUE}$INTERFACE${NC}，如需修改请编辑脚本。"
}

# 交互式菜单
show_menu() {
    echo -e "\n${GREEN}=== dhcpcd 服务管理菜单 ===${NC}"
    echo -e "请选择操作:"
    echo -e "  ${YELLOW}1${NC}) 启动 dhcpcd"
    echo -e "  ${YELLOW}2${NC}) 停止 dhcpcd"
    echo -e "  ${YELLOW}3${NC}) 重启 dhcpcd"
    echo -e "  ${YELLOW}4${NC}) 查看状态"
    echo -e "  ${YELLOW}5${NC}) 退出"
    read -rp "请输入数字 [1-5]: " choice

    case $choice in
        1)
            start_dhcpcd
            ;;
        2)
            stop_dhcpcd
            ;;
        3)
            restart_dhcpcd
            ;;
        4)
            status_dhcpcd
            ;;
        5)
            echo -e "${GREEN}再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入。${NC}"
            show_menu
            ;;
    esac
}

# 主函数
main() {
    check_root
    check_dhcpcd_installed

    # 根据参数执行操作
    case "${1:-menu}" in # 默认参数为 "menu"
        "start")
            start_dhcpcd
            ;;
        "stop")
            stop_dhcpcd
            ;;
        "restart")
            restart_dhcpcd
            ;;
        "status")
            status_dhcpcd
            ;;
        "menu")
            show_menu
            ;;
        "-h" | "--help")
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            usage
            exit 1
            ;;
    esac
}

# 执行主函数，并传递所有参数
main "$@"
