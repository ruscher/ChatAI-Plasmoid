/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.notification

import Qt.labs.platform

import "."

Item {
    id: webViewRoot
    readonly property string effectiveProfileName: String(plasmoid.configuration.webEngineProfileName || "").replace(/[^A-Za-z0-9._-]/g, "-").slice(0, 64) || "chat-ai"
    property var webProfile: null
    property bool hasLoadError: false
    property string loadErrorDetails: ""

    ProviderModel {
        id: providerCatalog
    }

    Component.onCompleted: {
        // Prototype instances must be created after the QML component is ready.
        // Configure the profile before allowing WebEngineView to navigate.
        const profile = profilePrototype.instance();
        configureProfile(profile);
        webProfile = profile;
    }

    Connections {
        target: plasmoid.configuration

        function onUrlChanged() {
            configureProfile();
            hasLoadError = false;
        }

        function onDownloadPathChanged() {
            configureProfile();
        }
    }

    function isHttpUrl(value) {
        return /^(https?):\/\/[^\s]+$/i.test(String(value || ""));
    }

    function localPath(value) {
        let path = String(value || "").trim();
        if (path.indexOf("file://") === 0)
            path = path.replace(/^file:\/\/(localhost)?/, "");
        return path || String(StandardPaths.writableLocation(StandardPaths.DownloadLocation));
    }

    function downloadDirectory() {
        const path = localPath(plasmoid.configuration.downloadPath);
        return path.charAt(0) === "/" ? path : StandardPaths.writableLocation(StandardPaths.DownloadLocation);
    }

    function safeFileName(value, fallback) {
        let name = String(value || fallback || "download").split(/[\\/]/).pop();
        name = name.replace(/[\u0000-\u001f\u007f<>:"|?*]/g, "_").replace(/\.\./g, "_").trim();
        if (name === "." || name === "..")
            name = fallback || "download";
        return name || fallback || "download";
    }

    function currentUserAgent() {
        const currentUrl = String(plasmoid.configuration.url || "");
        const provider = providerCatalog.providerForUrl(currentUrl);
        return provider && provider.userAgent
            ? provider.userAgent
            : providerCatalog.desktopChromiumUserAgent;
    }

    function configureProfile(profileOverride) {
        const profile = profileOverride || webProfile;
        if (!profile)
            return;
        profile.httpUserAgent = currentUserAgent();
        profile.downloadPath = downloadDirectory();
    }

    function goBackToHomePage() {
        const url = plasmoid.configuration.url;
        if (!isHttpUrl(url)) {
            loadErrorDetails = i18n("The configured address is not a valid HTTP or HTTPS URL.");
            hasLoadError = true;
            return;
        }
        hasLoadError = false;
        webview.url = url;
    }

    function goBack() {
        if (webview) webview.goBack();
    }

    function goForward() {
        if (webview) webview.goForward();
    }

    function reloadPage() {
        if (webview) webview.reloadAndBypassCache();
    }

    function printPage() {
        webview.runJavaScript("document.title", function (title) {
            const directory = downloadDirectory();
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            let safeName = safeFileName(title, "ChatAI").replace(/[^a-z0-9._-]/gi, '-').toLowerCase();
            let filename = `${directory}/${safeName}-${timestamp}.pdf`;

            webview.downloads.addDownload(null, `${safeName}-${timestamp}.pdf`, filename, true);

            webview.printToPdf(filename, WebEngineView.A4, WebEngineView.Portrait);
        });
    }

    function saveMHTML() {
        webview.triggerWebAction(WebEngineView.SavePage);
    }

    Notification {
        id: webNotification
        componentName: "chatai_plasmoid"
        eventId: "notification"
        title: i18n("ChatAI")
        iconName: "dialog-information"
    }

    function showNotification(title, message, icon = "dialog-information") {
        webNotification.title = title || i18n("ChatAI");
        webNotification.text = message;
        webNotification.iconName = icon;
        webNotification.sendEvent();
    }

    function getOpenPath(path) {
        return localPath(path);
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    property bool findBarVisible: false

    Shortcut {
        sequence: StandardKey.Find
        onActivated: findBarVisible = true
    }

    ContextMenu {
        id: linkContextMenu
        webviewItem: webview
        onReloadRequested: reloadPage()
        onSavePdfRequested: printPage()
        onSaveMhtmlRequested: saveMHTML()
    }

    WebEngineProfilePrototype {
        id: profilePrototype

        storageName: webViewRoot.effectiveProfileName
        httpCacheType: WebEngineProfile.DiskHttpCache
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        persistentPermissionsPolicy: WebEngineProfile.AskEveryTime
    }

    WebEngineView {
        id: webview

        property var downloadCache: ({})

        property var downloads: ListModel {
            function addDownload(downloadItem, fileName, path, isPdf) {
                let downloadId = downloadItem ? String(downloadItem.id) : "pdf-" + Date.now().toString();
                let download = {
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
                };

                if (downloadItem)
                    webview.downloadCache[downloadId] = downloadItem;

                this.append(download);
                return this.count - 1;
            }

            function removeDownload(index) {
                let item = this.get(index);
                if (item && item.downloadId) {
                    delete webview.downloadCache[item.downloadId];
                }
                this.remove(index);
            }
        }

        function downloadIndex(downloadId) {
            const id = String(downloadId || "");
            for (let i = 0; i < downloads.count; i++) {
                if (String(downloads.get(i).downloadId) === id)
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
            downloads.setProperty(index, "state", download.state);
            downloads.setProperty(index, "receivedBytes", download.receivedBytes);
            downloads.setProperty(index, "totalBytes", total);
            downloads.setProperty(index, "progress", download.state === WebEngineDownloadRequest.DownloadCompleted ? 1 : progress);
            downloads.setProperty(index, "isPaused", download.isPaused);
            downloads.setProperty(index, "error", download.interruptReasonString || "");
        }

        function cancelDownload(downloadId) {
            const download = downloadCache[String(downloadId || "")];
            if (download)
                download.cancel();
        }

        function pauseDownload(downloadId) {
            const download = downloadCache[String(downloadId || "")];
            if (download)
                download.pause();
        }

        function resumeDownload(downloadId) {
            const download = downloadCache[String(downloadId || "")];
            if (download)
                download.resume();
        }

        function checkAndUpdateFavicon() {
            // Use the last known favicon while loading the new one
            if (Plasmoid.configuration.lastFavIcon)
                Plasmoid.configuration.favIcon = Plasmoid.configuration.lastFavIcon;

            // Parse page HTML for favicon information
            webview.runJavaScript(`
                function findFaviconInHTML() {
                    const icons = [];
                    // 1. Search meta tags first
                    const metas = document.getElementsByTagName('meta');
                    for (let i = 0; i < metas.length; i++) {
                        const property = metas[i].getAttribute('property');
                        if (property === 'og:image') {
                            const content = metas[i].getAttribute('content');
                            if (content) icons.push({ href: content, size: 64 });
                        }
                    }

                    // 2. Search for link tags
                    const links = document.getElementsByTagName('link');
                    for (let i = 0; i < links.length; i++) {
                        const rel = links[i].getAttribute('rel');
                        if (rel && (rel.includes('icon') || rel.includes('shortcut'))) {
                            const href = links[i].getAttribute('href');
                            const sizes = links[i].getAttribute('sizes');
                            if (href) {
                                icons.push({
                                    href: href,
                                    size: sizes ? parseInt(sizes.split('x')[0]) : 32
                                });
                            }
                        }
                    }

                    // 3. Check for default favicon.ico
                    if (icons.length === 0) {
                        icons.push({ href: '/favicon.ico', size: 32 });
                    }

                    // Sort by size
                    icons.sort((a, b) => b.size - a.size);

                    // Get the best icon
                    const bestIcon = icons[0];
                    if (!bestIcon) return null;

                    // Convert to absolute URL
                    const absoluteUrl = bestIcon.href.startsWith('http')
                        ? bestIcon.href
                        : new URL(bestIcon.href, window.location.origin).href;

                    return absoluteUrl;
                }
                findFaviconInHTML();
            `, function (result) {
                if (result) {
                    // Process WebEngine favicon result
                    if (result.startsWith('image://favicon/'))
                        result = result.replace('image://favicon/', '');

                    Plasmoid.configuration.favIcon = result;
                    Plasmoid.configuration.lastFavIcon = result;
                } else if (icon && icon.toString()) {
                    // Use WebEngine icon as fallback
                    let webEngineIcon = icon.toString();
                    if (webEngineIcon.startsWith('image://favicon/'))
                        webEngineIcon = webEngineIcon.replace('image://favicon/', '');

                    Plasmoid.configuration.favIcon = webEngineIcon;
                    Plasmoid.configuration.lastFavIcon = webEngineIcon;
                }
            });
        }

        anchors.fill: parent
        // Do not start with the default profile: providers such as ChatGPT and
        // DeepSeek reject the QtWebEngine identity before the custom profile is ready.
        url: webViewRoot.webProfile ? plasmoid.configuration.url : ""
        profile: webViewRoot.webProfile || WebEngine.defaultProfile
        onLinkHovered: hoveredUrl => {
            if (hoveredUrl == "") {
                hideStatusText.start();
            } else {
                statusText.text = hoveredUrl;
                statusBubble.visible = true;
                hideStatusText.stop();
            }
            if (hoveredUrl.toString() !== "")
                mouseArea.cursorShape = Qt.PointingHandCursor;
            else
                mouseArea.cursorShape = Qt.ArrowCursor;
        }
        onContextMenuRequested: request => {
            // Use default menu for special elements (text fields, selection, etc)
            if (request.isContentEditable || request.selectedText || request.mediaType !== ContextMenuRequest.MediaTypeNone) {
                request.accepted = false;  // Allow default menu to appear
                return;
            }

            // Update link only if there is a URL
            let hasLink = request.linkUrl.toString() !== "";
            linkContextMenu.link = hasLink ? request.linkUrl.toString() : "";

            // Always show our custom menu when it's not a special element
            linkContextMenu.open(request.position.x, request.position.y);
            request.accepted = true;
        }

        onPermissionRequested: function (permission) {
            let allowed = false;
            switch (permission.permissionType) {
            case WebEnginePermission.Notifications:
                allowed = Boolean(plasmoid.configuration.notificationsEnabled);
                break;
            case WebEnginePermission.Geolocation:
                allowed = Boolean(plasmoid.configuration.geolocationEnabled);
                break;
            case WebEnginePermission.MediaAudioCapture:
                allowed = Boolean(plasmoid.configuration.microphoneEnabled);
                break;
            case WebEnginePermission.MediaVideoCapture:
                allowed = Boolean(plasmoid.configuration.webcamEnabled);
                break;
            case WebEnginePermission.DesktopAudioVideoCapture:
                allowed = Boolean(plasmoid.configuration.screenShareEnabled);
                break;
            default:
                allowed = false;
                break;
            }
            if (allowed)
                permission.grant();
            else
                permission.deny();
        }
        onLoadingChanged: function (loadingInfo) {
            if (loadingInfo.status === WebEngineView.LoadStartedStatus)
                hasLoadError = false;
            else if (loadingInfo.status === WebEngineView.LoadFailedStatus) {
                hasLoadError = true;
                loadErrorDetails = loadingInfo.errorString || i18n("The service did not provide an error description.");
            }

            if (loadingInfo.status === WebEngineView.LoadSucceededStatus) {
                checkAndUpdateFavicon();
            }
        }

        onPrintRequested: function () {
            webview.triggerWebAction(WebEngineView.Print);
        }

        onCertificateError: function (error) {
            hasLoadError = true;
            loadErrorDetails = error.description || i18n("The site's security certificate is not trusted.");
            error.rejectCertificate();
        }

        onFullScreenRequested: function (request) {
            // A plasmoid has no independent browser window to resize safely. Reject
            // page-controlled fullscreen rather than changing the user's desktop.
            request.reject();
        }

        onRenderProcessTerminated: function (terminationStatus, exitCode) {
            hasLoadError = true;
            loadErrorDetails = i18n("The web content process stopped unexpectedly (exit code %1).", exitCode);
        }

        onPdfPrintingFinished: function (filePath, success) {
            // Find the index of the PDF download
            for (let i = 0; i < downloads.count; i++) {
                if (downloads.get(i).fullPath === filePath) {
                    if (success) {
                        downloads.setProperty(i, "state", WebEngineDownloadRequest.DownloadCompleted);
                        downloads.setProperty(i, "progress", 1);
                    } else {
                        downloads.setProperty(i, "state", WebEngineDownloadRequest.DownloadInterrupted);
                        downloads.setProperty(i, "error", i18n("The PDF could not be created."));
                    }
                    break;
                }
            }
        }

        // Helper function to check if it's an authentication URL
        function isAuthUrl(url) {
            return /(^|\/\/)(accounts\.google\.com|appleid\.apple\.com|login\.live\.com|github\.com\/login|instagram\.com\/oauth|facebook\.com\/oidc)(\/|$)/i.test(String(url || ""));
        }

        function openExternalIfSafe(url) {
            const target = String(url || "");
            if (!isHttpUrl(target)) {
                showNotification(i18n("Blocked navigation"), i18n("Only HTTP and HTTPS links can be opened from ChatAI."), "dialog-warning");
                return false;
            }
            Qt.openUrlExternally(target);
            return true;
        }

        // Add these handlers to intercept new windows and tabs
        onNewWindowRequested: function (request) {
            let url = request.requestedUrl.toString();
            if (isAuthUrl(url)) {
                webview.url = url;
                request.action = WebEngineNewWindowRequest.IgnoreRequest;
            } else {
                openExternalIfSafe(url);
                request.action = WebEngineNewWindowRequest.IgnoreRequest;
            }
        }

        // Intercept links that try to open in new tab/window
        onNavigationRequested: function (request) {
            const requestedUrl = request.url.toString();
            if (!isHttpUrl(requestedUrl)) {
                request.action = WebEngineNavigationRequest.IgnoreRequest;
                return;
            }
            if (request.navigationType === WebEngineNavigationRequest.NavigationTypeRedirect || request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked) {

                // If the link has target="_blank" or similar
                if (request.userInitiated && request.disposition !== WebEngineNavigationRequest.CurrentTabDisposition) {
                    let url = request.url.toString();
                    if (isAuthUrl(url)) {
                        webview.url = url;
                        request.action = WebEngineNavigationRequest.IgnoreRequest;
                    } else {
                        openExternalIfSafe(url);
                        request.action = WebEngineNavigationRequest.IgnoreRequest;
                    }
                }
            }
        }

        Connections {
            target: webViewRoot.webProfile

            function onPresentNotification(notification) {
                if (plasmoid.configuration.notificationsEnabled) {
                    showNotification(notification.title, notification.message);
                    notification.show();
                }
            }

            function onDownloadRequested(download) {
                const directory = webViewRoot.downloadDirectory();
                const fileName = webViewRoot.safeFileName(download.downloadFileName, "download");

                for (let i = 0; i < downloads.count; i++) {
                    const currentDownload = downloads.get(i);
                    if (currentDownload.state === WebEngineDownloadRequest.DownloadInProgress && currentDownload.fileName === fileName && !currentDownload.isPdfExport) {
                        showNotification(i18n("Download in progress"), i18n("The file '%1' is already being downloaded", fileName), "dialog-warning");
                        download.cancel();
                        return;
                    }
                }

                download.downloadDirectory = directory;
                download.downloadFileName = fileName;
                downloads.addDownload(download, fileName, directory + "/" + fileName, false);

                const downloadId = String(download.id);
                const updateConnection = function () { webview.updateDownload(download); };
                download.receivedBytesChanged.connect(updateConnection);
                download.totalBytesChanged.connect(updateConnection);
                download.stateChanged.connect(updateConnection);
                download.isPausedChanged.connect(updateConnection);
                webview.downloadCache[downloadId] = {
                    download: download,
                    updateConnection: updateConnection
                };
                download.accept();
                webview.updateDownload(download);
            }

            function onDownloadFinished(download) {
                webview.updateDownload(download);
                const downloadId = String(download.id);
                const cached = webview.downloadCache[downloadId];
                if (cached && cached.updateConnection) {
                    download.receivedBytesChanged.disconnect(cached.updateConnection);
                    download.totalBytesChanged.disconnect(cached.updateConnection);
                    download.stateChanged.disconnect(cached.updateConnection);
                    download.isPausedChanged.disconnect(cached.updateConnection);
                }
                delete webview.downloadCache[downloadId];
            }
        }
        // https://doc.qt.io/qt-6/qml-qtwebengine-webenginesettings.html
        settings {
            spatialNavigationEnabled: plasmoid.configuration.spatialNavigationEnabled
            allowWindowActivationFromJavaScript: true
            javascriptCanAccessClipboard: plasmoid.configuration.javascriptCanAccessClipboard
            javascriptCanOpenWindows: plasmoid.configuration.javascriptCanOpenWindows
            javascriptCanPaste: plasmoid.configuration.javascriptCanPaste
            unknownUrlSchemePolicy: plasmoid.configuration.allowUnknownUrlSchemes ? WebEngineSettings.AllowAllUnknownUrlSchemes : WebEngineSettings.DisallowUnknownUrlSchemes
            playbackRequiresUserGesture: plasmoid.configuration.playbackRequiresUserGesture
            focusOnNavigationEnabled: plasmoid.configuration.focusOnNavigationEnabled
            screenCaptureEnabled: plasmoid.configuration.screenShareEnabled
            pluginsEnabled: true
            forceDarkMode: {
                const color = Kirigami.Theme.backgroundColor;
                const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
                return luma < 0.5;
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: mouse => {
            if (mouse.button === Qt.BackButton)
                webview.goBack();
            else if (mouse.button === Qt.ForwardButton)
                webview.goForward();
        }
    }

    PlasmaComponents3.ProgressBar {
        id: loadingProgressBar

        z: 10
        visible: webview.loading && webview.loadProgress < 100
        height: visible ? 3 : 0

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        from: 0
        to: 100
        value: webview.loadProgress

        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
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
            onRetryRequested: {
                webViewRoot.hasLoadError = false;
                webview.reload();
            }
            onOpenExternallyRequested: {
                if (webViewRoot.isHttpUrl(plasmoid.configuration.url))
                    Qt.openUrlExternally(plasmoid.configuration.url);
            }
        }
    }

    Rectangle {
        id: statusBubble

        property int padding: 8

        color: Kirigami.Theme.backgroundColor
        visible: false
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: statusText.paintedWidth + padding
        height: statusText.paintedHeight + padding

        Text {
            id: statusText

            anchors.centerIn: statusBubble
            elide: Qt.ElideMiddle
            color: Kirigami.Theme.textColor

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
        downloadsModel: webview.downloads
        downloadCache: webview.downloadCache
        webviewItem: webview
    }

    FindBar {
        id: findBar
        findBarVisible: webViewRoot.findBarVisible
        webviewItem: webview

        onCloseRequested: {
            webViewRoot.findBarVisible = false;
        }

        onFindBarVisibleChanged: {
            if (findBarVisible) {
                findBar.focusAndSelect();
            } else {
                findBar.clearSearch();
            }
        }
    }
}
