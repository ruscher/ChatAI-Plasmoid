/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    required property PlasmoidItem plasmoidItem

    // Icon mode constants (must match ConfigAppearance.qml ComboBox order)
    readonly property int iconModeFavicon: 0
    readonly property int iconModeAdaptive: 1
    readonly property int iconModeDark: 2
    readonly property int iconModeLight: 3
    readonly property int iconModeOutlined: 4
    readonly property int iconModeFilled: 5
    readonly property int iconModeColorful: 6
    readonly property int iconModeCustom: 7

    property var models: []
    property var webview: null
    property string fallbackIcon: "help-about"

    readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: isVertical ? 0 : Kirigami.Units.iconSizes.medium
    Layout.minimumHeight: isVertical ? Kirigami.Units.iconSizes.medium : 0

    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.medium

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        property bool wasExpanded: false
        Accessible.name: compactRoot.currentProviderName()
        PlasmaComponents3.ToolTip.text: i18n("Open ChatAI — %1", compactRoot.currentProviderName())
        PlasmaComponents3.ToolTip.visible: containsMouse
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        onPressed: wasExpanded = compactRoot.plasmoidItem.expanded
        onClicked: compactRoot.plasmoidItem.expanded = !wasExpanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        // Use a function that returns a URL or icon name appropriately
        source: getIconSource()
    }

    function getIconSource() {
        let icon = getIconNameOrPath();
        if (icon.indexOf("/") !== -1 || icon.endsWith(".svg") || icon.endsWith(".png")) {
            return Qt.resolvedUrl(icon);
        }
        return icon;
    }

    function getChatModelIcon() {
        if (!models || models.length === 0)
            return `assets/logo-${getBackgroundColorContrast()}.svg`;

        const mode = plasmoid.configuration.iconMode;
        const currentModel = models.find(model => plasmoid.configuration.url === model.url || plasmoid.configuration.url.indexOf(model.url + "/") === 0 || plasmoid.configuration.url.indexOf(model.url + "?") === 0);
        const colorContrast = getBackgroundColorContrast();

        // Colorful mode. If not in colorful mode, some models only have colorful icons available
        const hasOnlyColorfulIcon = currentModel && mode !== iconModeColorful && ["lobechat", "bigagi"].includes(currentModel.id);
        const iconId = currentModel ? (currentModel.iconId || currentModel.id) : "";
        const availableIcons = ["t3", "duckduckgo", "chatgpt", "huggingface", "copilot", "google", "you", "perplexity", "claude", "deepseek"];

        if (!currentModel || currentModel.custom || !availableIcons.includes(iconId) || hasOnlyColorfulIcon) {
            return `assets/logo-${colorContrast}.svg`;
        }

        if (mode === iconModeColorful) {
            return `assets/colorful/${iconId}.svg`;
        }

        const style = mode === iconModeFilled ? "filled" : "outlined";
        return `assets/${style}/${iconId}-${colorContrast}.svg`;
    }

    function getIconNameOrPath() {
        const mode = plasmoid.configuration.iconMode;
        
        if (mode === iconModeCustom) {
            return plasmoid.configuration.customIcon || fallbackIcon;
        }
        
        if (mode === iconModeFavicon) {
            const faviconUrl = plasmoid.configuration.favIcon || plasmoid.configuration.lastFavIcon;
            if (faviconUrl) {
                return faviconUrl.replace("image://favicon/", "");
            }
        }

        if (mode >= iconModeOutlined) {
            return getChatModelIcon() || fallbackIcon;
        }

        const contrast = getBackgroundColorContrast();
        if (mode === iconModeDark) return "assets/logo-dark.svg";
        if (mode === iconModeLight) return "assets/logo-light.svg";
        
        return `assets/logo-${contrast}.svg`;
    }

    function getBackgroundColorContrast() {
        // Use Kirigami.Theme for better Plasma 6 compatibility
        const color = Kirigami.Theme.backgroundColor;
        const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
        return luma > 0.5 ? "dark" : "light";
    }

    function currentProviderName() {
        const currentModel = models && models.find(model => plasmoid.configuration.url === model.url || plasmoid.configuration.url.indexOf(model.url + "/") === 0 || plasmoid.configuration.url.indexOf(model.url + "?") === 0);
        return currentModel ? currentModel.name : i18n("ChatAI");
    }
}
