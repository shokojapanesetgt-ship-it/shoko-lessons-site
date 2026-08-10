#!/bin/bash
cd "$(dirname "$0")"

IP=$(ipconfig getifaddr en0)
if [ -z "$IP" ]; then
  IP=$(ipconfig getifaddr en1)
fi

PORT=8000

echo ""
echo "确保 iPhone 和这台 Mac 连的是同一个 WiFi。"
echo ""
if [ -z "$IP" ]; then
  echo "没查到局域网 IP，请确认 Mac 已连接 WiFi 后重新运行这个脚本。"
  echo ""
  read -n 1 -s -r -p "按任意键关闭窗口"
  exit 1
fi

echo "在 iPhone 的 Safari 里打开这个地址："
echo ""
echo "   http://$IP:$PORT/index.html"
echo ""
echo "测试完按 Ctrl+C 停止服务器（或直接关掉这个窗口）。"
echo ""

python3 -m http.server $PORT
