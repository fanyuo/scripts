#!/bin/bash

DEFAULT_SUBNET="192.168.31"

read -p "请输入三级网段 (默认: $DEFAULT_SUBNET): " SUBNET
SUBNET=${SUBNET:-$DEFAULT_SUBNET}

echo ""
echo "===== 开始高速扫描 ====="
echo "扫描网段：$SUBNET.1 ~ $SUBNET.255"
echo ""

LIVE_IPS=()

# 判断 ping 参数
PING_CMD="ping"
PING_COUNT_PARAM="-c"
PING_TIMEOUT_PARAM="-W"

if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
    # Linux / WSL / macOS 默认可用
    if ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1; then
        PING_TIMEOUT_PARAM="-W"
    else
        # macOS 用 -t
        PING_TIMEOUT_PARAM="-t"
    fi
elif ping 127.0.0.1 -n 1 >/dev/null 2>&1; then
    # Windows bash / Git Bash
    PING_CMD="ping"
    PING_COUNT_PARAM="-n"
    PING_TIMEOUT_PARAM="-w"
else
    echo "无法检测到 ping 命令参数，请手动调整脚本"
    exit 1
fi

# 并发参数
CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
MAX_JOBS=$((CPU_CORES * 10))
MAX_JOBS=$((MAX_JOBS>256?256:MAX_JOBS))

job_count=0

for i in $(seq 1 255); do
    IP="$SUBNET.$i"

    (
        if $PING_CMD $PING_COUNT_PARAM 1 $PING_TIMEOUT_PARAM 1 "$IP" >/dev/null 2>&1; then
            echo -e "\e[32m$IP 通了\e[0m"
            echo "$IP" >> alive.tmp
        else
            echo -e "\e[31m$IP 不通\e[0m"
        fi
    ) &

    job_count=$((job_count+1))
    if ((job_count>=MAX_JOBS)); then
        wait
        job_count=0
    fi
done

wait

echo ""
echo "===== 扫描完成，通的 IP 列表 ====="

if [ -f alive.tmp ]; then
    sort -t . -k4 -n alive.tmp
    rm -f alive.tmp
else
    echo "没有通的 IP。"
fi

echo ""
read -p "按回车键退出..."
