local socket = require("socket")

-- ================== 启动OCR服务 ==================
local type = exec("getprop ro.product.cpu.abi")
type = string.gsub(type, "[%s\r\n]", "")
print("架构: [" .. type .. "]")

local bytefileName = ""

if type == "arm64-v8a" then
    bytefileName = "arm64"
elseif type == "x86_64" then
    bytefileName = "x86_64"
elseif type == "x86" then
    bytefileName = "x86"
else
    print("无法识别设备的架构")
    toast("无法识别设备的架构")
    exitScript()
end

-- 强制停止旧进程
exec("pkill -f " .. bytefileName)

local binPath = "/data/local/tmp/" .. bytefileName
local PORT = 9091

extractAssets("传奇.rc", "/data/local/tmp", bytefileName)
exec("chmod 755 " .. binPath)
exec("nohup " .. binPath .. " " .. PORT .. " > /dev/null 2>&1 &")
sleep(1000)

print("准备连接 OCR 服务...")

-- ================== 建立TCP连接 ==================
local client = socket.tcp()
client:settimeout(5)

local ok, err = client:connect("127.0.0.1", PORT)
if not ok then
    print("❌ OCR连接失败:", err)
    return
end

print("✅ OCR连接成功")

识别位置默认输出信息 = false

-- ================== JSON转义（关键修复） ==================
function jsonEscape(str)
    if not str then return "" end
    str = tostring(str)
    str = string.gsub(str, "\\", "\\\\")
    str = string.gsub(str, "\"", "\\\"")
    str = string.gsub(str, "\n", "\\n")
    str = string.gsub(str, "\r", "\\r")
    return str
end

-- ================== 请求函数 ==================
function OCR请求(type, x1, y1, x2, y2, text, color)
    if not color then color = "" end

    text = text and jsonEscape(text) or nil
    color = jsonEscape(color)

    local req

    if text then
        req = string.format(
            '{"type":"%s","x1":%d,"y1":%d,"x2":%d,"y2":%d,"text":"%s","colorStr":"%s"}\n',
            type, x1, y1, x2, y2, text, color
        )
    else
        req = string.format(
            '{"type":"%s","x1":%d,"y1":%d,"x2":%d,"y2":%d,"colorStr":"%s"}\n',
            type, x1, y1, x2, y2, color
        )
    end

    -- 🔥 调试：看发送内容
    print("发送:", req)

    local ok, err = client:send(req)
    if not ok then
        print("发送失败:", err)
        return nil
    end

    local resp, err = client:receive("*l")
    if not resp then
        print("接收失败:", err)
        return nil
    end

    -- 🔥 调试：看返回内容
    print("返回:", resp)

    return resp
end

-- ================== 解析 ==================

function 解析坐标(resp)
    if not resp or resp == "[]" then return nil end

    local x = string.match(resp, '"x"%s*:%s*(%d+)')
    local y = string.match(resp, '"y"%s*:%s*(%d+)')

    if x and y then
        return tonumber(x), tonumber(y)
    end

    return nil
end

function 解析范围(resp)
    if not resp or resp == "[]" then return nil end

    local x = string.match(resp, '"X"%s*:%s*(%d+)')
    local y = string.match(resp, '"Y"%s*:%s*(%d+)')

    -- 兼容中英字段
    local w = string.match(resp, '"Width"%s*:%s*(%d+)') or string.match(resp, '"宽"%s*:%s*(%d+)')
    local h = string.match(resp, '"Height"%s*:%s*(%d+)') or string.match(resp, '"高"%s*:%s*(%d+)')

    if x and y and w and h then
        return tonumber(x), tonumber(y), tonumber(w), tonumber(h)
    end

    return nil
end

-- ================== 原函数（完全兼容） ==================

-- 1️⃣ 全部识别
function ScreenOCR(x1, y1, x2, y2, color)
    local resp = OCR请求("all", x1, y1, x2, y2, nil, color)
    if not resp then return nil end

    if 识别位置默认输出信息 then
        print(resp)
    end

    return resp ~= "[]" and jsonLib.decode(resp) or nil
end

-- 2️⃣ 找字范围
function FindTextRegion(x1, y1, x2, y2, 寻找文字, color)
    local resp = OCR请求("find", x1, y1, x2, y2, 寻找文字, color)

    local x, y, w, h = 解析范围(resp)
    if x then
        return { true, x, y, w, h }
    end

    return false
end

-- 3️⃣ 随机点击
function FindTextRandomClick(x1, y1, x2, y2, 寻找文字, 是否点击, color)
    local resp = OCR请求("rand", x1, y1, x2, y2, 寻找文字, color)

    local x, y = 解析坐标(resp)
    if x then
        if 是否点击 then
            tap(x, y)
        end
        return { true, x, y }
    end

    return false
end

-- 4️⃣ 中心点击
function FindTextCenterClick(x1, y1, x2, y2, 寻找文字, 是否点击, color)
    local resp = OCR请求("center", x1, y1, x2, y2, 寻找文字, color)

    local x, y = 解析坐标(resp)
    if x then
        if 是否点击 then
            tap(x, y)
        end
        return { true, x, y }
    end

    return false
end
