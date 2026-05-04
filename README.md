# AutoGo PPOCRv5 Socket OCR

A Lua-based OCR automation framework that communicates with a local OCR service via TCP socket.  
It supports text recognition, keyword searching, and automated clicking, designed for Android automation scenarios.

---

# 🚀 Features

- 📡 TCP socket communication with local OCR service
- 🔍 Full-screen text recognition
- 🎯 Keyword detection (center / random click support)
- 🖱️ Automatic clicking on recognized text
- ⚡ Safe JSON escaping handling
- 🧠 Multi-architecture support:
  - arm64-v8a
  - x86
  - x86_64

---

# 📦 Requirements

## Runtime Environment

- Lua interpreter with socket support
- LuaSocket (`require("socket")`)
- Android environment with root or shell execution access
- Precompiled OCR binary for target architecture

---

# 📁 Project Structure
