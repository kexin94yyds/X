#!/bin/zsh

# 配置推文信息
tweet_url="https://x.com/stijnnoorman/status/1927356139236151539"
tweet_id="1927356139236151539"
blogger_username="stijnnoorman"
outfile="${blogger_username}_${tweet_id}_comments.md"

echo "🚀 开始抓取推文评论和图片..."
echo "📥 推文链接：$tweet_url"
echo "📥 输出文件：$outfile"

# 创建代理配置
cat > /tmp/proxychains.conf << EOF
strict_chain
proxy_dns
[ProxyList]
http 127.0.0.1 33210
EOF

echo "🔍 获取博主用户ID..."
user_id=$(proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "$blogger_username" 2>/dev/null | jq -r '.id')

if [ -z "$user_id" ] || [ "$user_id" = "null" ]; then
    echo "❌ 错误：无法获取用户 $blogger_username 的ID"
    rm -f /tmp/proxychains.conf
    exit 1
fi

echo "✅ 博主用户ID: $user_id"

# 创建Markdown文件头部
cat > "$outfile" << EOF
# @$blogger_username 推文评论合集

> 抓取时间: $(date '+%Y-%m-%d %H:%M:%S')
> 推文链接: [$tweet_url]($tweet_url)
> 博主: [@$blogger_username](https://x.com/$blogger_username)

---

EOF

echo "📊 获取原始推文信息..."
# 获取原始推文信息
tweet_info=$(proxychains4 -f /tmp/proxychains.conf twscrape tweet_by_id "$tweet_id" 2>/dev/null)

if [ -n "$tweet_info" ] && [ "$tweet_info" != "null" ]; then
    tweet_content=$(echo "$tweet_info" | jq -r '.rawContent // empty')
    tweet_date=$(echo "$tweet_info" | jq -r '.date // empty')
    replies_count=$(echo "$tweet_info" | jq -r '.replyCount // 0')
    retweets_count=$(echo "$tweet_info" | jq -r '.retweetCount // 0')
    likes_count=$(echo "$tweet_info" | jq -r '.likeCount // 0')
    
    if [ -n "$tweet_content" ] && [ "$tweet_content" != "null" ]; then
        formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${tweet_date:0:19}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "${tweet_date:0:16}")
        
        # 写入原始推文
        echo "## 📝 原始推文 - $formatted_date" >> "$outfile"
        echo "" >> "$outfile"
        echo "$tweet_content" >> "$outfile"
        echo "" >> "$outfile"
        echo "**统计:** 💬 $replies_count | 🔄 $retweets_count | ❤️ $likes_count" >> "$outfile"
        echo "" >> "$outfile"
        
        # 处理原始推文图片
        media_urls=$(echo "$tweet_info" | jq -r '.media[]? | select(.type == "photo") | .url')
        if [ -n "$media_urls" ]; then
            echo "**图片:**" >> "$outfile"
            echo "$media_urls" | while IFS= read -r img_url; do
                if [ -n "$img_url" ]; then
                    echo "![图片]($img_url)" >> "$outfile"
                fi
            done
            echo "" >> "$outfile"
        fi
        
        echo "---" >> "$outfile"
        echo "" >> "$outfile"
    fi
fi

echo "💬 开始抓取评论（仅博主回复）..."
# 获取该推文的所有评论，筛选出博主自己的回复
proxychains4 -f /tmp/proxychains.conf twscrape tweet_replies "$tweet_id" --limit 100 2>/dev/null | \
jq -r --arg user_id "$user_id" '
  select(.user.id == $user_id) |
  {
    id: .id,
    date: .date,
    content: .rawContent,
    media: [.media[]? | select(.type == "photo") | .url],
    replies: .replyCount,
    retweets: .retweetCount,
    likes: .likeCount
  }
' | \
while IFS= read -r reply_json; do
    if [ -n "$reply_json" ] && [ "$reply_json" != "null" ]; then
        reply_id=$(echo "$reply_json" | jq -r '.id // empty')
        reply_date=$(echo "$reply_json" | jq -r '.date // empty')
        reply_content=$(echo "$reply_json" | jq -r '.content // empty')
        reply_replies=$(echo "$reply_json" | jq -r '.replies // 0')
        reply_retweets=$(echo "$reply_json" | jq -r '.retweets // 0')
        reply_likes=$(echo "$reply_json" | jq -r '.likes // 0')
        
        if [ -n "$reply_content" ] && [ "$reply_content" != "null" ]; then
            reply_formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${reply_date:0:19}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "${reply_date:0:16}")
            
            echo "## 💬 博主回复 - $reply_formatted_date" >> "$outfile"
            echo "" >> "$outfile"
            echo "$reply_content" >> "$outfile"
            echo "" >> "$outfile"
            echo "**统计:** 💬 $reply_replies | 🔄 $reply_retweets | ❤️ $reply_likes" >> "$outfile"
            echo "" >> "$outfile"
            echo "**回复链接:** [https://x.com/$blogger_username/status/$reply_id](https://x.com/$blogger_username/status/$reply_id)" >> "$outfile"
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
echo "   ✓ 原始推文内容和图片"
echo "   ✓ 推文统计数据"
echo "   ✓ 博主在该推文下的所有回复"
echo "   ✓ 回复的图片和统计数据"
echo "   ✓ 所有相关链接"

echo ""
echo "💡 使用说明："
echo "   - 修改脚本开头的 tweet_url 和相关信息来抓取不同推文"
echo "   - 可以用Markdown编辑器或浏览器查看"
echo "   - 图片链接可直接在Markdown中显示" 