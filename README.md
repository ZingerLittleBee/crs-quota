# CRS Quotio

macOS 菜单栏应用，用于监控 CRS API 使用额度。

## 功能

- **菜单栏显示** - 点击图标查看统计数据
- **多账户支持** - 可配置多个 API 端点
- **实时数据** - 显示费用、Token 使用量、到期时间等
- **自动刷新** - 每 5 分钟自动更新，支持手动刷新

## 显示数据

- 用户名称、账户状态
- 总费用 / 今日费用
- 每日限额进度条
- 总 Token / 今日 Token
- 并发限制、到期日期

## 环境要求

- macOS 13.0+
- Xcode 15.0+

## 如何运行

1. 打开 `crs-quotio.xcodeproj`
2. 点击 **Run** (Cmd + R)
3. 点击菜单栏图标，进入 Settings 添加 API 配置

## 配置说明

- **Name** - 配置名称
- **Base URL** - API 地址 (如 `http://127.0.0.1:3000`)
- **API ID** - 用户 API ID

## 技术栈

- Swift / SwiftUI
- async/await 异步请求
- UserDefaults 持久化存储
