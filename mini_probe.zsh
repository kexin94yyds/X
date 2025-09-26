#!/bin/zsh

# 一键最小验证脚本：自动探测可用代理 → 获取 user_id → 拉取 3 条推文
# 用法：
#   ./mini_probe.zsh @naval
#   或：zsh mini_probe.zsh @AlexHormozi

set -e

handle="${1:-@naval}"
name="${handle#@}"
outfile="${name}_mini_test.txt"

echo "=== 最小验证：$handle ==="

# 依赖检查
missing=()
command -v twscrape >/dev/null 2>&1 || missing+=(twscrape)
command -v proxychains4 >/dev/null 2>&1 || missing+=(proxychains4)
command -v jq >/dev/null 2>&1 || missing+=(jq)
if [ ${#missing[@]} -gt 0 ]; then
  echo "❌ 缺少依赖：${(j:, :)missing}"
  exit 1
fi

candidates=(
  "http 127.0.0.1 33210"
  "socks5 127.0.0.1 33211"
  "http 127.0.0.1 7897"
)

uid=""
proxy_used=""

for cand in "${candidates[@]}"; do
  proto=$(echo "$cand" | awk '{print $1}')
  host=$(echo "$cand" | awk '{print $2}')
  port=$(echo "$cand" | awk '{print $3}')
  echo "🔎 尝试代理: $proto $host:$port"
  cat > /tmp/proxychains.conf << EOF
strict_chain
proxy_dns
[ProxyList]
$proto $host $port
EOF
  uid=$(proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "$name" 2>/dev/null | jq -r '.id' 2>/dev/null || true)
  if [ -n "$uid" ] && [ "$uid" != "null" ]; then
    proxy_used="$proto $host:$port"
    echo "✅ 获取到 user_id: $uid （$proxy_used）"
    break
  fi
done

if [ -z "$uid" ] || [ "$uid" = "null" ]; then
  echo "❌ 无法获取 user_id。请："
  echo "   1) 检查代理端口是否可用（HTTP:33210 或 SOCKS5:33211/HTTP:7897）"
  echo "   2) 修复 twscrape 账户（twscrape relogin myacc6 或重新导入 cookies）"
  echo "   3) 参考《Twitter爬虫完整故障排除手册.md》👉 账户与代理章节"
  rm -f /tmp/proxychains.conf
  exit 1
fi

echo "📡 拉取 3 条推文用于快速验证..."
proxychains4 -f /tmp/proxychains.conf twscrape user_tweets "$uid" --limit 3 2>/dev/null | \
jq -r '.date + "\t" + (.rawContent | gsub("\n"; " ") | gsub("\r"; " "))' | \
while IFS=$'\t' read -r date content; do
  formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${date:0:19}" "+%Y-%m-%d" 2>/dev/null || echo "${date:0:10}")
  echo "$formatted_date\t$content"
done | tee "$outfile"

lines=$(wc -l < "$outfile")
echo "\n✅ 最小验证完成：$lines 条 → $outfile（代理：$proxy_used）"

rm -f /tmp/proxychains.conf || true

