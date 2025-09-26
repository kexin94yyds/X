#!/bin/zsh

# 配置推文信息
tweet_url="https://x.com/stijnnoorman/status/1927356139236151539"
tweet_id="1927356139236151539"
blogger_username="stijnnoorman"
outfile="${blogger_username}_${tweet_id}_all_comments.md"

echo "🚀 开始抓取推文和所有评论..."
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
# @$blogger_username 推文完整评论合集

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
        echo "# 💬 所有评论" >> "$outfile"
        echo "" >> "$outfile"
    fi
fi

echo "💬 开始抓取所有评论（限制200条）..."
comment_count=0

# 获取该推文的所有评论
proxychains4 -f /tmp/proxychains.conf twscrape tweet_replies "$tweet_id" --limit 200 2>/dev/null | \
jq -r '
  {
    id: .id,
    date: .date,
    content: .rawContent,
    username: .user.username,
    displayName: .user.displayName,
    verified: .user.verified,
    media: [.media[]? | select(.type == "photo") | .url],
    replies: .replyCount,
    retweets: .retweetCount,
    likes: .likeCount,
    isOP: (.user.id == "'$user_id'")
  }
' | \
while IFS= read -r reply_json; do
    if [ -n "$reply_json" ] && [ "$reply_json" != "null" ]; then
        reply_id=$(echo "$reply_json" | jq -r '.id // empty')
        reply_date=$(echo "$reply_json" | jq -r '.date // empty')
        reply_content=$(echo "$reply_json" | jq -r '.content // empty')
        reply_username=$(echo "$reply_json" | jq -r '.username // empty')
        reply_displayname=$(echo "$reply_json" | jq -r '.displayName // empty')
        reply_verified=$(echo "$reply_json" | jq -r '.verified // false')
        reply_replies=$(echo "$reply_json" | jq -r '.replies // 0')
        reply_retweets=$(echo "$reply_json" | jq -r '.retweets // 0')
        reply_likes=$(echo "$reply_json" | jq -r '.likes // 0')
        is_op=$(echo "$reply_json" | jq -r '.isOP // false')
        
        if [ -n "$reply_content" ] && [ "$reply_content" != "null" ]; then
            reply_formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${reply_date:0:19}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "${reply_date:0:16}")
            
            # 标记博主评论
            if [ "$is_op" = "true" ]; then
                echo "## 🎯 博主回复 - $reply_formatted_date" >> "$outfile"
                echo "**@$reply_username** (原博主)" >> "$outfile"
            else
                echo "## 💬 用户评论 - $reply_formatted_date" >> "$outfile"
                if [ "$reply_verified" = "true" ]; then
                    echo "**@$reply_username** ✅ ($reply_displayname)" >> "$outfile"
                else
                    echo "**@$reply_username** ($reply_displayname)" >> "$outfile"
                fi
            fi
            
            echo "" >> "$outfile"
            echo "$reply_content" >> "$outfile"
            echo "" >> "$outfile"
            echo "**统计:** 💬 $reply_replies | 🔄 $reply_retweets | ❤️ $reply_likes" >> "$outfile"
            echo "" >> "$outfile"
            echo "**链接:** [https://x.com/$reply_username/status/$reply_id](https://x.com/$reply_username/status/$reply_id)" >> "$outfile"
            echo "" >> "$outfile"
            
            # 处理评论中的图片
            reply_media=$(echo "$reply_json" | jq -r '.media[]? // empty')
            if [ -n "$reply_media" ]; then
                echo "**图片:**" >> "$outfile"
                echo "$reply_media" | while IFS= read -r reply_img; do
                    if [ -n "$reply_img" ]; then
                        echo "![评论图片]($reply_img)" >> "$outfile"
                    fi
                done
                echo "" >> "$outfile"
            fi
            
            echo "---" >> "$outfile"
            echo "" >> "$outfile"
            
            comment_count=$((comment_count + 1))
            echo "📝 已处理 $comment_count 条评论..."
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
echo "   - 评论数量: $comment_count"
echo "   - 保存位置: $outfile"

echo ""
echo "🎉 Markdown文件已生成，包含："
echo "   ✓ 原始推文内容和图片"
echo "   ✓ 推文统计数据"
echo "   ✓ 所有用户的评论（包括博主回复）"
echo "   ✓ 评论者信息和认证状态"
echo "   ✓ 评论的图片和统计数据"
echo "   ✓ 所有相关链接"

echo ""
echo "💡 博主回复会特别标记为 🎯"
echo "💡 认证用户会显示 ✅ 标记" 