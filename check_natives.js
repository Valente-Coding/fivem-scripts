#!/usr/bin/env node
// check_natives.js <file1.lua> [file2.lua ...]
// Flags PascalCase function calls that look like FiveM natives but don't
// exist in the natives reference and aren't defined locally in the file.
// This is a heuristic, not a perfect type-checker — it's meant to catch
// obviously invented native names.

const fs = require('fs');
const path = require('path');

const REFERENCE_PATH = path.join(__dirname, 'natives_reference.json');

// FiveM/Citizen runtime functions that aren't in the GTA natives DB
// but are valid. Extend this list if you see false positives.
const EXTRA_KNOWN_NAMES = new Set([
    'CREATE_THREAD', 'CREATE_THREAD_NOW', 'REGISTER_NET_EVENT', 'REGISTER_SERVER_EVENT',
    'ADD_EVENT_HANDLER', 'TRIGGER_EVENT', 'TRIGGER_SERVER_EVENT', 'TRIGGER_CLIENT_EVENT',
    'SET_TIMEOUT', 'REGISTER_COMMAND', 'REGISTER_NUI_CALLBACK', 'SEND_NUI_MESSAGE',
    'REGISTER_KEY_MAPPING',
]);

function loadNativeNames() {
    const data = JSON.parse(fs.readFileSync(REFERENCE_PATH, 'utf8'));
    const names = new Set(EXTRA_KNOWN_NAMES);
    for (const namespace of Object.values(data)) {
        for (const native of Object.values(namespace)) {
            if (native.name) names.add(native.name.toUpperCase());
        }
    }
    return names;
}

// PascalCase (e.g. GetEntityCoords) -> UPPER_SNAKE_CASE (GET_ENTITY_COORDS)
function toNativeCase(pascal) {
    return pascal
        .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
        .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
        .toUpperCase();
}

function checkFile(filePath, nativeNames) {
    const code = fs.readFileSync(filePath, 'utf8');

    // Locally-defined function names: function Foo(...), Foo = function, local Foo = function
    const localDefs = new Set();
    const defRegex = /(?:function\s+([A-Za-z_][\w.:]*)\s*\(|([A-Za-z_]\w*)\s*=\s*function)/g;
    let m;
    while ((m = defRegex.exec(code))) {
        const name = (m[1] || m[2] || '').split(/[.:]/).pop();
        if (name) localDefs.add(name);
    }

    // Candidate calls: PascalCase identifiers (2+ "words") followed by '('
    const callRegex = /\b([A-Z][a-zA-Z0-9]*[a-z][A-Za-z0-9]*)\s*\(/g;
    const flagged = new Set();
    while ((m = callRegex.exec(code))) {
        const name = m[1];
        if (localDefs.has(name)) continue;
        if (nativeNames.has(toNativeCase(name))) continue;
        if (name.length < 5) continue; // skip short/common words
        flagged.add(name);
    }
    return flagged;
}

function main() {
    const files = process.argv.slice(2);
    if (files.length === 0) {
        console.error('Usage: node check_natives.js <file1.lua> [file2.lua ...]');
        process.exit(1);
    }

    const nativeNames = loadNativeNames();
    let anyFlagged = false;

    for (const file of files) {
        const flagged = checkFile(file, nativeNames);
        if (flagged.size > 0) {
            anyFlagged = true;
            console.log(`${file}:`);
            for (const name of flagged) {
                console.log(`  - ${name}  (expected native form: ${toNativeCase(name)})`);
            }
        }
    }

    process.exit(anyFlagged ? 1 : 0);
}

main();
