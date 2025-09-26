#!/bin/zsh

echo "=== 美国代理配置脚本 ==="
echo ""

# 检查当前IP
echo "当前IP地址:"
curl -s ifconfig.me
echo ""
echo ""

# 设置美国代理环境变量
echo "请选择你的美国代理方案:"
echo "1. 手动输入代理地址"
echo "2. 使用常见VPN代理端口"
echo "3. 测试代理连接"
echo ""

read -p "请选择 (1-3): " choice

case $choice in
    1)
        echo ""
        read -p "请输入美国代理IP地址: " proxy_ip
        read -p "请输入代理端口: " proxy_port
        export HTTP_PROXY=http://$proxy_ip:$proxy_port
        export HTTPS_PROXY=http://$proxy_ip:$proxy_port
        echo "代理已设置: $HTTP_PROXY"
        ;;
    2)
        echo ""
        echo "常见VPN代理端口:"
        echo "HTTP代理: 8080, 3128, 8888"
        echo "SOCKS5代理: 1080, 1081"
        echo ""
        read -p "请输入代理IP: " proxy_ip
        read -p "请输入端口: " proxy_port
        export HTTP_PROXY=http://$proxy_ip:$proxy_port
        export HTTPS_PROXY=http://$proxy_ip:$proxy_port
        echo "代理已设置: $HTTP_PROXY"
        ;;
    3)
        if [[ -n "$HTTP_PROXY" ]]; then
            echo "当前代理: $HTTP_PROXY"
            echo "测试代理连接..."
            curl -s --proxy $HTTP_PROXY ifconfig.me
            echo ""
        else
            echo "未设置代理"
        fi
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "测试Twitter爬虫:"
echo "1. 检查账户状态"
twscrape accounts

echo ""
echo "2. 尝试重新登录"
twscrape relogin myacc6

echo ""
echo "3. 测试搜索功能"
twscrape search "test" --limit 1

echo ""
echo "=== 配置完成 ===" 