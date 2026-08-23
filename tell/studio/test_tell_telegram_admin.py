import json
import urllib.parse
import urllib.request
from pathlib import Path


def load_env(path):
    values = {}
    for line in Path(path).read_text().splitlines():
        if line and not line.lstrip().startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip()
    return values


env = load_env("/home/frankstone/.config/tell/telegram.env")
payload = urllib.parse.urlencode({
    "chat_id": env["TELEGRAM_ADMIN_CHAT_ID"],
    "text": "TELL feedback channel connected.\n破绽玩家反馈通道已连接。",
}).encode()
url = f"https://api.telegram.org/bot{env['TELEGRAM_BOT_TOKEN']}/sendMessage"
with urllib.request.urlopen(urllib.request.Request(url, data=payload), timeout=15) as response:
    result = json.load(response)
if not result.get("ok"):
    raise SystemExit("ADMIN_TEST_FAILED")
print("ADMIN_TEST_SENT")
