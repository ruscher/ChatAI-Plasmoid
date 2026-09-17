/*
 *  SPDX-FileCopyrightText: 2026 ChatAI-Plasmoid contributors
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick

// Single source of truth for built-in and user-provided chat services.
QtObject {
    id: providerModel

    readonly property string duckDuckGoMobileUserAgent: "Mozilla/5.0 (Linux; Android 9; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.111 Mobile Safari/537.36"
    // Qt 6.10.2 is Chromium 134-based. Some providers reject QtWebEngine's
    // product token, so use the equivalent desktop Chromium identity for them.
    readonly property string desktopChromiumUserAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"

    readonly property var builtInProviders: [
        { id: "t3", name: "T3 Chat", url: "https://t3.chat", configKey: "showT3Chat", iconId: "t3" },
        { id: "duckduckgo", name: "DuckDuckGo Chat", url: "https://duckduckgo.com/chat", configKey: "showDuckDuckGoChat", iconId: "duckduckgo", userAgent: duckDuckGoMobileUserAgent },
        { id: "chatgpt", name: "ChatGPT", url: "https://chatgpt.com", configKey: "showChatGPT", iconId: "chatgpt", userAgent: desktopChromiumUserAgent },
        { id: "huggingface", name: "HuggingChat", url: "https://huggingface.co/chat", configKey: "showHugginChat", iconId: "huggingface" },
        { id: "copilot", name: "Bing Copilot", url: "https://copilot.microsoft.com/", configKey: "showBingCopilot", iconId: "copilot" },
        { id: "google", name: "Google Gemini", url: "https://gemini.google.com/app", configKey: "showGoogleGemini", iconId: "google" },
        { id: "blackbox", name: "BlackBox AI", url: "https://www.blackbox.ai", configKey: "showBlackBox", iconId: "blackbox" },
        { id: "you", name: "You", url: "https://you.com/?chatMode=default", configKey: "showYou", iconId: "you" },
        { id: "perplexity", name: "Perplexity", url: "https://www.perplexity.ai", configKey: "showPerplexity", iconId: "perplexity" },
        { id: "lobechat", name: "LobeChat", url: "https://lobechat.com/chat", configKey: "showLobeChat", iconId: "lobechat" },
        { id: "bigagi", name: "Big-AGI", url: "https://get.big-agi.com", configKey: "showBigAGI", iconId: "bigagi" },
        { id: "claude", name: "Claude", url: "https://claude.ai/new", configKey: "showClaude", iconId: "claude" },
        { id: "deepseek", name: "DeepSeek", url: "https://chat.deepseek.com", configKey: "showDeepSeek", iconId: "deepseek", userAgent: desktopChromiumUserAgent },
        { id: "meta", name: "Meta AI", url: "https://www.meta.ai", configKey: "showMetaAI", iconId: "meta" },
        { id: "grok", name: "Grok", url: "https://x.com/i/grok", configKey: "showGrok", iconId: "grok", userAgent: duckDuckGoMobileUserAgent }
    ]

    readonly property var providers: builtInProviders.concat(customProviders(plasmoid.configuration.customSites))

    function normalizeUrl(value) {
        let candidate = String(value || "").trim();
        if (!candidate)
            return "";
        if (!/^[a-z][a-z0-9+.-]*:\/\//i.test(candidate))
            candidate = "https://" + candidate;
        return isHttpUrl(candidate) ? candidate : "";
    }

    function isHttpUrl(value) {
        return /^(https?):\/\/[^\s]+$/i.test(String(value || ""));
    }

    function slug(value) {
        const result = String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
        return result || "site";
    }

    function customProviders(serializedSites) {
        // Keep the comma-separated format for backwards compatibility. Accepting
        // an array also lets older development builds migrate without data loss.
        const entries = Array.isArray(serializedSites) ? serializedSites : String(serializedSites || "").split(",");
        const result = [];
        entries.forEach(entry => {
            if (typeof entry !== "string")
                return;
            const separator = entry.indexOf("|");
            if (separator <= 0)
                return;
            const name = entry.slice(0, separator).trim();
            const url = normalizeUrl(entry.slice(separator + 1));
            if (!name || !url || name.indexOf(",") !== -1 || name.indexOf("|") !== -1)
                return;
            result.push({
                id: "custom-" + slug(name),
                name: name,
                url: url,
                iconId: "logo",
                custom: true
            });
        });
        return result;
    }

    function isEnabled(provider) {
        return provider && (!provider.configKey || Boolean(plasmoid.configuration[provider.configKey]));
    }

    function enabledProviders() {
        return providers.filter(provider => isEnabled(provider));
    }

    function providerForUrl(value) {
        const candidate = String(value || "");
        return providers.find(provider => candidate === provider.url || candidate.indexOf(provider.url + "/") === 0 || candidate.indexOf(provider.url + "?") === 0) || null;
    }

    function nameForUrl(value) {
        const provider = providerForUrl(value);
        return provider ? provider.name : String(value || "");
    }
}
