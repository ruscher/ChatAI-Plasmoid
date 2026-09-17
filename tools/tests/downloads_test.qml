import QtQuick
import "../../contents/ui/Downloads.js" as Downloads

// Unit tests for the pure download bookkeeping (run with tools/tests/run-unit-tests.sh).
Item {
    property int failures: 0
    function check(name, cond) { console.log((cond ? "PASS " : "FAIL ") + name); if (!cond) failures++; }
    function near(a, b) { return Math.abs(a - b) < 0.001; }

    Component.onCompleted: {
        const D = Downloads;
        // Weighted progress: 900 MB/1 GB + 100 MB/3 GB -> 1000/4000 = 25 %, not (90 % + 3 %) / 2
        let s = D.summarize([
            { state: D.StateInProgress, receivedBytes: 900e6, totalBytes: 1000e6, seen: false, isPaused: false },
            { state: D.StateInProgress, receivedBytes: 100e6, totalBytes: 3000e6, seen: false, isPaused: false }
        ]);
        check("weighted progress by bytes (25 %)", near(s.progress, 0.25));
        check("two active", s.active === 2 && s.showIndicator && !s.hasUnknownSize);

        // Unknown size only -> indeterminate
        s = D.summarize([{ state: D.StateInProgress, receivedBytes: 5e6, totalBytes: 0, seen: false, isPaused: false }]);
        check("unknown size -> progress -1 and hasUnknownSize", s.progress === -1 && s.hasUnknownSize && s.showIndicator);

        // Hybrid: known + unknown -> ratio over known, flag set
        s = D.summarize([
            { state: D.StateInProgress, receivedBytes: 50, totalBytes: 100, seen: false, isPaused: false },
            { state: D.StateInProgress, receivedBytes: 5e6, totalBytes: 0, seen: false, isPaused: false }
        ]);
        check("hybrid -> 50 % over known, hasUnknownSize", near(s.progress, 0.5) && s.hasUnknownSize);

        // Paused counts as active
        s = D.summarize([{ state: D.StateInProgress, receivedBytes: 1, totalBytes: 2, seen: false, isPaused: true }]);
        check("paused is active", s.active === 1 && s.paused === 1);

        // Visibility rule: unseen completed keeps the indicator, seen ones do not
        s = D.summarize([
            { state: D.StateCompleted, receivedBytes: 10, totalBytes: 10, seen: true },
            { state: D.StateCompleted, receivedBytes: 10, totalBytes: 10, seen: false },
            { state: D.StateCompleted, receivedBytes: 10, totalBytes: 10, seen: true }
        ]);
        check("A seen, B unseen, C seen -> indicator visible, attention 1", s.showIndicator && s.attention === 1 && s.active === 0 && s.progress === 0);
        s = D.summarize([
            { state: D.StateCompleted, receivedBytes: 10, totalBytes: 10, seen: true },
            { state: D.StateCancelled, receivedBytes: 1, totalBytes: 10, seen: false }
        ]);
        check("all seen/cancelled -> indicator hidden", !s.showIndicator && s.attention === 0);
        s = D.summarize([{ state: D.StateInterrupted, receivedBytes: 1, totalBytes: 10, seen: false }]);
        check("unacknowledged error keeps indicator", s.showIndicator && s.failedUnseen === 1);
        check("empty list -> hidden", !D.summarize([]).showIndicator);
        check("received capped at total", near(D.summarize([{ state: D.StateInProgress, receivedBytes: 200, totalBytes: 100, seen: false }]).progress, 1));

        // Speed & ETA reliability
        let samples = [];
        samples = D.pushSample(samples, 0, 0);
        samples = D.pushSample(samples, 1000, 1e6);
        check("speed unreliable under 2 s window", D.speedFromSamples(samples) === -1);
        samples = D.pushSample(samples, 3000, 3e6);
        check("speed 1 MB/s over 3 s", near(D.speedFromSamples(samples) / 1e6, 1));
        check("eta 7 s for 7 MB remaining", near(D.etaSeconds(3e6, 10e6, 1e6), 7));
        check("eta -1 when total unknown", D.etaSeconds(3e6, 0, 1e6) === -1);
        check("eta -1 when speed unknown", D.etaSeconds(3e6, 10e6, -1) === -1);
        check("no progress -> speed -1", D.speedFromSamples([{ time: 0, bytes: 5 }, { time: 5000, bytes: 5 }]) === -1);
        // Window trimming keeps recent samples
        let many = [];
        for (let t = 0; t <= 30000; t += 1000) many = D.pushSample(many, t, t, 10000);
        check("samples trimmed to window", many.length <= 12 && many[0].time >= 20000);

        // Byte scaling
        check("scaleBytes 2.4 MB", D.scaleBytes(2.4e6).unitIndex === 2 && near(D.scaleBytes(2.4e6).value, 2.4));
        check("scaleBytes 512 B", D.scaleBytes(512).unitIndex === 0 && D.scaleBytes(512).digits === 0);
        check("scaleBytes 1.8 GB", D.scaleBytes(1.8e9).unitIndex === 3);

        // Icons
        check("icon pdf", D.iconForFileName("report.PDF") === "application-pdf");
        check("icon unknown", D.iconForFileName("blob") === "application-octet-stream");
        check("state helpers", D.isActive(D.StateRequested) && D.isFinished(D.StateInterrupted) && !D.isFinished(D.StateInProgress));

        console.log(failures === 0 ? "ALL PASS" : failures + " FAILURES");
        Qt.quit();
    }
}
