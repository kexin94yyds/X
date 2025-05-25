# Twitter 爬虫完整使用指南

## 📋 目录
- [问题排除指南](#问题排除指南)
  - [问题1: twscrape 账户配置失效](#问题1-twscrape-账户配置失效)
  - [问题2: 代理连接错误](#问题2-代理连接错误)
  - [问题3: jq 解析错误](#问题3-jq-解析错误)
- [文件安全管理](#文件安全管理)
- [文件丢失恢复指南](#文件丢失恢复指南)
- [常用诊断命令](#常用诊断命令)

---

# 问题排除指南

## 问题1: twscrape 账户配置失效

### 🚨 症状表现
```bash
# 运行爬虫时出现
jq: parse error: Invalid numeric literal at line 1, column 4
✅ 完成：共 0 条推文 → 文件名.txt

# 检查账户状态
twscrape accounts
# 输出为空或显示 Total: 0

twscrape stats
# 显示 Total: 0 - Active: 0 - Inactive: 0
```

### 🔍 问题原因
1. **Twitter 账户认证过期** - cookies 失效或被撤销
2. **数据库被重置** - twscrape 数据库文件损坏或清空
3. **账户被限制** - Twitter 检测到自动化行为
4. **系统更新** - twscrape 版本更新导致配置丢失

### ✅ 解决方案

#### 步骤1: 诊断问题
```bash
# 检查账户状态
twscrape accounts
twscrape stats

# 检查数据库
sqlite3 accounts.db "SELECT count(*) FROM accounts;"
```

#### 步骤2: 重新配置账户
```bash
# 创建账户配置文件
echo 'myacc:_:_:_:你的cookies字符串' > accounts.txt

# 添加账户
twscrape add_accounts accounts.txt "username:email:password:email_password:cookies"

# 登录账户
twscrape login_accounts

# 验证配置
twscrape accounts
twscrape stats
```

#### 步骤3: 获取 Twitter Cookies
1. 打开浏览器，登录 Twitter/X
2. 按 F12 打开开发者工具
3. 进入 Application/Storage → Cookies → x.com
4. 复制所有 cookies，格式如：
```
_cf_bm=值; att=值; auth_token=值; ct0=值; guest_id=值; kdt=值; twid=值
```

### 📝 预防措施
- 定期备份 `accounts.db` 文件
- 避免频繁大量爬取
- 使用多个账户轮换
- 监控账户状态

---

## 问题2: 代理连接错误

### 🚨 症状表现
```bash
[proxychains] Strict chain  ...  127.0.0.1:9050  ...  timeout
httpx.ConnectError: All connection attempts failed
```

### 🔍 问题原因
1. **代理配置错误** - 端口号不正确
2. **代理服务未启动** - Clash/代理软件未运行
3. **配置文件路径错误** - proxychains 配置文件位置不对

### ✅ 解决方案

#### 步骤1: 检查代理服务
```bash
# 检查 Clash 是否运行
ps aux | grep clash

# 检查端口是否开放
lsof -i :33210

# 测试代理连接
curl -x http://127.0.0.1:33210 -s -o /dev/null -w "%{http_code}" https://x.com
```

#### 步骤2: 修正代理配置
```bash
# 创建正确的代理配置文件
echo -e "strict_chain\nproxy_dns\n[ProxyList]\nhttp 127.0.0.1 33210" > /tmp/proxychains.conf

# 验证配置
cat /tmp/proxychains.conf
```

#### 步骤3: 测试连接
```bash
# 测试代理是否工作
proxychains4 -f /tmp/proxychains.conf curl -s https://x.com | head -5
```

### 📝 常见端口
- **Clash**: 33210 (HTTP), 33211 (SOCKS)
- **V2Ray**: 1080, 10809
- **Shadowsocks**: 1080
- **Tor**: 9050

---

## 问题3: jq 解析错误

### 🚨 症状表现
```bash
jq: parse error: Invalid numeric literal at line 1, column 4
```

### 🔍 问题原因
1. **API 返回空数据** - 通常由账户问题引起
2. **API 返回错误信息** - 而不是 JSON 格式
3. **网络连接问题** - 数据传输不完整

### ✅ 解决方案

#### 步骤1: 检查原始输出
```bash
# 查看 twscrape 原始输出
proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "用户名"

# 检查是否返回有效 JSON
proxychains4 -f /tmp/proxychains.conf twscrape user_tweets "用户ID" --limit 1
```

#### 步骤2: 验证账户和网络
- 确认 twscrape 账户配置正确
- 检查代理连接状态
- 测试不同的用户名

---

# 文件安全管理

## 🔒 **文件分类指南**

### ✅ **可以分享的文件（安全）**
```
📄 文档类
├── Twitter爬虫完整使用指南.md
├── Twitter爬虫完整故障排除手册.md
└── README.md (如果有)

🔧 脚本类
├── NavalismHQ.zsh (基础脚本模板)
├── blogger.zsh (临时脚本，可删除)
└── *.zsh (其他脚本模板)

📊 数据类 (去敏感化后)
├── *_test.txt (推文数据，可分享)
├── *_2025.txt (年份分类数据)
└── *_2024.txt 等
```

### 🚨 **绝对不能分享的文件（敏感）**
```
🔐 认证信息
├── accounts.txt ⚠️ 包含你的 Twitter cookies
├── accounts.db ⚠️ twscrape 数据库，包含账户信息
└── /tmp/proxychains.conf ⚠️ 代理配置

🗂️ 系统文件
├── .DS_Store
└── .git/ (如果包含敏感提交记录)
```

### ⚠️ **需要检查的文件（可能敏感）**
```
📝 配置文件
├── *.conf (检查是否包含代理信息)
└── *.config (检查是否包含个人信息)

📊 日志文件
├── *.log (可能包含 IP 或认证信息)
└── debug 输出文件
```

## 🛡️ **安全建议**

### 1️⃣ **立即删除敏感文件**
```bash
# 删除包含 cookies 的文件
rm -f accounts.txt
rm -f /tmp/proxychains.conf

# 清理临时文件
rm -f blogger.zsh
```

### 2️⃣ **备份重要文件**
```bash
# 备份数据库（私人保存）
cp accounts.db ~/Documents/twitter_backup.db

# 备份推文数据
cp *_test.txt ~/Documents/
```

### 3️⃣ **创建分发包**
```bash
# 只包含安全文件
mkdir twitter_scraper_public
cp NavalismHQ.zsh twitter_scraper_public/
cp Twitter爬虫*.md twitter_scraper_public/
```

### 4️⃣ **Git 安全**
如果使用 Git，添加 `.gitignore`：
```
accounts.txt
accounts.db
*.conf
/tmp/
*.log
```

---

# 文件丢失恢复指南

## 🚨 **不同文件丢失的处理方法**

### 1️⃣ **accounts.db 丢失（最常见）**

#### 🔍 **症状**
- 运行爬虫时显示 0 条推文
- `twscrape accounts` 无输出
- `twscrape stats` 显示 Total: 0

#### ✅ **完整恢复步骤**
```bash
# 1. 重新获取 Twitter cookies
# 打开浏览器 → 登录 x.com → F12 → Application → Cookies → x.com
# 复制所有 cookies

# 2. 创建新的账户配置
echo 'myacc:_:_:_:你的新cookies字符串' > accounts.txt

# 3. 添加账户到 twscrape
twscrape add_accounts accounts.txt "username:email:password:email_password:cookies"

# 4. 登录账户
twscrape login_accounts

# 5. 验证恢复
twscrape accounts
twscrape stats

# 6. 测试功能
proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "elonmusk"
```

### 2️⃣ **NavalismHQ.zsh 基础脚本丢失**

#### ✅ **重新创建脚本**
```bash
# 创建基础脚本文件
cat > NavalismHQ.zsh << 'EOF'
#!/bin/zsh

channel="@NavalismHQ"
name="${channel#@}"
outfile="${name}_test.txt"

echo "📥 快速测试输出文件：$outfile"

cat > /tmp/proxychains.conf << EOF2
strict_chain
proxy_dns
[ProxyList]
http 127.0.0.1 33210
EOF2

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
EOF

# 添加执行权限
chmod +x NavalismHQ.zsh
```

### 3️⃣ **代理配置文件丢失**

#### ✅ **重新创建代理配置**
```bash
# 创建代理配置文件
echo -e "strict_chain\nproxy_dns\n[ProxyList]\nhttp 127.0.0.1 33210" > /tmp/proxychains.conf

# 验证配置
cat /tmp/proxychains.conf

# 测试代理
curl -x http://127.0.0.1:33210 -s -o /dev/null -w "%{http_code}" https://x.com
```

### 4️⃣ **所有文件都丢失（完全重建）**

#### ✅ **从零开始重建**
```bash
# 1. 创建工作目录
mkdir -p ~/Desktop/爬推特
cd ~/Desktop/爬推特

# 2. 重新安装依赖（如果需要）
pip install twscrape
brew install proxychains-ng jq  # macOS

# 3. 创建基础脚本（使用上面的脚本内容）

# 4. 配置 Twitter 账户（使用上面的步骤）

# 5. 创建代理配置（使用上面的配置）

# 6. 测试完整功能
./NavalismHQ.zsh
```

## 🔄 **预防文件丢失的措施**

### 1️⃣ **定期备份**
```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
backup_dir="$HOME/Documents/twitter_scraper_backup_$(date +%Y%m%d)"
mkdir -p "$backup_dir"
cp accounts.db "$backup_dir/"
cp NavalismHQ.zsh "$backup_dir/"
cp *.md "$backup_dir/"
echo "✅ 备份完成: $backup_dir"
EOF

chmod +x backup.sh
```

### 2️⃣ **云端同步**
- 将非敏感文件同步到 iCloud/Google Drive
- 敏感文件（accounts.db）单独加密备份

### 3️⃣ **版本控制**
```bash
# 初始化 git（注意 .gitignore）
git init
echo -e "accounts.txt\naccounts.db\n*.conf\n/tmp/\n*.log" > .gitignore
git add .
git commit -m "Initial commit"
```

---

# 常用诊断命令

## 🔧 系统检查
```bash
# 检查依赖安装
which twscrape
which jq
which proxychains4

# 检查版本
twscrape version
jq --version
```

## 🔍 账户诊断
```bash
# 完整账户信息
twscrape accounts
twscrape stats

# 数据库查询
sqlite3 accounts.db "SELECT username, active, last_used FROM accounts;"
```

## 🌐 网络诊断
```bash
# 测试代理
curl -x http://127.0.0.1:33210 -s -o /dev/null -w "%{http_code}" https://x.com

# 测试直连
curl -s -o /dev/null -w "%{http_code}" https://x.com

# 检查端口
lsof -i :33210
netstat -an | grep 33210
```

## 📁 文件检查
```bash
# 检查生成的文件
ls -la *test.txt
find . -name "*.txt" -size +0c

# 查看文件内容
head -5 文件名.txt
wc -l 文件名.txt
```

## 🆘 快速修复流程

### 当爬虫不工作时，按顺序检查：

1. **检查账户状态**
   ```bash
   twscrape accounts && twscrape stats
   ```

2. **检查代理连接**
   ```bash
   curl -x http://127.0.0.1:33210 -s -o /dev/null -w "%{http_code}" https://x.com
   ```

3. **测试基本功能**
   ```bash
   proxychains4 -f /tmp/proxychains.conf twscrape user_by_login "elonmusk"
   ```

4. **重新配置账户**（如果前面步骤失败）
   - 获取新的 Twitter cookies
   - 重新添加账户配置

---

## 📞 技术支持

### 遇到新问题时：
1. 记录完整的错误信息
2. 运行诊断命令收集信息
3. 将问题和解决方案添加到此文档
4. 或咨询 AI 助手进行分析

### 常见问题快速链接：
- **0条推文** → [问题1: twscrape 账户配置失效](#问题1-twscrape-账户配置失效)
- **连接超时** → [问题2: 代理连接错误](#问题2-代理连接错误)
- **解析错误** → [问题3: jq 解析错误](#问题3-jq-解析错误)
- **文件丢失** → [文件丢失恢复指南](#文件丢失恢复指南)

---

*最后更新: 2025-05-25*  
*版本: 1.0*  
*包含: 问题排除 + 文件安全 + 恢复指南* 
