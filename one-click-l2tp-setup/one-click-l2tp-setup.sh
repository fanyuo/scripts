#!/bin/bash

# L2TP VPN服务器交互式配置脚本
# 功能：安装和配置L2TP VPN服务器，监听所有IP地址

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 恢复默认颜色

# 显示脚本标题
echo -e "${GREEN}"
echo "========================================"
echo " L2TP VPN服务器自动配置脚本 (监听任意IP)"
echo "========================================"
echo -e "${NC}"

# 1. 确认配置信息
echo -e "${YELLOW}"
echo "脚本将使用以下配置进行安装："
echo "----------------------------------------"
echo "监听IP地址: 0.0.0.0 (本机所有IP)"
echo "客户端IP范围: 10.0.0.100-10.0.0.200"
echo "服务器本地IP: 10.0.0.1"
echo "DNS服务器: 8.8.8.8"
echo "----------------------------------------"
echo -e "${NC}"

read -p "是否继续安装？[y/n]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${RED}安装已取消${NC}"
    exit 1
fi

# 2. 开始安装过程
echo -e "${GREEN}正在开始安装过程...${NC}"

# 3. 更新系统
echo -e "${YELLOW}[1/8] 正在更新系统软件包...${NC}"
sudo apt update && sudo apt upgrade -y

# 4. 安装必要软件
echo -e "${YELLOW}[2/8] 安装必要的软件包(xl2tpd/ppp/iptables)...${NC}"
sudo apt install xl2tpd ppp iptables-persistent -y

# 5. 配置xl2tpd
echo -e "${YELLOW}[3/8] 配置xl2tpd主配置文件...${NC}"
sudo tee /etc/xl2tpd/xl2tpd.conf > /dev/null <<EOL
[global]
ipsec saref = no
listen-addr = 0.0.0.0

[lns default]
ip range = 10.0.0.100-10.0.0.200
local ip = 10.0.0.1
require authentication = yes
name = l2tp-server
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOL

# 6. 配置PPP选项
echo -e "${YELLOW}[4/8] 配置PPP选项文件...${NC}"
sudo tee /etc/ppp/options.xl2tpd > /dev/null <<EOL
require-pap
refuse-chap
refuse-mschap
ms-dns 8.8.8.8
asyncmap 0
# lock
debug
logfile /var/log/ppp.log
noccp
noauth
mtu 1410
mru 1410
EOL

# 7. 设置文件权限
echo -e "${YELLOW}[5/8] 设置chap-secrets文件权限...${NC}"
sudo chmod 644 /etc/ppp/chap-secrets
sudo chown root:root /etc/ppp/chap-secrets

# 8. 启用IP转发
echo -e "${YELLOW}[6/8] 启用IP转发功能...${NC}"
sudo sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
sudo tee -a /etc/sysctl.conf > /dev/null <<EOL
net.ipv4.ip_forward=1
EOL
sudo sysctl -p

# 9. 配置防火墙
echo -e "${YELLOW}[7/8] 配置防火墙规则...${NC}"
sudo iptables -A INPUT -p udp --dport 1701 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
sudo iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT
sudo netfilter-persistent save

# 10. 启动服务
echo -e "${YELLOW}[8/8] 启动服务并设置开机启动...${NC}"
sudo systemctl daemon-reload
sudo systemctl restart xl2tpd
sudo systemctl enable xl2tpd

# 11. 安装完成提示
echo -e "${GREEN}"
echo "========================================"
echo " L2TP VPN服务器安装完成！"
echo "========================================"
echo -e "${NC}"
echo -e "服务器配置信息："
echo -e "监听地址: ${YELLOW}0.0.0.0 (本机所有IP)${NC}"
echo -e "客户端IP范围: ${YELLOW}10.0.0.100-10.0.0.200${NC}"
echo -e "本地服务器IP: ${YELLOW}10.0.0.1${NC}"
echo -e "DNS服务器: ${YELLOW}8.8.8.8${NC}"
echo ""
echo -e "${RED}重要提示：${NC}"
echo -e "1. 请手动编辑 ${YELLOW}/etc/ppp/chap-secrets${NC} 添加VPN用户"
echo -e "   格式: ${YELLOW}用户名 * 密码 *${NC}"
echo -e "2. 如果服务器有外部防火墙，请确保开放UDP 1701端口"
echo -e "3. 客户端连接地址应为服务器的 ${YELLOW}公网或局域网IP地址${NC}"