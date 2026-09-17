/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 Rafael Ruscher <rruscher@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

/*
 * Toolbar:  📌  ←  →  ↻  ⌂  [ AI ▼ ]  🔍  👁  ⬇  ⋮  ✕
 * Secondary buttons move into the kebab menu when the bar gets narrow.
 */
RowLayout {
    id: header

    required property QtObject providerModel
    // WebView.qml root while loaded, otherwise null.
    property var webviewRoot: null
    property bool settingsOpen: false

    signal homeRequested()
    signal closeRequested()
    signal settingsRequested(string category)
    signal aboutRequested()
    signal shortcutsRequested()
    // True while a native dialog owned by the header is open.
    property bool modalOpen: folderDialog.visible

    readonly property bool hasWebView: webviewRoot !== null
    readonly property bool menuOpen: kebabMenu.visible || downloadMenu.visible || selector.popup.visible || customUrlField.visible

    // Progressive overflow (docs/03)
    readonly property int overflowLevel: width < Kirigami.Units.gridUnit * 26 ? 3 : width < Kirigami.Units.gridUnit * 30 ? 2 : width < Kirigami.Units.gridUnit * 34 ? 1 : 0
    readonly property bool eyesInBar: !plasmoid.configuration.hideAutoHideButton && overflowLevel < 1
    readonly property bool downloadInBar: !plasmoid.configuration.hideDownloadButton && overflowLevel < 2
    readonly property bool searchInBar: overflowLevel < 3
    readonly property bool homeInBar: !plasmoid.configuration.hideHomeButton && overflowLevel < 3

    spacing: Kirigami.Units.smallSpacing

    function configuredDownloadPath() {
        const configured = String(plasmoid.configuration.downloadPath || "");
        return configured || StandardPaths.writableLocation(StandardPaths.DownloadLocation);
    }

    function openDownloadFolder() {
        const path = String(configuredDownloadPath());
        Qt.openUrlExternally(path.indexOf("file://") === 0 ? path : "file://" + path);
    }

    function showCustomAddress() {
        customUrlField.text = plasmoid.configuration.url;
        customUrlField.visible = true;
        customUrlField.forceActiveFocus();
        customUrlField.selectAll();
    }

    function acceptCustomAddress() {
        const url = providerModel.normalizeUrl(customUrlField.text);
        customUrlField.visible = false;
        if (!url)
            return;
        if (plasmoid.configuration.url !== url)
            plasmoid.configuration.url = url;
        homeRequested();
    }

    component ToolbarButton: PlasmaComponents3.ToolButton {
        display: PlasmaComponents3.AbstractButton.IconOnly
        Accessible.name: text
        PlasmaComponents3.ToolTip.text: text
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    // 1. Pin
    ToolbarButton {
        id: pinButton
        visible: !plasmoid.configuration.hideKeepOpen
        icon.name: "window-pin"
        checkable: true
        checked: Boolean(plasmoid.configuration.pin)
        text: checked ? i18n("Pinned: stays open when clicking outside") : i18n("Pin: keep open when clicking outside")
        onToggled: plasmoid.configuration.pin = checked
    }

    // 2–3. Back / Forward
    ToolbarButton {
        visible: !plasmoid.configuration.hideNavigationButtons
        icon.name: "go-previous"
        text: i18n("Back")
        enabled: header.hasWebView && header.webviewRoot.canGoBack
        onClicked: header.webviewRoot.goBack()
    }

    ToolbarButton {
        visible: !plasmoid.configuration.hideNavigationButtons
        icon.name: "go-next"
        text: i18n("Forward")
        enabled: header.hasWebView && header.webviewRoot.canGoForward
        onClicked: header.webviewRoot.goForward()
    }

    // 4. Reload / Stop
    ToolbarButton {
        visible: !plasmoid.configuration.hideRefreshButton
        readonly property bool loadingPage: header.hasWebView && header.webviewRoot.loading
        icon.name: loadingPage ? "process-stop" : "view-refresh"
        text: loadingPage ? i18n("Stop loading") : i18n("Reload")
        enabled: header.hasWebView && !header.webviewRoot.clearingCache
        onClicked: loadingPage ? header.webviewRoot.stop() : header.webviewRoot.reload()
    }

    // 5. Home
    ToolbarButton {
        visible: header.homeInBar
        icon.name: "go-home"
        text: i18n("Home page of the current assistant")
        enabled: header.hasWebView
        onClicked: header.homeRequested()
    }

    // 6. Select AI (or the custom address field)
    AiSelector {
        id: selector
        visible: !customUrlField.visible
        providerModel: header.providerModel
        onSelected: header.homeRequested()
        onCustomAddressRequested: header.showCustomAddress()
    }

    PlasmaComponents3.TextField {
        id: customUrlField
        visible: false
        Layout.fillWidth: true
        placeholderText: "https://…"
        inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
        Accessible.name: i18n("Custom address")
        onAccepted: header.acceptCustomAddress()
        Keys.onEscapePressed: visible = false
        onActiveFocusChanged: {
            if (!activeFocus)
                visible = false;
        }
    }

    // 7. Search
    ToolbarButton {
        visible: header.searchInBar
        icon.name: "edit-find"
        text: i18n("Find in page (Ctrl+F)")
        enabled: header.hasWebView
        checkable: true
        checked: header.hasWebView && header.webviewRoot.findBarVisible
        onClicked: header.webviewRoot.toggleFind()
    }

    // 8. Eyes (auto-hide)
    ToolbarButton {
        visible: header.eyesInBar
        icon.name: plasmoid.configuration.autoHideHeader ? "view-hidden" : "view-visible"
        checkable: true
        checked: plasmoid.configuration.autoHideHeader
        text: checked ? i18n("Toolbar hides automatically; click to keep it visible") : i18n("Hide the toolbar automatically")
        onToggled: plasmoid.configuration.autoHideHeader = checked
    }

    // 9. Downloads
    ToolbarButton {
        id: downloadButton
        visible: header.downloadInBar
        icon.name: "folder-download"
        readonly property int activeCount: header.hasWebView ? header.webviewRoot.activeDownloadCount : 0
        text: activeCount > 0 ? i18np("One download in progress", "%1 downloads in progress", activeCount) : i18n("Downloads")
        onClicked: downloadMenu.popup()

        Rectangle {
            visible: downloadButton.activeCount > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: Kirigami.Units.smallSpacing * 2.5
            height: width
            radius: width / 2
            color: Kirigami.Theme.highlightColor
            Accessible.ignored: true
        }

        PlasmaComponents3.Menu {
            id: downloadMenu

            PlasmaComponents3.MenuItem {
                icon.name: "folder-open"
                text: i18n("Open Download Folder")
                onTriggered: header.openDownloadFolder()
            }
            PlasmaComponents3.MenuItem {
                icon.name: "folder"
                text: i18n("Choose Download Folder…")
                onTriggered: folderDialog.open()
            }
            PlasmaComponents3.MenuSeparator {}
            PlasmaComponents3.MenuItem {
                text: downloadButton.activeCount > 0
                    ? i18np("One download in progress (%2%)", "%1 downloads in progress (%2%)", downloadButton.activeCount, Math.round((header.hasWebView ? header.webviewRoot.activeDownloadProgress : 0) * 100))
                    : i18n("No downloads in progress")
                enabled: false
            }
            PlasmaComponents3.MenuItem {
                icon.name: "edit-clear-history"
                text: i18n("Clear Finished Downloads")
                enabled: header.hasWebView && header.webviewRoot.downloads.count > downloadButton.activeCount
                onTriggered: header.webviewRoot.clearFinishedDownloads()
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: i18n("Choose Download Folder")
        currentFolder: header.configuredDownloadPath()
        onAccepted: plasmoid.configuration.downloadPath = selectedFolder
    }

    // 10. Kebab
    ToolbarButton {
        id: kebabButton
        icon.name: "overflow-menu"
        text: i18n("More actions")
        onClicked: kebabMenu.popup()

        ChatAIMenu {
            id: kebabMenu
            webviewRoot: header.webviewRoot
            showFindItem: !header.searchInBar
            showAutoHideItem: !header.eyesInBar && !plasmoid.configuration.hideAutoHideButton
            showHomeItem: !header.homeInBar && !plasmoid.configuration.hideHomeButton
            showDownloadsItem: !header.downloadInBar && !plasmoid.configuration.hideDownloadButton
            onSettingsRequested: category => header.settingsRequested(category)
            onAboutRequested: header.aboutRequested()
            onShortcutsRequested: header.shortcutsRequested()
            onHomeRequested: header.homeRequested()
            onOpenDownloadFolderRequested: header.openDownloadFolder()
            onChooseDownloadFolderRequested: folderDialog.open()
        }
    }

    // 11. Close
    ToolbarButton {
        visible: !plasmoid.configuration.hideCloseButton
        icon.name: "window-close"
        text: i18n("Close and release memory")
        onClicked: header.closeRequested()
    }
}
