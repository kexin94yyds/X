# Twitter 爬虫 - 完整使用指南

## 🚀 快速开始（已配置用户）
如果你已经配置好环境，直接复制这个命令使用：

```bash
cd ~/Desktop/爬推特 && cp NavalismHQ.zsh blogger.zsh && sed -i '' 's/@NavalismHQ/@BLOGGER_HANDLE/' blogger.zsh && sed -i '' 's/--limit 1000/--limit 1000/' blogger.zsh && ./blogger.zsh && echo "📂 开始年份分类..." && name="BLOGGER_NAME" && for year in 2025 2024 2023 2022 2021 2020 2019 2018; do grep "^$year" ${name}_test.txt > ${name}_${year}.txt 2>/dev/null; count=$(wc -l < ${name}_${year}.txt 2>/dev/null || echo "0"); if [ "$count" -gt 0 ]; then echo "✅ $year年: $count 条推文 → ${name}_${year}.txt"; else rm -f ${name}_${year}.txt; fi; done
```

**使用前替换：**
- `@BLOGGER_HANDLE` → 目标博主（如 `@elonmusk`）
- `BLOGGER_NAME` → 博主名称（如 `elonmusk`）

**示例：爬取 Elon Musk**
```bash
cd ~/Desktop/爬推特 && cp NavalismHQ.zsh blogger.zsh && sed -i '' 's/@NavalismHQ/@elonmusk/' blogger.zsh && sed -i '' 's/--limit 1000/--limit 1000/' blogger.zsh && ./blogger.zsh && echo "📂 开始年份分类..." && name="elonmusk" && for year in 2025 2024 2023 2022 2021 2020 2019 2018; do grep "^$year" ${name}_test.txt > ${name}_${year}.txt 2>/dev/null; count=$(wc -l < ${name}_${year}.txt 2>/dev/null || echo "0"); if [ "$count" -gt 0 ]; then echo "✅ $year年: $count 条推文 → ${name}_${year}.txt"; else rm -f ${name}_${year}.txt; fi; done
```

---

## 🎯 功能简介
一键爬取任意 Twitter 博主的推文，自动按年份分类保存为独立文件。

**输出效果：**
- `博主名_test.txt` - 完整推文文件
- `博主名_2025.txt` - 2025年推文
- `博主名_2024.txt` - 2024年推文
- （其他年份文件...）

---

## 🛠️ 首次配置（新用户必看）

### 📋 环境要求
- **系统**: macOS 或 Linux
- **Python**: 3.7+ 版本
- **代理**: 需要可用的 HTTP 代理服务

### 安装依赖
```bash
# 安装 Python 包
pip install twscrape

# macOS 用户
brew install proxychains-ng jq

# Ubuntu/Debian 用户  
sudo apt install proxychains4 jq
```

### 准备工作目录
```bash
mkdir -p ~/Desktop/爬推特
cd ~/Desktop/爬推特
```

### 获取基础文件
需要一个名为 `NavalismHQ.zsh` 的基础脚本文件（请联系脚本提供者获取）

---

## 📊 使用效果展示
```
🔍 === 全面检查 @elonmusk 抓取完整性 === 🔍

📊 数据统计总览：
   总推文数量: 892 条
   API 使用率: 89.2%

📅 年份分布：
   ✅ 2025年: 456 条推文 → elonmusk_2025.txt
   ✅ 2024年: 321 条推文 → elonmusk_2024.txt
   ✅ 2023年: 115 条推文 → elonmusk_2023.txt

🏁 结论: ✅ 抓取完整且高质量
```

---

## ⚠️ 注意事项
1. 需要配置可用的代理服务
2. 确保网络连接稳定
3. 遵守 Twitter 的使用条款
4. 大量爬取可能被限流
5. 私密账户无法爬取

---

## 🆘 遇到问题？

### 方法1: AI助手（推荐）
**直接把这个文档发给任何 AI 助手说：**

> "我要配置这个 Twitter 爬虫，我的系统是 [你的系统]，遇到了 [具体错误]，请帮我解决"

### 方法2: 常见问题
- **依赖安装失败**: 检查 Python 和包管理器是否正确安装
- **代理连接问题**: 确认代理服务正在运行
- **权限错误**: 使用 `chmod +x NavalismHQ.zsh` 添加执行权限
- **文件不存在**: 确认 `NavalismHQ.zsh` 在工作目录中

### 方法3: 技术支持
- 将错误信息截图发送给脚本提供者
- 或在技术社区求助

---

## 🎉 开始使用
1. 完成环境配置
2. 获取 `NavalismHQ.zsh` 文件
3. 复制模板命令并替换博主信息
4. 在终端运行命令
5. 等待爬取完成，查看生成的txt文件

---

**一键爬推特，数据分析更轻松！有问题就问 AI，简单高效！** 🤖 