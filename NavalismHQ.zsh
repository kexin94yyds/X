#!/bin/zsh

channel="@NavalismHQ"
name="${channel#@}"
outfile="${name}_test.txt"

echo "📥 快速测试输出文件：$outfile"

cat > /tmp/proxychains.conf << EOF
strict_chain
proxy_dns
[ProxyList]
http 127.0.0.1 33210
EOF

user_id=$(proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "$name" 2>/dev/null | jq -r '.id')

proxychains4 -f /tmp/proxychains.conf twscrape user_tweets "$user_id" --limit 1000 2>/dev/null | \
jq -r '.date + "\t" + (.rawContent | gsub("\n"; " ") | gsub("\r"; " "))' | \
while IFS=$'\t' read -r date content; do
    formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${date:0:19}" "+%Y-%m-%d" 2>/dev/null || echo "${date:0:10}")
    echo "$formatted_date\t$content"
done > "$outfile"

rm -f /tmp/proxychains.conf

lines=$(wc -l < "$outfile")
echo "✅ 完成：共 $lines 条推文 → $outfile"

echo ""
echo "📝 测试对比 - 修复前后的多行推文:"
echo "修复后的完整内容:"
head -5 "$outfile" 
 
 