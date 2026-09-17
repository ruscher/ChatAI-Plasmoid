/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *  SPDX-FileCopyrightText: 2026 ChatAI-Plasmoid contributors
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import QtWebEngine

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Column {
    id: downloadsBar

    property var downloadsModel
    property var downloadCache
    property var webviewItem

    visible: downloadsModel && downloadsModel.count > 0
    spacing: Kirigami.Units.smallSpacing

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
    }

    function stateLabel(state, isPdf, error) {
        if (isPdf)
            return i18n("Saving PDF…");
        switch (state) {
        case WebEngineDownloadRequest.DownloadRequested:
            return i18n("Waiting");
        case WebEngineDownloadRequest.DownloadInProgress:
            return i18n("Downloading");
        case WebEngineDownloadRequest.DownloadCompleted:
            return i18n("Completed");
        case WebEngineDownloadRequest.DownloadCancelled:
            return i18n("Cancelled");
        case WebEngineDownloadRequest.DownloadInterrupted:
            return error || i18n("Interrupted");
        default:
            return i18n("Unknown state");
        }
    }

    function removeDownload(index) {
        if (downloadsModel && index >= 0 && index < downloadsModel.count)
            downloadsModel.removeDownload(index);
    }

    Repeater {
        model: downloadsModel

        delegate: Rectangle {
            width: downloadsBar.width
            height: Kirigami.Units.gridUnit * 2.5
            color: Kirigami.Theme.backgroundColor
            opacity: 0.98

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: model.fileName
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    Accessible.name: text
                }

                PlasmaComponents3.Label {
                    text: downloadsBar.stateLabel(model.state, model.isPdfExport, model.error)
                    opacity: 0.75
                    elide: Text.ElideRight
                    Layout.maximumWidth: downloadsBar.width * 0.3
                }

                PlasmaComponents3.ProgressBar {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                    from: 0
                    to: 1
                    value: model.progress || 0
                    indeterminate: model.isPdfExport || (model.totalBytes <= 0 && model.state === WebEngineDownloadRequest.DownloadInProgress)
                    visible: model.state === WebEngineDownloadRequest.DownloadRequested || model.state === WebEngineDownloadRequest.DownloadInProgress || model.state === WebEngineDownloadRequest.DownloadInterrupted
                }

                PlasmaComponents3.Button {
                    icon.name: model.isPaused ? "media-playback-start" : "media-playback-pause"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    visible: !model.isPdfExport && model.state === WebEngineDownloadRequest.DownloadInProgress
                    enabled: webviewItem && downloadCache && downloadCache[model.downloadId]
                    onClicked: {
                        if (model.isPaused)
                            webviewItem.resumeDownload(model.downloadId);
                        else
                            webviewItem.pauseDownload(model.downloadId);
                    }
                    PlasmaComponents3.ToolTip.text: model.isPaused ? i18n("Resume") : i18n("Pause")
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                PlasmaComponents3.Button {
                    icon.name: "dialog-cancel"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    visible: !model.isPdfExport && (model.state === WebEngineDownloadRequest.DownloadRequested || model.state === WebEngineDownloadRequest.DownloadInProgress || model.state === WebEngineDownloadRequest.DownloadInterrupted)
                    enabled: webviewItem
                    onClicked: webviewItem.cancelDownload(model.downloadId)
                    PlasmaComponents3.ToolTip.text: i18n("Cancel")
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                PlasmaComponents3.Button {
                    icon.name: "document-open"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    visible: model.state === WebEngineDownloadRequest.DownloadCompleted
                    enabled: model.fullPath
                    onClicked: Qt.openUrlExternally(downloadsBar.getOpenPath(model.fullPath))
                    PlasmaComponents3.ToolTip.text: i18n("Open file")
                    PlasmaComponents3.ToolTip.visible: hovered
                }

                PlasmaComponents3.Button {
                    icon.name: "dialog-close"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    visible: model.state === WebEngineDownloadRequest.DownloadCompleted || model.state === WebEngineDownloadRequest.DownloadCancelled || model.state === WebEngineDownloadRequest.DownloadInterrupted
                    onClicked: downloadsBar.removeDownload(index)
                    PlasmaComponents3.ToolTip.text: i18n("Remove")
                    PlasmaComponents3.ToolTip.visible: hovered
                }
            }
        }
    }

    function getOpenPath(path) {
        const local = String(path || "").replace(/^file:\/\/(localhost)?/, "");
        return "file://" + local;
    }
}
