import QtQuick
import QtQuick.Window
import QtWebEngine

Window {
    id: win
    width: 1100; height: 800; visible: true
    property int index: -1
    property var current: null
    property string status: ""
    property double started: 0

    WebEngineProfile { id: otr; offTheRecord: true }

    Component.onCompleted: {
        otr.httpUserAgent = bridge.userAgent(WebEngine.defaultProfile.httpUserAgent);
        bridge.record(JSON.stringify({meta: "ua", value: otr.httpUserAgent}));
        next();
    }

    function next() {
        index++;
        if (index >= providers.length) { bridge.done(); return; }
        current = providers[index];
        status = "";
        started = Date.now();
        settle.stop();
        guard.restart();
        view.url = current.url;
    }

    function finish(reason) {
        guard.stop(); settle.stop();
        view.runJavaScript(`(() => {
            const t = (document.body ? document.body.innerText : '').replace(/\\s+/g,' ').slice(0, 4000).toLowerCase();
            const hints = ['browser not supported','unsupported browser','update your browser','browser or app may not be secure','disallowed_useragent','verify you are human','just a moment','checking your browser','enable javascript','access denied','forbidden','captcha','cloudflare','not available in your','sign in','log in','login','get started','sign up','continue with google'];
            return JSON.stringify({title: document.title, href: location.href, textLen: t.length, hints: hints.filter(h => t.includes(h)), inputs: document.querySelectorAll('textarea, [contenteditable=true]').length});
        })()`, function (result) {
            let details = {};
            try { details = JSON.parse(result || "{}"); } catch (e) { details = {parseError: String(e)}; }
            bridge.record(JSON.stringify({id: current.id, url: current.url, status: status || reason, reason: reason, ms: Date.now() - started, finalUrl: String(view.url), details: details}));
            Qt.callLater(next);
        });
    }

    Timer { id: guard; interval: guardMs; onTriggered: finish("timeout") }
    Timer { id: settle; interval: 6000; onTriggered: finish("settled") }

    WebEngineView {
        id: view
        anchors.fill: parent
        profile: otr
        settings.javascriptCanAccessClipboard: true
        onLoadingChanged: function (info) {
            if (info.status === WebEngineView.LoadSucceededStatus) { win.status = "LoadSucceeded"; settle.restart(); }
            else if (info.status === WebEngineView.LoadFailedStatus) { win.status = "LoadFailed:" + info.errorString + ":" + info.errorCode; settle.restart(); }
        }
        onRenderProcessTerminated: function (s, code) { win.status = "RenderTerminated:" + code; settle.restart(); }
        onNewWindowRequested: function (r) { r.action = WebEngineNewWindowRequest.IgnoreRequest }
        onCertificateError: function (e) { e.rejectCertificate() }
    }
}
