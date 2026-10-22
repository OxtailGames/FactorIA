// The FactorIA debugger for VS Code: starts `factoria dap` (the Debug Adapter Protocol server of the engine, see
// docs/DEBUGGING.md) for the debug type "factoria". Plain JavaScript, no build step, no dependencies.
"use strict";

const vscode = require("vscode");
const fs = require("fs");
const path = require("path");

// `factoria setup vscode` writes the absolute path of the factoria that installed this extension into this file.
const PATH_FILE = "factoria-path.txt";

function recordedFactoriaPath() {
    try {
        const text = fs.readFileSync(path.join(__dirname, PATH_FILE), "utf8").trim();
        if (text && fs.existsSync(text)) return text;
    } catch (e) {
        // No file: the extension was not installed by `factoria setup vscode`.
    }
    return "";
}

// The factoria to run: the launch attribute, else the recorded path, else the PATH.
function factoriaExecutable(configuration) {
    if (configuration && typeof configuration.factoriaPath === "string" && configuration.factoriaPath.trim() !== "") {
        return configuration.factoriaPath.trim();
    }
    return recordedFactoriaPath() || "factoria";
}

function defaultConfigurations() {
    return [
        { type: "factoria", request: "launch", name: "Play", mode: "play", project: "${workspaceFolder}" },
        { type: "factoria", request: "launch", name: "Headless (600 frames)", mode: "headless", project: "${workspaceFolder}", frames: 600 },
        { type: "factoria", request: "launch", name: "Tests", mode: "test", project: "${workspaceFolder}" },
    ];
}

function hasProject(folder) {
    return !!folder && fs.existsSync(path.join(folder.uri.fsPath, "factoria.json"));
}

class FactoriaAdapterFactory {
    createDebugAdapterDescriptor(session) {
        const configuration = session.configuration || {};
        const command = factoriaExecutable(configuration);
        const options = {};
        if (typeof configuration.project === "string" && configuration.project !== "" && fs.existsSync(configuration.project)) {
            options.cwd = configuration.project;
        }
        return new vscode.DebugAdapterExecutable(command, ["dap"], options);
    }
}

class FactoriaConfigurationProvider {
    // The configurations offered by the "Add Configuration..." button and by the Run and Debug dropdown.
    provideDebugConfigurations(folder) {
        return defaultConfigurations();
    }

    // F5 with no launch.json (an empty configuration) in a folder with factoria.json: play the project.
    resolveDebugConfiguration(folder, config) {
        if (!config.type && !config.request && !config.name) {
            if (!hasProject(folder)) {
                vscode.window.showErrorMessage(
                    "FactorIA: open a project folder (the one with factoria.json) to debug it, or create a launch.json with the type \"factoria\"."
                );
                return undefined;
            }
            config.type = "factoria";
            config.request = "launch";
            config.name = "Play";
        }
        if (config.type === "factoria") {
            if (!config.mode) config.mode = "play";
            if (!config.project && folder) config.project = folder.uri.fsPath;
        }
        return config;
    }
}

function activate(context) {
    context.subscriptions.push(
        vscode.debug.registerDebugAdapterDescriptorFactory("factoria", new FactoriaAdapterFactory())
    );
    const provider = new FactoriaConfigurationProvider();
    context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider("factoria", provider));
    // Offered in the Run and Debug dropdown without a launch.json (VS Code 1.74+; older versions use the initial ones).
    if (vscode.DebugConfigurationProviderTriggerKind) {
        context.subscriptions.push(
            vscode.debug.registerDebugConfigurationProvider("factoria", provider, vscode.DebugConfigurationProviderTriggerKind.Dynamic)
        );
    }
}

function deactivate() {}

module.exports = { activate, deactivate };
