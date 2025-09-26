#!/bin/zsh

# 配置博主信息
channel="@stijnnoorman"
name="${channel#@}"
outfile="${name}_comments.md"

echo "🚀 开始抓取 $channel 的评论和图片..."
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
echo "📡 开始抓取推文和评论（限制500条）..."

# 创建Markdown文件头部
cat > "$outfile" << EOF
# $channel 推文与评论合集

> 抓取时间: $(date '+%Y-%m-%d %H:%M:%S')
> 博主: [$channel](https://x.com/${name})

---

EOF

# 抓取推文数据
echo "📊 正在处理推文数据..."
proxychains4 -f /tmp/proxychains.conf twscrape user_tweets "$user_id" --limit 500 2>/dev/null | \
jq -r '
  {
    id: .id,
    date: .date,
    content: .rawContent,
    replies: .replyCount,
    retweets: .retweetCount,
    likes: .likeCount,
    media: [.media[]? | select(.type == "photo") | .url],
    url: ("https://x.com/" + .user.username + "/status/" + .id)
  }
' | \
while IFS= read -r tweet_json; do
    if [ -n "$tweet_json" ] && [ "$tweet_json" != "null" ]; then
        # 解析推文信息
        tweet_id=$(echo "$tweet_json" | jq -r '.id // empty')
        tweet_date=$(echo "$tweet_json" | jq -r '.date // empty')
        tweet_content=$(echo "$tweet_json" | jq -r '.content // empty')
        tweet_url=$(echo "$tweet_json" | jq -r '.url // empty')
        replies_count=$(echo "$tweet_json" | jq -r '.replies // 0')
        retweets_count=$(echo "$tweet_json" | jq -r '.retweets // 0')
        likes_count=$(echo "$tweet_json" | jq -r '.likes // 0')
        
        if [ -n "$tweet_id" ] && [ "$tweet_id" != "null" ]; then
            # 格式化日期
            formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${tweet_date:0:19}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "${tweet_date:0:16}")
            
            # 写入推文到Markdown
            echo "## 📝 推文 - $formatted_date" >> "$outfile"
            echo "" >> "$outfile"
            echo "$tweet_content" >> "$outfile"
            echo "" >> "$outfile"
            echo "**统计:** 💬 $replies_count | 🔄 $retweets_count | ❤️ $likes_count" >> "$outfile"
            echo "" >> "$outfile"
            echo "**链接:** [$tweet_url]($tweet_url)" >> "$outfile"
            echo "" >> "$outfile"
            
            # 处理图片
            media_urls=$(echo "$tweet_json" | jq -r '.media[]? // empty')
            if [ -n "$media_urls" ]; then
                echo "**图片:**" >> "$outfile"
                echo "$media_urls" | while IFS= read -r img_url; do
                    if [ -n "$img_url" ]; then
                        echo "![图片]($img_url)" >> "$outfile"
                    fi
                done
                echo "" >> "$outfile"
            fi
            
            # 获取该推文的评论（仅博主自己的回复）
            echo "🔍 获取推文 $tweet_id 的评论..."
            proxychains4 -f /tmp/proxychains.conf twscrape tweet_replies "$tweet_id" --limit 50 2>/dev/null | \
            jq -r --arg user_id "$user_id" '
              select(.user.id == $user_id) |
              {
                date: .date,
                content: .rawContent,
                media: [.media[]? | select(.type == "photo") | .url]
              }
            ' | \
            while IFS= read -r reply_json; do
                if [ -n "$reply_json" ] && [ "$reply_json" != "null" ]; then
                    reply_date=$(echo "$reply_json" | jq -r '.date // empty')
                    reply_content=$(echo "$reply_json" | jq -r '.content // empty')
                    
                    if [ -n "$reply_content" ] && [ "$reply_content" != "null" ]; then
                        reply_formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${reply_date:0:19}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "${reply_date:0:16}")
                        
                        echo "### 💬 博主回复 - $reply_formatted_date" >> "$outfile"
                        echo "" >> "$outfile"
                        echo "> $reply_content" >> "$outfile"
                        echo "" >> "$outfile"
                        
                        # 处理回复中的图片
                        reply_media=$(echo "$reply_json" | jq -r '.media[]? // empty')
                        if [ -n "$reply_media" ]; then
                            echo "**回复图片:**" >> "$outfile"
                            echo "$reply_media" | while IFS= read -r reply_img; do
                                if [ -n "$reply_img" ]; then
                                    echo "![回复图片]($reply_img)" >> "$outfile"
                                fi
                            done
                            echo "" >> "$outfile"
                        fi
                    fi
                fi
            done
            
            echo "---" >> "$outfile"
            echo "" >> "$outfile"
        fi
    fi
done

# 清理临时文件
rm -f /tmp/proxychains.conf

# 检查结果
if [ ! -f "$outfile" ]; then
    echo "❌ 错误：未能创建输出文件"
    exit 1
fi

file_size=$(ls -lh "$outfile" | awk '{print $5}')
line_count=$(wc -l < "$outfile")

echo "✅ 抓取完成！"
echo "📊 文件信息："
echo "   - 文件大小: $file_size"
echo "   - 总行数: $line_count"
echo "   - 保存位置: $outfile"

echo ""
echo "🎉 Markdown文件已生成，包含："
echo "   ✓ 博主推文内容"
echo "   ✓ 推文统计数据"
echo "   ✓ 博主自己的评论回复"
echo "   ✓ 所有图片链接"
echo "   ✓ 推文链接"

echo ""
echo "💡 使用说明："
echo "   - 修改脚本开头的 channel=\"@用户名\" 来抓取不同博主"
echo "   - 可以用Markdown编辑器或浏览器查看"
echo "   - 图片链接可直接在Markdown中显示" 