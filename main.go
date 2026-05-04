package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"math/rand"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Dasongzi1366/AutoGo/ppocr"
)

var ocr *ppocr.Ppocr

// ================= 初始化 =================
func init() {
	rand.Seed(time.Now().UnixNano())

	ocr = ppocr.New("v5")
	if ocr == nil {
		fmt.Println("OCR 初始化失败")
		return
	}
	fmt.Println("OCR 初始化成功")
}

// ================= 数据结构 =================
type Request struct {
	Type     string `json:"type"` // all / find / rand / center
	X1       int    `json:"x1"`
	Y1       int    `json:"y1"`
	X2       int    `json:"x2"`
	Y2       int    `json:"y2"`
	Text     string `json:"text"`     // find类用
	ColorStr string `json:"colorStr"` // 可选
}

type Point struct {
	X int `json:"x"`
	Y int `json:"y"`
}

// ================= 功能函数 =================

// 返回全部 OCR
func All(x1, y1, x2, y2 int, colorStr string) []byte {
	results := ocr.Ocr(x1, y1, x2, y2, colorStr, 0)
	jsonBytes, _ := json.Marshal(results)
	return jsonBytes
}

// 找匹配（返回原始对象）
func Findstr(x1, y1, x2, y2 int, text, colorStr string) []byte {
	results := ocr.Ocr(x1, y1, x2, y2, colorStr, 0)

	for _, v := range results {
		if strings.Contains(v.Label, text) {
			jsonBytes, _ := json.Marshal(v)
			return jsonBytes
		}
	}

	empty := []interface{}{}
	jsonBytes, _ := json.Marshal(empty)
	return jsonBytes
}

// 返回随机点
func FindstrRand(x1, y1, x2, y2 int, text, colorStr string) []byte {
	results := ocr.Ocr(x1, y1, x2, y2, colorStr, 0)

	for _, v := range results {
		if strings.Contains(v.Label, text) {
			rx := v.X + rand.Intn(v.Width)
			ry := v.Y + rand.Intn(v.Height)

			p := Point{X: rx, Y: ry}
			jsonBytes, _ := json.Marshal(p)
			return jsonBytes
		}
	}

	empty := []interface{}{}
	jsonBytes, _ := json.Marshal(empty)
	return jsonBytes
}

// 返回中心点
func FindstrCenter(x1, y1, x2, y2 int, text, colorStr string) []byte {
	results := ocr.Ocr(x1, y1, x2, y2, colorStr, 0)

	for _, v := range results {
		if strings.Contains(v.Label, text) {
			cx := v.X + v.Width/2
			cy := v.Y + v.Height/2

			p := Point{X: cx, Y: cy}
			jsonBytes, _ := json.Marshal(p)
			return jsonBytes
		}
	}

	empty := []interface{}{}
	jsonBytes, _ := json.Marshal(empty)
	return jsonBytes
}

// ================= 核心通信 =================
func handleConn(conn net.Conn) {
	defer conn.Close()

	fmt.Println("客户端连接：", conn.RemoteAddr())
	reader := bufio.NewReader(conn)

	for {
		msg, err := reader.ReadString('\n')
		if err != nil {
			fmt.Println("连接断开：", err)
			return
		}

		msg = strings.TrimSpace(msg)
		fmt.Println("收到：", msg)

		var req Request
		err = json.Unmarshal([]byte(msg), &req)
		if err != nil {
			conn.Write([]byte(`{"error":"json解析失败"}` + "\n"))
			continue
		}
		// 默认处理（colorStr 可不传）
		if req.ColorStr == "" {
			req.ColorStr = ""
		}

		var res []byte

		switch req.Type {
		case "all":
			res = All(req.X1, req.Y1, req.X2, req.Y2, req.ColorStr)

		case "find":
			fmt.Println("到 find 了")
			res = Findstr(req.X1, req.Y1, req.X2, req.Y2, req.Text, req.ColorStr)

		case "rand":
			res = FindstrRand(req.X1, req.Y1, req.X2, req.Y2, req.Text, req.ColorStr)

		case "center":
			res = FindstrCenter(req.X1, req.Y1, req.X2, req.Y2, req.Text, req.ColorStr)

		default:
			res = []byte(`{"error":"未知type"}`)
		}

		conn.Write(append(res, '\n')) // 必须带换行
	}
}

// ================= 主函数（端口参数 + 占用检测） =================
func main() {
	// 默认端口
	port := 9091

	// 命令行传参
	if len(os.Args) > 1 {
		p, err := strconv.Atoi(os.Args[1])
		if err == nil && p > 0 && p < 65536 {
			port = p
		}
	}

	addr := fmt.Sprintf(":%d", port)

	// 监听（同时检测端口占用）
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		fmt.Println("busy")
		os.Exit(1)
	}
	defer listener.Close()

	fmt.Println("服务启动，端口", port)

	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}
		go handleConn(conn)
	}
}
