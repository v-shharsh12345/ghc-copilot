#!/usr/bin/env node
// QMD bootstrap for VS Code MCP — resolves the global npm install path
// so the MCP config doesn't need a hardcoded or space-fragile path.
const { execSync } = require("child_process");
const path = require("path");
const { pathToFileURL } = require("url");

const npmRoot = execSync("npm root -g", { encoding: "utf8" }).trim();
const entry = path.join(npmRoot, "@tobilu", "qmd", "dist", "qmd.js");

// QMD is ESM with top-level await — must use dynamic import()
process.argv = [process.argv[0], entry, ...process.argv.slice(2)];
import(pathToFileURL(entry).href);
