#!/bin/zsh

# 配置用户名（修改这里来抓取不同用户）
channel="@lexfridman"
name="${channel#@}"
outfile="${name}_test.txt"

echo "🚀 开始抓取 $channel 的推文..."
echo "📥 输出文件：$outfile"

# 创建代理配置
cat > /tmp/proxychains.conf << EOF
strict_chain
proxy_dns
[ProxyList]
http 127.0.0.1 33210
EOF

echo "🔍 获取用户ID..."
user_id=$(proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "$name" 2>/dev/null | jq -r '.id')

if [ -z "$user_id" ] || [ "$user_id" = "null" ]; then
    echo "❌ 错误：无法获取用户 $name 的ID"
    rm -f /tmp/proxychains.conf
    exit 1
fi

echo "✅ 用户ID: $user_id"
echo "📡 开始抓取推文（限制1000条）..."

# 抓取推文并格式化
proxychains4 -f /tmp/proxychains.conf twscrape user_tweets "$user_id" --limit 1000 2>/dev/null | \
jq -r '.date + "\t" + (.rawContent | gsub("\n"; " ") | gsub("\r"; " "))' | \
while IFS=$'\t' read -r date content; do
    formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${date:0:19}" "+%Y-%m-%d" 2>/dev/null || echo "${date:0:10}")
    echo "$formatted_date\t$content"
done > "$outfile"

# 清理临时文件
rm -f /tmp/proxychains.conf

# 检查结果
if [ ! -f "$outfile" ]; then
    echo "❌ 错误：未能创建输出文件"
    exit 1
fi

lines=$(wc -l < "$outfile")
echo "✅ 抓取完成：共 $lines 条推文 → $outfile"

# 显示前5条推文作为预览
echo ""
echo "📝 推文预览（前5条）:"
head -5 "$outfile"

echo ""
echo "📂 开始年份分类..."

# 按年份分类
for year in 2025 2024 2023 2022 2021 2020 2019 2018 2017 2016 2015; do
    year_file="${name}_${year}.txt"
    grep "^$year" "$outfile" > "$year_file" 2>/dev/null
    count=$(wc -l < "$year_file" 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        echo "✅ $year年: $count 条推文 → $year_file"
    else
        rm -f "$year_file"
    fi
done

echo ""
echo "🎉 全部完成！"
echo "📊 文件列表："
ls -la ${name}_*.txt

echo ""
echo "💡 使用说明："
echo "   - 修改脚本开头的 channel=\"@用户名\" 来抓取不同用户"
echo "   - 所有文件都保存在当前目录"
echo "   - 主文件：${name}_test.txt"
echo "   - 年份文件：${name}_年份.txt" 