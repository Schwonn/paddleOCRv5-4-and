# AutoGo PPOCRv5 Socket OCR

一个基于 Lua + TCP Socket 的 OCR 识别封装模块，支持 Android 本地 OCR 服务通信，实现文字识别、找字、点击等自动化操作。

---

# 🚀 功能特点

- 📡 基于 TCP Socket 与 OCR 服务通信
- 🔍 支持屏幕区域文字识别
- 🎯 支持找字定位（中心点 / 随机点）
- 🖱️ 自动点击识别结果
- ⚡ JSON 自动转义处理
- 🧠 兼容 arm64 / x86 / x86_64 架构

---

# 📦 运行环境

## 依赖

- Lua 环境（支持 socket）
- LuaSocket（`require("socket")`）
- Android root / shell 权限
- OCR 服务二进制（arm64 / x86 / x86_64）

---


---

# ⚙️ OCR服务启动流程

代码会自动完成以下操作：

### 1️⃣ 获取设备架构
```lua
exec("getprop ro.product.cpu.abi")

支持：
arm64-v8a
x86
x86_64

###  2️⃣ 启动 OCR 服务
