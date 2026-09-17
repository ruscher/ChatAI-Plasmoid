import QtQuick
import "../../contents/ui/Migration.js" as Migration

Item {
    function check(name, cond) { console.log((cond ? "PASS " : "FAIL ") + name); if (!cond) failures++; }
    property int failures: 0
    Component.onCompleted: {
        const legacyMap = { "https://x.com/i/grok": "https://grok.com", "https://duckduckgo.com/chat": "https://duck.ai/chat" };
        // Scenario from docs/12: existing 1.0.0 user
        let c = { configVersion: 0, keepOpen: true, pin: false, hidePrintButton: true, hideAutoHideButton: false,
                  customSites: "A|https://a.example,B|b.example,Bad|ftp://x", customSitesJson: "",
                  notificationsEnabled: true, microphoneEnabled: true, webcamEnabled: false, screenShareEnabled: false, geolocationEnabled: false,
                  notificationsPolicy: 0, microphonePolicy: 0, webcamPolicy: 0, screenSharePolicy: 0, geolocationPolicy: 0,
                  javascriptCanPaste: false, compatibilityUserAgent: false, url: "https://x.com/i/grok", lastFavIcon: "https://x.com/favicon.ico", dialogWidth: 500 };
        check("runs", Migration.run(c, legacyMap) === true);
        check("pin migrated", c.pin === true);
        check("hideAutoHideButton migrated", c.hideAutoHideButton === true);
        const sites = JSON.parse(c.customSitesJson);
        check("custom sites json (2 valid, 'b.example' w/o scheme dropped)", sites.length === 1 && sites[0].name === "A" && sites[0].url === "https://a.example");
        check("legacy customSites cleared", c.customSites === "");
        check("mic -> allow", c.microphonePolicy === 1);
        check("notifications true -> ask", c.notificationsPolicy === 0);
        check("webcam false -> ask", c.webcamPolicy === 0);
        check("javascriptCanPaste preserved", c.javascriptCanPaste === true);
        check("compat UA preserved", c.compatibilityUserAgent === true);
        check("url grok migrated", c.url === "https://grok.com");
        check("configVersion", c.configVersion === 1);
        check("idempotent", Migration.run(c, legacyMap) === false);

        // Fresh install: nothing changes except version
        let f = { configVersion: 0, keepOpen: false, pin: false, hidePrintButton: false, customSites: "", customSitesJson: "",
                  notificationsEnabled: true, microphoneEnabled: false, webcamEnabled: false, screenShareEnabled: false, geolocationEnabled: false,
                  notificationsPolicy: 0, microphonePolicy: 0, javascriptCanPaste: false, compatibilityUserAgent: false,
                  url: "https://duck.ai/chat", lastFavIcon: "", dialogWidth: 0 };
        Migration.run(f, legacyMap);
        check("fresh: paste stays false", f.javascriptCanPaste === false);
        check("fresh: compat UA stays false", f.compatibilityUserAgent === false);
        check("fresh: url unchanged", f.url === "https://duck.ai/chat");
        // Existing user who disabled notifications
        let n = { configVersion: 0, notificationsEnabled: false, notificationsPolicy: 0, url: "https://chatgpt.com", lastFavIcon: "x", customSites: "", customSitesJson: "" };
        Migration.run(n, legacyMap);
        check("notifications false -> block", n.notificationsPolicy === 2);
        check("ddg legacy url", (function(){ let d={configVersion:0,url:"https://duckduckgo.com/chat?x=1",customSites:"",customSitesJson:""}; Migration.run(d, legacyMap); return d.url==="https://duck.ai/chat"; })());
        console.log(failures === 0 ? "ALL PASS" : failures + " FAILURES");
        Qt.quit();
    }
}
