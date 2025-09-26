#!/bin/zsh

echo "=== Twitter爬虫美国代理测试脚本 ==="
echo ""

# 检查当前IP
echo "1. 检查当前IP地址:"
curl -s ifconfig.me
echo ""
echo ""

# 设置美国代理（需要你填入实际的代理地址）
echo "2. 设置美国代理环境变量:"
echo "请将下面的代理地址替换为你的实际美国代理:"
echo "export HTTP_PROXY=http://美国代理IP:端口"
echo "export HTTPS_PROXY=http://美国代理IP:端口"
echo ""

# 示例代理配置（需要替换为实际代理）
# export HTTP_PROXY=http://proxy.example.com:8080
# export HTTPS_PROXY=http://proxy.example.com:8080

echo "3. 测试代理连接:"
if [[ -n "$HTTP_PROXY" ]]; then
    echo "使用代理: $HTTP_PROXY"
    curl -s --proxy $HTTP_PROXY ifconfig.me
    echo ""
else
    echo "未设置代理，将使用直连"
fi

echo ""
echo "4. 测试twscrape工具:"
echo "检查账户状态:"
twscrape accounts

echo ""
echo "5. 尝试重新登录:"
twscrape relogin myacc6

echo ""
echo "6. 测试搜索功能:"
twscrape search "test" --limit 1

echo ""
echo "=== 测试完成 ===" 