"""Enter locally supplied demo credentials through native Settings, off camera.

No keys are logged, embedded in an APK, or written to a tracked file.
Run only on the dedicated demo emulator; saves its Settings preferences.
"""

from __future__ import annotations

import re
import time

from dotenv import dotenv_values

from android_demo import ROOT, adb, nodes, tap_text


def main() -> None:
    config = dotenv_values(ROOT / "backend" / ".env")
    key = config.get("LLM_API_KEY")
    if not key:
        raise RuntimeError("Local DeepSeek configuration is missing")
    tap_text("Setelan")
    time.sleep(1)
    fields = [n for n in nodes() if n.get("class") == "android.widget.EditText"]
    if len(fields) < 2:
        raise RuntimeError("Settings inputs not visible")
    node = fields[1]
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds", "")))
    adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
    adb("shell", "input", "keyevent", "123")
    adb("shell", "input", "keyevent", *(["67"] * 100))
    adb("shell", "input", "text", key)
    adb("shell", "input", "keyevent", "4")
    time.sleep(1)
    for _ in range(6):
        if any("Save Settings" in n.get("content-desc", "") + n.get("text", "")
               for n in nodes()):
            break
        adb("shell", "input", "swipe", "540", "1700", "540", "650", "400")
        time.sleep(0.5)
    tap_text("Save Settings")
    time.sleep(1)
    tap_text("Beranda")
    print("DeepSeek demo preference saved through native UI; no key logged")


if __name__ == "__main__":
    main()
