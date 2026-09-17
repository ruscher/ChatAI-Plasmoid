/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Main plasmoid item that contains all the widget functionality
PlasmoidItem {
    id: root

    ProviderModel {
        id: providerModel
    }

    readonly property alias models: providerModel.providers

    // Initialize the plasmoid and check if it should load on startup
    Component.onCompleted: {
        // If loadOnStartup is enabled in configuration
        if (plasmoid.configuration.loadOnStartup) {
            webviewLoader.active = true; // Activate the WebView loader
            root.expanded = true; // Expand the plasmoid
        }
    }

    // Widget appearance when collapsed (icon only)
    compactRepresentation: CompactRepresentation {
        id: compactRep

        plasmoidItem: root
        models: root.models
        webview: root.webviewRoot ? root.webviewRoot.webview : null
    }

    // Widget appearance when expanded (full view)
    fullRepresentation: ColumnLayout {
        id: mainLayout

        // Expose WebView root for other components
        property alias webviewRoot: webviewLoader.item
        // Default dimensions (used when no saved size exists)
        readonly property int defaultWidth: Kirigami.Units.gridUnit * 28
        readonly property int defaultHeight: Kirigami.Units.gridUnit * 39

        // Set minimum dimensions for the expanded view
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 28
        // Use saved dimensions if available, otherwise use defaults
        Layout.preferredWidth: plasmoid.configuration.dialogWidth > 0 ? plasmoid.configuration.dialogWidth : defaultWidth
        Layout.preferredHeight: plasmoid.configuration.dialogHeight > 0 ? plasmoid.configuration.dialogHeight : defaultHeight

        // Save window size when user resizes
        // Use a timer to debounce saves (avoid saving on every pixel change)
        Timer {
            id: saveSizeTimer
            interval: 500
            repeat: false
            onTriggered: {
                // Only save if the size is valid and different from saved value
                const currentWidth = Math.round(mainLayout.width);
                const currentHeight = Math.round(mainLayout.height);
                const savedWidth = plasmoid.configuration.dialogWidth;
                const savedHeight = plasmoid.configuration.dialogHeight;
                
                // Save if dimensions are valid and different from what's saved
                if (currentWidth > 0 && currentHeight > 0 &&
                    (currentWidth !== savedWidth || currentHeight !== savedHeight)) {
                    plasmoid.configuration.dialogWidth = currentWidth;
                    plasmoid.configuration.dialogHeight = currentHeight;
                }
            }
        }

        onWidthChanged: saveSizeTimer.restart()
        onHeightChanged: saveSizeTimer.restart()

        spacing: 0

        // Header component with auto-hide behavior
        Header {
            id: headerRoot

            property bool headerVisible: false
            property bool isInteracting: false
            property bool shouldBeVisible: {
                if (plasmoid.configuration.hideHeader)
                    return false;

                if (!plasmoid.configuration.autoHideHeader)
                    return true;

                return headerVisible || isInteracting || headerMouseArea.containsMouse;
            }

            models: root.models
            Layout.fillWidth: true
            z: 2 // Increase the z-index to ensure it is above the MouseArea
            // Callback to close the WebView and collapse the widget
            closeWebViewCallback: function () {
                webviewLoader.active = false;
                root.expanded = false;
            }
            // Handle navigation
            onGoBackToHomePage: webviewRoot.goBackToHomePage()
            onReloadPageRequested: webviewRoot.reloadPage()
            onNavigateBackRequested: webviewRoot.goBack()
            onNavigateForwardRequested: webviewRoot.goForward()
            onPrintPageRequested: webviewRoot.printPage()
            onToggleSearchRequested: {
                if (webviewRoot && webviewRoot.findBarVisible !== undefined) {
                    webviewRoot.findBarVisible = !webviewRoot.findBarVisible;
                }
            }
            Layout.preferredHeight: shouldBeVisible ? implicitHeight : 0
            Layout.maximumHeight: Layout.preferredHeight
            Layout.minimumHeight: 0
            Layout.bottomMargin: shouldBeVisible ? Kirigami.Units.smallSpacing : 0
            visible: Layout.preferredHeight > 0
            opacity: Layout.preferredHeight > 0 ? 1 : 0
            clip: true
            // Timer for hiding
            Timer {
                id: hideTimer

                interval: 2000
                onTriggered: {
                    if (!headerRoot.isInteracting)
                        headerRoot.headerVisible = false;
                }
            }

            // Intercept mouse events
            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    headerRoot.headerVisible = true;
                    hideTimer.stop();
                }
                onExited: {
                    if (!headerRoot.isInteracting)
                        hideTimer.restart();
                }
                onPressed: {
                    headerRoot.isInteracting = true;
                    mouse.accepted = false;
                }
                onReleased: {
                    headerRoot.isInteracting = false;
                    if (!containsMouse)
                        hideTimer.restart();

                    mouse.accepted = false;
                }
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Mouse detection area
        MouseArea {
            id: headerMouseArea

            height: 2
            hoverEnabled: true
            z: 1 // Place below the header
            propagateComposedEvents: true
            onEntered: {
                headerRoot.headerVisible = true;
                hideTimer.stop();
            }
            onExited: {
                if (!headerRoot.isInteracting)
                    hideTimer.restart();
            }
            // Pass mouse events to child components
            onClicked: mouse.accepted = false
            onPressed: mouse.accepted = false
            onReleased: mouse.accepted = false
            onDoubleClicked: mouse.accepted = false
            onPositionChanged: mouse.accepted = false
            onPressAndHold: mouse.accepted = false

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }

        // WebView loader that manages the web content
        Loader {
            id: webviewLoader

            // Improved the loading of the WebView & Added Error Handling
            active: root.expanded || item !== null || plasmoid.configuration.loadOnStartup
            asynchronous: true
            source: "WebView.qml"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 0

            // Add status handling
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load WebView.qml");
                }
            }
        }

        // Monitor plasmoid expansion state
        Connections {
            // Activate WebView when plasmoid is expanded
            function onExpandedChanged() {
                if (root.expanded)
                    webviewLoader.active = true;
            }

            target: root
        }
    }
}
