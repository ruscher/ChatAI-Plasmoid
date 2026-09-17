#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#
# Usage: QT_QPA_PLATFORM=offscreen QTWEBENGINE_CHROMIUM_FLAGS=--disable-gpu \
#        python3 tools/provider-probe/probe.py [default|chrome] [results.jsonl]
# Env:   PROBE_ONLY=id1,id2  PROBE_TIMEOUT=ms
# Provider load probe for ChatAI-Plasmoid. Loads each URL in an off-the-record
# QtWebEngine profile, records load status, final URL, title and page hints.
import json, os, sys, re
from PySide6.QtCore import QUrl, QTimer, QObject, Slot, Property, Signal
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWebEngineQuick import QtWebEngineQuick

PROVIDERS = [
 ("chatgpt","https://chatgpt.com"),("claude","https://claude.ai/new"),("gemini","https://gemini.google.com/app"),
 ("deepseek","https://chat.deepseek.com"),("mscopilot","https://copilot.microsoft.com/"),("perplexity","https://www.perplexity.ai"),
 ("duckduckgo","https://duckduckgo.com/chat"),("duckai","https://duck.ai/chat"),("huggingchat","https://huggingface.co/chat"),
 ("you","https://you.com/?chatMode=default"),("blackbox","https://www.blackbox.ai"),("meta","https://www.meta.ai"),
 ("grok-x","https://x.com/i/grok"),("grok","https://grok.com"),("t3","https://t3.chat"),("lobechat","https://lobechat.com/chat"),
 ("bigagi","https://get.big-agi.com"),("ghcopilot","https://github.com/copilot"),("manus","https://manus.im/app"),
 ("qwen","https://chat.qwen.ai"),("kimi","https://www.kimi.com"),("mistral","https://chat.mistral.ai"),
]

class Bridge(QObject):
    def __init__(self, ua_mode, out):
        super().__init__(); self.ua_mode=ua_mode; self.out=out
    @Slot(str, result=str)
    def userAgent(self, default_ua):
        if self.ua_mode == "default": return default_ua
        return re.sub(r"\s*QtWebEngine/[\d.]+", "", default_ua)
    @Slot(str)
    def record(self, line):
        with open(self.out, "a") as f: f.write(line+"\n")
        print(line, flush=True)
    @Slot()
    def done(self):
        QGuiApplication.quit()

if __name__ == "__main__":
    ua_mode = sys.argv[1] if len(sys.argv) > 1 else "default"
    out = sys.argv[2] if len(sys.argv) > 2 else f"results-{ua_mode}.jsonl"
    open(out, "w").close()
    QtWebEngineQuick.initialize()
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    bridge = Bridge(ua_mode, out)
    engine.rootContext().setContextProperty("bridge", bridge)
    only=[x for x in os.environ.get("PROBE_ONLY","").split(",") if x]
    sel=[(i,u) for i,u in PROVIDERS if not only or i in only]
    engine.rootContext().setContextProperty("providers", [{"id":i,"url":u} for i,u in sel])
    engine.rootContext().setContextProperty("guardMs", int(os.environ.get("PROBE_TIMEOUT","30000")))
    engine.load(QUrl.fromLocalFile(os.path.join(os.path.dirname(__file__), "probe.qml")))
    if not engine.rootObjects(): sys.exit(1)
    QTimer.singleShot(20*60*1000, app.quit)
    sys.exit(app.exec())
