#!/usr/bin/env python3
"""
Selenium Twitter测试脚本
用于验证是否能通过浏览器自动化绕过Twitter风控
"""

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import time
import json

def test_twitter_access():
    # 设置Chrome选项
    options = webdriver.ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    # 可选：无头模式
    # options.add_argument('--headless')
    
    # 设置User-Agent模拟真实浏览器
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    try:
        # 自动下载并设置ChromeDriver
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=options)
        
        print("启动浏览器成功...")
        
        # 访问Twitter首页
        driver.get("https://twitter.com")
        time.sleep(3)
        
        print(f"页面标题: {driver.title}")
        print(f"当前URL: {driver.current_url}")
        
        # 检查是否被重定向到登录页或正常加载
        if "login" in driver.current_url.lower() or "sign" in driver.current_url.lower():
            print("✅ 成功访问Twitter，页面要求登录（正常）")
        elif "twitter.com" in driver.current_url or "x.com" in driver.current_url:
            print("✅ 成功访问Twitter主页")
        else:
            print(f"⚠️  被重定向到: {driver.current_url}")
        
        # 尝试搜索一个公开推文
        try:
            driver.get("https://twitter.com/search?q=test&src=typed_query")
            time.sleep(5)
            print("✅ 搜索页面加载成功")
            
            # 检查是否有搜索结果
            tweets = driver.find_elements(By.CSS_SELECTOR, '[data-testid="tweet"]')
            print(f"找到推文数量: {len(tweets)}")
            
        except Exception as e:
            print(f"❌ 搜索测试失败: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ Selenium测试失败: {e}")
        return False
        
    finally:
        try:
            driver.quit()
            print("浏览器已关闭")
        except:
            pass

if __name__ == "__main__":
    print("=== Selenium Twitter访问测试 ===")
    success = test_twitter_access()
    
    if success:
        print("\n✅ Selenium方案可行，可以考虑用浏览器自动化替代twscrape")
        print("💡 建议：开发基于selenium的Twitter爬虫脚本")
    else:
        print("\n❌ Selenium方案也遇到问题，可能需要其他解决方案")