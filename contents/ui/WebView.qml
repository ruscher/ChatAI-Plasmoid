/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtCore
import QtQuick
import QtQuick.Layouts
import QtWebEngine

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification

/*
 * Web engine host: profile, navigation, permissions, downloads, zoom,
 * fullscreen and lifecycle. Created lazily by the Loader in main.qml and
 * destroyed by Close to release the Chromium processes.
 */
Item {
    id: webViewRoot

    required property QtObject providerModel

    // Set by main.qml: true while the popup is collapsed or the settings
    // panel covers the view. Drives visibility and lifecycle freezing.
    property bool hidden: false

    readonly property alias webview: webview
    readonly property alias downloads: downloadsModel
    readonly property string effectiveProfileName: String(plasmoid.configuration.webEngineProfileName || "").replace(/[^A-Za-z0-9._-]/g, "-").slice(0, 64) || providerModel.defaultProfileName
    property var webProfile: null

    property bool hasLoadError: false
    property string loadErrorDetails: ""
    property bool findBarVisible: false

    // Permissions
    property var pendingPermission: null
    property var permissionQueue: []
    property int permissionsRevision: 0

    // State exposed to the header and menus
    property bool clearingCache: false
    readonly property bool devToolsOpen: devToolsLoader.active
    readonly property bool fullScreenActive: fullScreenLoader.item ? fullScreenLoader.item.active : false
    readonly property bool loading: webview.loading
    readonly property bool canGoBack: webview.canGoBack
    readonly property bool canGoForward: webview.canGoForward
    readonly property int zoomPercent: Math.round(webview.zoomFactor * 100)
    readonly property var zoomSteps: [0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0]
    readonly property string currentTitle: webview.title
    readonly property string currentUrl: String(webview.url || "")
    readonly property int renderProcessPid: webview.renderProcessPid
    readonly property int lifecycleState: webview.lifecycleState
    readonly property int recommendedState: webview.recommendedState

    // Downloads summary for the header badge
    property int downloadsRevision: 0
    readonly property int activeDownloadCount: countActiveDownloads(downloadsRevision)
    readonly property real activeDownloadProgress: averageDownloadProgress(downloadsRevision)
    property var downloadCache: ({})

    // Anything that must not be interrupted by freezing the page.
    readonly property bool busy: webview.loading || webview.recentlyAudible || activeDownloadCount > 0
        || pendingPermission !== null || devToolsOpen || clearingCache || fullScreenActive

    readonly property var currentProvider: providerModel.providerForUrl(plasmoid.configuration.url)

    readonly property int policyAsk: 0
    readonly property int policyAllow: 1
    readonly property int policyBlock: 2

    Layout.fillWidth: true
    Layout.fillHeight: true

    Component.onCompleted: {
        // Prototype instances must be created after the component is ready;
        // creating them inside a binding crashes QQuickWebEngineView::setProfile.
        const profile = profilePrototype.instance();
        configureProfile(profile);
        webProfile = profile;
        applyZoom();
    }

    Connections {
        target: plasmoid.configuration

        function onUrlChanged() {
            webViewRoot.configureProfile();
            webViewRoot.hasLoadError = false;
            // Do not carry the previous provider's icon over; the new one
            // arrives through WebEngineView.icon.
            plasmoid.configuration.favIcon = "";
        }
        function onDownloadPathChanged() { webViewRoot.configureProfile(); }
        function onCustomUserAgentChanged() { webViewRoot.configureProfile(); }
        function onCompatibilityUserAgentChanged() { webViewRoot.configureProfile(); }
        function onZoomFactorChanged() { webViewRoot.applyZoom(); }
    }

    // ---- helpers -----------------------------------------------------------

    function isHttpUrl(value) {
        return providerModel.isHttpUrl(value);
    }

    function localPath(value) {
        let path = String(value || "").trim();
        if (path.indexOf("file://") === 0)
            path = path.replace(/^file:\/\/(localhost)?/, "");
        return path || String(StandardPaths.writableLocation(StandardPaths.DownloadLocation)).replace(/^file:\/\/(localhost)?/, "");
    }

    function downloadDirectory() {
        const path = localPath(plasmoid.configuration.downloadPath);
        return path.charAt(0) === "/" ? path : localPath("");
    }

    function safeFileName(value, fallback) {
        let name = String(value || fallback || "download").split(/[\\/]/).pop();
        // Strip control characters, path separators and reserved characters.
        name = name.replace(/[\x00-\x1f\x7f<>:"|?*]/g, "_").replace(/\.\./g, "_").trim();
        if (name === "." || name === "..")
            name = fallback || "download";
        return name || fallback || "download";
    }

    function configureProfile(profileOverride) {
        const profile = profileOverride || webProfile;
        if (!profile)
            return;
        profile.httpUserAgent = providerModel.effectiveUserAgent(WebEngine.defaultProfile.httpUserAgent, currentProvider);
        profile.downloadPath = downloadDirectory();
    }

    // ---- navigation API used by Header / menu ------------------------------

    function goHome() {
        const provider = currentProvider;
        const url = provider ? provider.url : plasmoid.configuration.url;
        if (!isHttpUrl(url)) {
            loadErrorDetails = i18n("The configured address is not a valid HTTP or HTTPS URL.");
            hasLoadError = true;
            return;
        }
        hasLoadError = false;
        webview.url = url;
    }

    function goBack() { if (webview.canGoBack) webview.goBack(); }
    function goForward() { if (webview.canGoForward) webview.goForward(); }
    function reload() { hasLoadError = false; webview.reload(); }
    function reloadBypassCache() { hasLoadError = false; webview.reloadAndBypassCache(); }
    function stop() { webview.stop(); }
    function toggleFind() { findBarVisible = !findBarVisible; }

    function openExternally() {
        if (isHttpUrl(currentUrl))
            Qt.openUrlExternally(currentUrl);
    }

    function copyUrl() {
        clipboardHelper.text = currentUrl;
        clipboardHelper.selectAll();
        clipboardHelper.copy();
        clipboardHelper.text = "";
    }

    // ---- zoom --------------------------------------------------------------

    function applyZoom() {
        const factor = Math.min(5.0, Math.max(0.25, Number(plasmoid.configuration.zoomFactor) || 1.0));
        if (Math.abs(webview.zoomFactor - factor) > 0.001)
            webview.zoomFactor = factor;
    }

    function setZoom(factor) {
        plasmoid.configuration.zoomFactor = Math.min(5.0, Math.max(0.25, factor));
        applyZoom();
    }

    function zoomIn() {
        const current = webview.zoomFactor;
        const next = zoomSteps.find(step => step > current + 0.001);
        setZoom(next !== undefined ? next : Math.min(5.0, current + 0.25));
    }

    function zoomOut() {
        const current = webview.zoomFactor;
        const lower = zoomSteps.filter(step => step < current - 0.001);
        setZoom(lower.length ? lower[lower.length - 1] : Math.max(0.25, current - 0.25));
    }

    function zoomReset() { setZoom(1.0); }

    // ---- fullscreen --------------------------------------------------------

    function enterFullScreen() {
        fullScreenLoader.active = true;
        fullScreenLoader.item.enter(webview);
    }

    function exitFullScreen() {
        if (fullScreenLoader.item)
            fullScreenLoader.item.leave();
        if (webview.isFullScreen)
            webview.fullScreenCancelled();
        fullScreenLoader.active = false;
    }

    function toggleFullScreen() {
        if (fullScreenActive)
            exitFullScreen();
        else
            enterFullScreen();
    }

    // ---- devtools ----------------------------------------------------------

    function openDevTools() {
        devToolsLoader.active = true;
        devToolsLoader.item.show();
        devToolsLoader.item.requestActivate();
    }

    function closeDevTools() {
        devToolsLoader.active = false;
    }

    // ---- cache & permissions management -----------------------------------

    function clearHttpCache() {
        if (!webProfile || clearingCache)
            return;
        clearingCache = true;
        webProfile.clearHttpCache();
    }

    function listPermissions() {
        return webProfile ? webProfile.listAllPermissions() : [];
    }

    function resetPermission(permission) {
        if (permission)
            permission.reset();
        permissionsRevision++;
    }

    function resetAllPermissions() {
        listPermissions().forEach(permission => permission.reset());
        permissionsRevision++;
    }

    // ---- lifecycle (docs/09) ----------------------------------------------

    onHiddenChanged: {
        if (!hidden) {
            freezeTimer.stop();
            discardTimer.stop();
            // A visible page must be Active: order matters.
            webview.lifecycleState = WebEngineView.LifecycleState.Active;
            webview.visible = true;
        } else {
            webview.visible = false;
            if (plasmoid.configuration.freezeWhenHidden)
                freezeTimer.restart();
            if (plasmoid.configuration.discardAfterMinutes > 0)
                discardTimer.restart();
        }
    }

    function tryFreeze() {
        if (!hidden || !plasmoid.configuration.freezeWhenHidden)
            return;
        if (busy || webview.recommendedState === WebEngineView.LifecycleState.Active) {
            // The engine still recommends Active (audio, upload, form work…): retry later.
            freezeTimer.restart();
            return;
        }
        if (webview.lifecycleState === WebEngineView.LifecycleState.Active)
            webview.lifecycleState = WebEngineView.LifecycleState.Frozen;
    }

    Timer {
        id: freezeTimer
        interval: 30 * 1000
        onTriggered: webViewRoot.tryFreeze()
    }

    Timer {
        id: discardTimer
        interval: Math.max(1, plasmoid.configuration.discardAfterMinutes) * 60 * 1000
        onTriggered: {
            if (!webViewRoot.hidden || webViewRoot.busy || webview.lifecycleState === WebEngineView.LifecycleState.Discarded)
                return;
            if (webview.recommendedState !== WebEngineView.LifecycleState.Active)
                webview.lifecycleState = WebEngineView.LifecycleState.Discarded;
        }
    }

    // ---- downloads ---------------------------------------------------------

    function countActiveDownloads() {
        let count = 0;
        for (let i = 0; i < downloadsModel.count; i++) {
            const item = downloadsModel.get(i);
            if (item.state === WebEngineDownloadRequest.DownloadInProgress || item.state === WebEngineDownloadRequest.DownloadRequested)
                count++;
        }
        return count;
    }

    function averageDownloadProgress() {
        let total = 0;
        let count = 0;
        for (let i = 0; i < downloadsModel.count; i++) {
            const item = downloadsModel.get(i);
            if (item.state === WebEngineDownloadRequest.DownloadInProgress) {
                total += item.progress;
                count++;
            }
        }
        return count ? total / count : 0;
    }

    ListModel {
        id: downloadsModel

        function addDownload(downloadItem, fileName, path, isPdf) {
            const downloadId = downloadItem ? String(downloadItem.id) : "pdf-" + Date.now().toString();
            append({
                "downloadId": downloadId,
                "fileName": fileName,
                "fullPath": path,
                "progress": 0,
                "receivedBytes": 0,
                "totalBytes": downloadItem && downloadItem.totalBytes > 0 ? downloadItem.totalBytes : 0,
                "isPdfExport": isPdf,
                "state": downloadItem ? downloadItem.state : WebEngineDownloadRequest.DownloadInProgress,
                "isPaused": downloadItem ? downloadItem.isPaused : false,
                "error": ""
            });
            webViewRoot.downloadsRevision++;
            return count - 1;
        }

        function removeDownload(index) {
            const item = get(index);
            if (item && item.downloadId)
                delete webViewRoot.downloadCache[item.downloadId];
            remove(index);
            webViewRoot.downloadsRevision++;
        }

        function clearFinished() {
            for (let i = count - 1; i >= 0; i--) {
                const state = get(i).state;
                if (state !== WebEngineDownloadRequest.DownloadInProgress && state !== WebEngineDownloadRequest.DownloadRequested)
                    removeDownload(i);
            }
        }
    }

    function downloadIndex(downloadId) {
        const id = String(downloadId || "");
        for (let i = 0; i < downloadsModel.count; i++) {
            if (String(downloadsModel.get(i).downloadId) === id)
                return i;
        }
        return -1;
    }

    function updateDownload(download) {
        if (!download)
            return;
        const index = downloadIndex(download.id);
        if (index < 0)
            return;
        const total = download.totalBytes > 0 ? download.totalBytes : 0;
        const progress = total > 0 ? Math.min(1, download.receivedBytes / total) : 0;
        downloadsModel.setProperty(index, "state", download.state);
        downloadsModel.setProperty(index, "receivedBytes", download.receivedBytes);
        downloadsModel.setProperty(index, "totalBytes", total);
        downloadsModel.setProperty(index, "progress", download.state === WebEngineDownloadRequest.DownloadCompleted ? 1 : progress);
        downloadsModel.setProperty(index, "isPaused", download.isPaused);
        downloadsModel.setProperty(index, "error", download.interruptReasonString || "");
        downloadsRevision++;
    }

    function downloadEntry(downloadId) {
        return downloadCache[String(downloadId || "")] || null;
    }

    function cancelDownload(downloadId) {
        const entry = downloadEntry(downloadId);
        if (entry)
            entry.download.cancel();
    }

    function pauseDownload(downloadId) {
        const entry = downloadEntry(downloadId);
        if (entry)
            entry.download.pause();
    }

    function resumeDownload(downloadId) {
        const entry = downloadEntry(downloadId);
        if (entry)
            entry.download.resume();
    }

    function clearFinishedDownloads() {
        downloadsModel.clearFinished();
    }

    function printPage() {
        webview.runJavaScript("document.title", function (title) {
            const directory = webViewRoot.downloadDirectory();
            const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
            const safeName = webViewRoot.safeFileName(title, "ChatAI").replace(/[^a-z0-9._-]/gi, "-").toLowerCase();
            const filename = `${directory}/${safeName}-${timestamp}.pdf`;
            downloadsModel.addDownload(null, `${safeName}-${timestamp}.pdf`, filename, true);
            webview.printToPdf(filename, WebEngineView.A4, WebEngineView.Portrait);
        });
    }

    function saveMHTML() {
        webview.triggerWebAction(WebEngineView.SavePage);
    }

    // ---- notifications -----------------------------------------------------

    Notification {
        id: webNotification
        // Standard Plasma event: no per-applet .notifyrc required.
        componentName: "plasma_workspace"
        eventId: "notification"
        iconName: "dialog-information"
    }

    function showNotification(title, message, icon) {
        webNotification.title = title || i18n("ChatAI");
        webNotification.text = message;
        webNotification.iconName = icon || "dialog-information";
        webNotification.sendEvent();
    }

    // ---- permissions (docs/07) --------------------------------------------

    function combinePolicies(a, b) {
        if (a === policyBlock || b === policyBlock)
            return policyBlock;
        if (a === policyAllow && b === policyAllow)
            return policyAllow;
        return policyAsk;
    }

    function policyForPermission(type) {
        const config = plasmoid.configuration;
        switch (type) {
        case WebEnginePermission.PermissionType.Notifications:
            return config.notificationsPolicy;
        case WebEnginePermission.PermissionType.MediaAudioCapture:
            return config.microphonePolicy;
        case WebEnginePermission.PermissionType.MediaVideoCapture:
            return config.webcamPolicy;
        case WebEnginePermission.PermissionType.MediaAudioVideoCapture:
            return combinePolicies(config.microphonePolicy, config.webcamPolicy);
        case WebEnginePermission.PermissionType.DesktopVideoCapture:
        case WebEnginePermission.PermissionType.DesktopAudioVideoCapture:
            return config.screenSharePolicy;
        case WebEnginePermission.PermissionType.Geolocation:
            return config.geolocationPolicy;
        case WebEnginePermission.PermissionType.ClipboardReadWrite:
            return config.clipboardPolicy;
        default:
            // MouseLock, LocalFontsAccess, Unsupported and anything newer.
            return policyBlock;
        }
    }

    function handlePermission(permission) {
        const policy = policyForPermission(permission.permissionType);
        if (policy === policyAllow) {
            permission.grant();
        } else if (policy === policyAsk) {
            if (pendingPermission === null)
                pendingPermission = permission;
            else
                permissionQueue.push(permission);
        } else {
            permission.deny();
        }
    }

    function resolvePendingPermission(grant) {
        const permission = pendingPermission;
        pendingPermission = null;
        if (permission) {
            if (grant)
                permission.grant();
            else
                permission.deny();
            permissionsRevision++;
        }
        if (permissionQueue.length)
            pendingPermission = permissionQueue.shift();
    }

    // ---- profile -----------------------------------------------------------

    WebEngineProfilePrototype {
        id: profilePrototype

        storageName: webViewRoot.effectiveProfileName
        httpCacheType: WebEngineProfile.DiskHttpCache
        httpCacheMaximumSize: Math.max(0, plasmoid.configuration.httpCacheMaximumSize) * 1024 * 1024
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        persistentPermissionsPolicy: WebEngineProfile.StoreOnDisk
    }

    Connections {
        target: webViewRoot.webProfile

        function onPresentNotification(notification) {
            webViewRoot.showNotification(notification.title, notification.message);
            notification.show();
        }

        function onClearHttpCacheCompleted() {
            webViewRoot.clearingCache = false;
        }

        function onDownloadRequested(download) {
            const directory = webViewRoot.downloadDirectory();
            const fileName = webViewRoot.safeFileName(download.downloadFileName, "download");

            for (let i = 0; i < downloadsModel.count; i++) {
                const current = downloadsModel.get(i);
                if (current.state === WebEngineDownloadRequest.DownloadInProgress && current.fileName === fileName && !current.isPdfExport) {
                    webViewRoot.showNotification(i18n("Download in progress"), i18n("The file '%1' is already being downloaded", fileName), "dialog-warning");
                    download.cancel();
                    return;
                }
            }

            download.downloadDirectory = directory;
            download.downloadFileName = fileName;
            downloadsModel.addDownload(download, fileName, directory + "/" + fileName, false);

            const updateConnection = function () { webViewRoot.updateDownload(download); };
            download.receivedBytesChanged.connect(updateConnection);
            download.totalBytesChanged.connect(updateConnection);
            download.stateChanged.connect(updateConnection);
            download.isPausedChanged.connect(updateConnection);
            webViewRoot.downloadCache[String(download.id)] = { download: download, updateConnection: updateConnection };
            download.accept();
            webViewRoot.updateDownload(download);
        }

        function onDownloadFinished(download) {
            webViewRoot.updateDownload(download);
            const entry = webViewRoot.downloadCache[String(download.id)];
            if (entry && entry.updateConnection) {
                download.receivedBytesChanged.disconnect(entry.updateConnection);
                download.totalBytesChanged.disconnect(entry.updateConnection);
                download.stateChanged.disconnect(entry.updateConnection);
                download.isPausedChanged.disconnect(entry.updateConnection);
            }
            delete webViewRoot.downloadCache[String(download.id)];
            if (download.state === WebEngineDownloadRequest.DownloadCompleted)
                webViewRoot.showNotification(i18n("Download finished"), download.downloadFileName, "folder-download");
        }
    }

    // ---- the view ----------------------------------------------------------

    WebEngineView {
        id: webview

        anchors.fill: parent
        // Wait for the configured profile before navigating.
        url: webViewRoot.webProfile ? plasmoid.configuration.url : ""
        profile: webViewRoot.webProfile || WebEngine.defaultProfile

        onIconChanged: {
            // Chromium already picked the best icon declared by the page.
            const value = String(icon || "").replace(/^image:\/\/favicon\//, "");
            if (!webViewRoot.isHttpUrl(value))
                return;
            if (plasmoid.configuration.favIcon !== value)
                plasmoid.configuration.favIcon = value;
            if (plasmoid.configuration.lastFavIcon !== value)
                plasmoid.configuration.lastFavIcon = value;
        }

        onLinkHovered: hoveredUrl => {
            const text = String(hoveredUrl || "");
            if (text === "") {
                hideStatusText.start();
            } else {
                statusText.text = text;
                statusBubble.visible = true;
                hideStatusText.stop();
            }
        }

        onContextMenuRequested: request => {
            if (request.isContentEditable || request.selectedText || request.mediaType !== ContextMenuRequest.MediaTypeNone) {
                request.accepted = false;
                return;
            }
            linkContextMenu.link = String(request.linkUrl || "");
            linkContextMenu.open(request.position.x, request.position.y);
            request.accepted = true;
        }

        onPermissionRequested: function (permission) {
            webViewRoot.handlePermission(permission);
        }

        onDesktopMediaRequested: function (request) {
            if (plasmoid.configuration.screenSharePolicy === webViewRoot.policyBlock || request.screensModel.rowCount() === 0)
                request.cancel();
            else
                request.selectScreen(request.screensModel.index(0, 0));
        }

        onLoadingChanged: function (loadingInfo) {
            if (loadingInfo.status === WebEngineView.LoadStartedStatus) {
                webViewRoot.hasLoadError = false;
            } else if (loadingInfo.status === WebEngineView.LoadFailedStatus) {
                webViewRoot.hasLoadError = true;
                webViewRoot.loadErrorDetails = loadingInfo.errorString || i18n("The service did not provide an error description.");
            } else if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                // Chromium keeps zoom per host; re-apply the global preference.
                webViewRoot.applyZoom();
            }
        }

        onPrintRequested: webview.triggerWebAction(WebEngineView.Print)

        onCertificateError: function (error) {
            webViewRoot.hasLoadError = true;
            webViewRoot.loadErrorDetails = error.description || i18n("The site's security certificate is not trusted.");
            error.rejectCertificate();
        }

        onFullScreenRequested: function (request) {
            if (request.toggleOn)
                webViewRoot.enterFullScreen();
            else
                webViewRoot.exitFullScreen();
            request.accept();
        }

        onRenderProcessTerminated: function (terminationStatus, exitCode) {
            webViewRoot.hasLoadError = true;
            webViewRoot.loadErrorDetails = i18n("The web content process stopped unexpectedly (exit code %1).", exitCode);
        }

        onPdfPrintingFinished: function (filePath, success) {
            for (let i = 0; i < downloadsModel.count; i++) {
                if (downloadsModel.get(i).fullPath === filePath) {
                    downloadsModel.setProperty(i, "state", success ? WebEngineDownloadRequest.DownloadCompleted : WebEngineDownloadRequest.DownloadInterrupted);
                    downloadsModel.setProperty(i, "progress", success ? 1 : 0);
                    if (!success)
                        downloadsModel.setProperty(i, "error", i18n("The PDF could not be created."));
                    webViewRoot.downloadsRevision++;
                    break;
                }
            }
        }

        function openExternalIfSafe(url) {
            const target = String(url || "");
            if (!webViewRoot.isHttpUrl(target)) {
                webViewRoot.showNotification(i18n("Blocked navigation"), i18n("Only HTTP and HTTPS links can be opened from ChatAI."), "dialog-warning");
                return false;
            }
            Qt.openUrlExternally(target);
            return true;
        }

        onNewWindowRequested: function (request) {
            const url = String(request.requestedUrl);
            request.action = WebEngineNewWindowRequest.IgnoreRequest;
            if (webViewRoot.providerModel.isAuthUrl(url))
                webview.url = url;
            else
                openExternalIfSafe(url);
        }

        onNavigationRequested: function (request) {
            const requestedUrl = String(request.url);
            if (!webViewRoot.isHttpUrl(requestedUrl)) {
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                return;
            }
            const isLink = request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked;
            if (isLink && request.userInitiated && request.disposition !== WebEngineNavigationRequest.CurrentTabDisposition) {
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                if (webViewRoot.providerModel.isAuthUrl(requestedUrl))
                    webview.url = requestedUrl;
                else
                    openExternalIfSafe(requestedUrl);
            }
        }

        // https://doc.qt.io/qt-6/qml-qtwebengine-webenginesettings.html
        settings {
            spatialNavigationEnabled: plasmoid.configuration.spatialNavigationEnabled
            allowWindowActivationFromJavaScript: true
            javascriptCanAccessClipboard: plasmoid.configuration.javascriptCanAccessClipboard
            javascriptCanOpenWindows: plasmoid.configuration.javascriptCanOpenWindows
            javascriptCanPaste: plasmoid.configuration.javascriptCanPaste
            unknownUrlSchemePolicy: plasmoid.configuration.allowUnknownUrlSchemes ? WebEngineSettings.AllowUnknownUrlSchemesFromUserInteraction : WebEngineSettings.DisallowUnknownUrlSchemes
            playbackRequiresUserGesture: plasmoid.configuration.playbackRequiresUserGesture
            focusOnNavigationEnabled: plasmoid.configuration.focusOnNavigationEnabled
            screenCaptureEnabled: plasmoid.configuration.screenSharePolicy !== webViewRoot.policyBlock
            pluginsEnabled: true
            forceDarkMode: {
                const color = Kirigami.Theme.backgroundColor;
                return (0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) < 0.5;
            }
        }
    }

    // Mouse back/forward buttons
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: mouse => {
            if (mouse.button === Qt.BackButton)
                webViewRoot.goBack();
            else if (mouse.button === Qt.ForwardButton)
                webViewRoot.goForward();
        }
    }

    Shortcut {
        sequence: StandardKey.Find
        onActivated: webViewRoot.findBarVisible = true
    }
    Shortcut {
        sequences: [StandardKey.ZoomIn, "Ctrl+="]
        onActivated: webViewRoot.zoomIn()
    }
    Shortcut {
        sequence: StandardKey.ZoomOut
        onActivated: webViewRoot.zoomOut()
    }
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: webViewRoot.zoomReset()
    }
    Shortcut {
        sequence: "F11"
        onActivated: webViewRoot.toggleFullScreen()
    }

    // Hidden helper used by copyUrl(); TextEdit.copy() uses the system clipboard.
    TextEdit {
        id: clipboardHelper
        visible: false
        width: 0
        height: 0
    }

    ContextMenu {
        id: linkContextMenu
        webviewItem: webview
        onReloadRequested: webViewRoot.reload()
        onSavePdfRequested: webViewRoot.printPage()
        onSaveMhtmlRequested: webViewRoot.saveMHTML()
    }

    Loader {
        id: fullScreenLoader
        active: false
        source: "FullScreenWindow.qml"
        onLoaded: item.exitRequested.connect(webViewRoot.exitFullScreen)
    }

    Loader {
        id: devToolsLoader
        active: false
        source: "DevToolsWindow.qml"
        onLoaded: {
            item.inspected = webview;
            item.closeRequested.connect(webViewRoot.closeDevTools);
        }
    }

    ColumnLayout {
        id: topOverlays
        z: 10
        spacing: 0
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        PlasmaComponents3.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 3 : 0
            visible: webview.loading && webview.loadProgress < 100
            from: 0
            to: 100
            value: webview.loadProgress
        }

        PermissionBar {
            Layout.fillWidth: true
            Layout.margins: active ? Kirigami.Units.smallSpacing : 0
            permission: webViewRoot.pendingPermission
            onGranted: webViewRoot.resolvePendingPermission(true)
            onDenied: webViewRoot.resolvePendingPermission(false)
        }

        FindBar {
            id: findBar
            Layout.fillWidth: true
            findBarVisible: webViewRoot.findBarVisible
            webviewItem: webview
            onCloseRequested: webViewRoot.findBarVisible = false
            onFindBarVisibleChanged: {
                if (findBarVisible)
                    findBar.focusAndSelect();
                else
                    findBar.clearSearch();
            }
        }
    }

    Rectangle {
        id: errorOverlay

        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        opacity: 0.98
        visible: webViewRoot.hasLoadError
        z: 20

        ErrorView {
            anchors.centerIn: parent
            width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 25)
            errorDetails: webViewRoot.loadErrorDetails
            onRetryRequested: webViewRoot.reload()
            onOpenExternallyRequested: {
                if (webViewRoot.isHttpUrl(plasmoid.configuration.url))
                    Qt.openUrlExternally(plasmoid.configuration.url);
            }
        }
    }

    Rectangle {
        id: statusBubble

        readonly property int padding: Kirigami.Units.smallSpacing * 2

        color: Kirigami.Theme.backgroundColor
        visible: false
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: Math.min(statusText.implicitWidth + padding, parent.width)
        height: statusText.implicitHeight + padding
        radius: Kirigami.Units.cornerRadius

        PlasmaComponents3.Label {
            id: statusText
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            elide: Text.ElideMiddle
            verticalAlignment: Text.AlignVCenter

            Timer {
                id: hideStatusText
                interval: 750
                onTriggered: {
                    statusText.text = "";
                    statusBubble.visible = false;
                }
            }
        }
    }

    DownloadBar {
        downloadsModel: downloadsModel
        downloadCache: webViewRoot.downloadCache
        webviewItem: webViewRoot
    }
}
