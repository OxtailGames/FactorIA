// Source instrumenter of the script debugger (docs/design/SCRIPT_DEBUGGER.md, "The instrumented code").
// Runs in a private QuickJS runtime of fa_tooling after external/acorn/dist/acorn.js, which defines `acorn`.
// globalThis.__faInstrument(file, source, moduleId) returns a JSON string: {code, info} or {error: {line, column, message}}.
// Text is only ever INSERTED, never a newline; every insertion is recorded in info.shifts.
// Columns are 1-based UTF-8 byte columns (QuickJS's unit); acorn offsets are 0-based UTF-16 units.
(function () {
    "use strict";

    const CLOSURE = "(__fa_x) => eval(__fa_x)";
    const LINE_BREAK = new RegExp("\\r\\n?|\\n|\\u2028|\\u2029", "g");

    function utf8len(s, from, to) {
        let n = 0;
        for (let i = from; i < to; i++) {
            const c = s.charCodeAt(i);
            if (c < 0x80) n += 1;
            else if (c < 0x800) n += 2;
            else if (c >= 0xd800 && c <= 0xdbff && i + 1 < to) { n += 4; i++; }
            else n += 3;
        }
        return n;
    }

    function instrument(file, source, moduleId) {
        let ast;
        try {
            // No `locations`: pos() below derives lines and byte columns from offsets, and the per-node Position objects
            // cost half of the parse time. A SyntaxError still carries `loc`.
            ast = acorn.parse(source, {
                ecmaVersion: "latest", sourceType: "module", preserveParens: true,
                allowHashBang: true, allowAwaitOutsideFunction: true,
            });
        } catch (e) {
            if (!(e instanceof SyntaxError)) throw e;
            const loc = e.loc || { line: 1, column: 0 };
            let lineStart = 0, line = 1;
            LINE_BREAK.lastIndex = 0;
            let m;
            while (line < loc.line && (m = LINE_BREAK.exec(source))) { lineStart = m.index + m[0].length; line++; }
            return JSON.stringify({
                error: {
                    line: loc.line, column: utf8len(source, lineStart, lineStart + loc.column) + 1,
                    message: String(e.message).replace(/ \(\d+:\d+\)$/, ""),
                },
            });
        }

        // ---- positions
        const lineStarts = [0];
        LINE_BREAK.lastIndex = 0;
        for (let m; (m = LINE_BREAK.exec(source));) lineStarts.push(m.index + m[0].length);
        const ascii = !/[^\x00-\x7f]/.test(source);
        function lineOf(off) {
            let lo = 0, hi = lineStarts.length - 1;
            while (lo < hi) {
                const mid = (lo + hi + 1) >> 1;
                if (lineStarts[mid] <= off) lo = mid; else hi = mid - 1;
            }
            return lo;  // 0-based line index
        }
        function pos(off) {
            const l = lineOf(off);
            const col = ascii ? off - lineStarts[l] : utf8len(source, lineStarts[l], off);
            return { line: l + 1, column: col + 1 };
        }

        // ---- output
        const ins = [];  // {off, text, seq}
        function insert(off, text) { ins.push({ off, text, seq: ins.length }); }

        const info = { statements: [], functions: [], scopes: [], shifts: [] };
        let cur = 0;  // current scope index

        function newScope(parent, kind, names) {
            info.scopes.push({ parent, kind, names });
            return info.scopes.length - 1;
        }

        // ---- names declared
        function patternNames(p, out) {
            if (!p) return;
            switch (p.type) {
                case "Identifier": out.push({ name: p.name, start: p.start }); break;
                case "ObjectPattern":
                    for (const prop of p.properties) patternNames(prop.type === "RestElement" ? prop.argument : prop.value, out);
                    break;
                case "ArrayPattern": for (const el of p.elements) patternNames(el, out); break;
                case "AssignmentPattern": patternNames(p.left, out); break;
                case "RestElement": patternNames(p.argument, out); break;
                case "ParenthesizedExpression": patternNames(p.expression, out); break;
                default: break;
            }
        }

        function declNames(d, out, withFunctions) {
            // lexical names declared by the statement `d` (let, const, class, function)
            if (!d) return;
            switch (d.type) {
                case "VariableDeclaration":
                    if (d.kind !== "var") for (const x of d.declarations) patternNames(x.id, out);
                    break;
                case "ClassDeclaration": if (d.id) out.push({ name: d.id.name, start: d.id.start }); break;
                case "FunctionDeclaration": if (withFunctions && d.id) out.push({ name: d.id.name, start: d.id.start }); break;
                case "ExportNamedDeclaration": declNames(d.declaration, out, withFunctions); break;
                case "ExportDefaultDeclaration":
                    if (d.declaration && (d.declaration.type === "ClassDeclaration" || d.declaration.type === "FunctionDeclaration"))
                        declNames(d.declaration, out, withFunctions);
                    break;
                case "LabeledStatement": declNames(d.body, out, withFunctions); break;
                default: break;
            }
        }

        function varNames(s, out) {
            // `var` names inside statement `s` (not inside nested functions, nor static blocks)
            if (!s) return;
            switch (s.type) {
                case "VariableDeclaration": if (s.kind === "var") for (const x of s.declarations) patternNames(x.id, out); break;
                case "BlockStatement": for (const x of s.body) varNames(x, out); break;
                case "IfStatement": varNames(s.consequent, out); varNames(s.alternate, out); break;
                case "ForStatement": varNames(s.init, out); varNames(s.body, out); break;
                case "ForInStatement": case "ForOfStatement": varNames(s.left, out); varNames(s.body, out); break;
                case "WhileStatement": case "DoWhileStatement": case "WithStatement": case "LabeledStatement":
                    varNames(s.body, out); break;
                case "TryStatement":
                    varNames(s.block, out);
                    if (s.handler) varNames(s.handler.body, out);
                    varNames(s.finalizer, out);
                    break;
                case "SwitchStatement": for (const c of s.cases) for (const x of c.consequent) varNames(x, out); break;
                case "ExportNamedDeclaration": varNames(s.declaration, out); break;
                default: break;
            }
        }

        function uniqueSorted(entries) {
            entries.sort((a, b) => a.start - b.start);
            const seen = new Set(), names = [];
            for (const e of entries) if (!seen.has(e.name)) { seen.add(e.name); names.push(e.name); }
            return names;
        }

        function listNames(stmts, withFunctions) {
            const out = [];
            for (const s of stmts) declNames(s, out, withFunctions);
            return out;
        }

        // ---- hooks
        function hookText(k) {
            return "if (__fa_h(__fa_f, " + k + ")) __fa_d.p(__fa_f, " + k + ", " + CLOSURE + "); ";
        }

        function addStatementInfo(off) {
            const p = pos(off);
            info.statements.push({ line: p.line, column: p.column, scope: cur });
            return info.statements.length - 1;
        }

        function hookable(s) {
            switch (s.type) {
                case "ImportDeclaration": case "FunctionDeclaration": case "EmptyStatement": case "ExportAllDeclaration":
                    return false;
                case "ExpressionStatement": return !s.directive;
                case "ExportNamedDeclaration":
                    return !!s.declaration && s.declaration.type !== "FunctionDeclaration";
                case "ExportDefaultDeclaration": return !s.declaration || s.declaration.type !== "FunctionDeclaration";
                default: return true;
            }
        }

        function statement(s) {
            if (hookable(s)) {
                const k = addStatementInfo(s.start);
                insert(s.start, hookText(k));
                if (s.type === "DebuggerStatement")
                    insert(s.start, "__fa_d.b(__fa_f, " + k + ", " + CLOSURE + "); ");
            }
            visitStatement(s);
        }

        function statementList(stmts) {
            for (const s of stmts) statement(s);
        }

        // the single-statement body of if/else/for/while/do/with
        function subBody(b) {
            if (!b) return;
            if (b.type === "BlockStatement") { block(b); return; }
            if (b.type === "EmptyStatement") return;
            insert(b.start, "{ ");
            statement(b);
            insert(b.end, " }");
        }

        function block(b) {
            const names = uniqueSorted(listNames(b.body, true));
            const saved = cur;
            if (names.length) cur = newScope(cur, "block", names);
            statementList(b.body);
            cur = saved;
        }

        // ---- function names
        function keyName(key, computed) {
            if (!key) return null;
            if (!computed) {
                if (key.type === "Identifier") return key.name;
                if (key.type === "PrivateIdentifier") return "#" + key.name;
                if (key.type === "Literal") return String(key.value);
            }
            if (key.type === "Literal" && typeof key.value === "string") return key.value;
            return "[computed]";
        }

        function memberName(m) {
            if (m.type !== "MemberExpression") return null;
            if (m.computed) return m.property.type === "Literal" && typeof m.property.value === "string" ? m.property.value : null;
            return keyName(m.property, false);
        }

        function isFunction(n) {
            return n && (n.type === "FunctionExpression" || n.type === "ArrowFunctionExpression");
        }

        function expr(n, hint, keyNode) {
            if (!n) return;
            if (isFunction(n)) visitFunction(n, hint, keyNode || null);
            else if (n.type === "ClassExpression") visitClass(n, hint);
            else visitGeneric(n);
        }

        // ---- functions
        function visitFunction(fn, hint, keyNode) {
            const arrow = fn.type === "ArrowFunctionExpression";
            const name = (fn.id && fn.id.name) || hint || "(anonymous)";
            const entries = [];
            for (const p of fn.params) patternNames(p, entries);
            const hoisted = [];
            if (fn.body.type === "BlockStatement") {
                for (const s of fn.body.body) { varNames(s, hoisted); declNames(s, hoisted, true); }
            }
            // parameters first (they keep their own order), then the body's names by position
            const paramNames = [];
            for (const e of entries) if (paramNames.indexOf(e.name) < 0) paramNames.push(e.name);
            const bodyEntries = hoisted.filter((e) => paramNames.indexOf(e.name) < 0);
            const bodyNames = uniqueSorted(bodyEntries);
            const scopeNames = (arrow ? [] : ["this"]).concat(paramNames, bodyNames);

            const startOff = fn.id ? fn.id.start : (keyNode ? keyNode.start : fn.start);
            const sp = pos(startOff);
            const savedScope = cur;
            const scope = newScope(cur, "function", scopeNames);
            const fid = info.functions.length;
            info.functions.push({ name, line: sp.line, column: sp.column, endLine: pos(Math.max(fn.end - 1, 0)).line, scope });
            const entry = "{ let __fa_f; try { __fa_f = __fa_d.e(" + fid + ", " + CLOSURE + "); ";
            const exit = " } catch (__fa_c) { throw __fa_d.c(__fa_f, __fa_c); } finally { __fa_d.x(__fa_f); } }";

            cur = scope;
            for (const p of fn.params) visitGeneric(p);
            if (fn.body.type === "BlockStatement") {
                const body = fn.body;
                // after the directive prologue
                let at = body.start + 1, text = entry;
                let lastDirective = null;
                for (const s of body.body) { if (s.type === "ExpressionStatement" && s.directive) lastDirective = s; else break; }
                if (lastDirective) {
                    at = lastDirective.end;
                    if (source[at - 1] !== ";") text = "; " + text;
                    else text = " " + text;
                }
                insert(at, text);
                statementList(body.body);
                insert(body.end - 1, exit);
            } else {
                const body = fn.body;
                const k = addStatementInfo(body.start);
                insert(body.start, entry + hookText(k) + "return ");
                visitGeneric(body);
                insert(body.end, "; " + exit.slice(1));
            }
            cur = savedScope;
        }

        function visitClass(c, hint) {
            let cname = (c.id && c.id.name) || hint || null;
            if (c.superClass) visitGeneric(c.superClass);
            for (const el of c.body.body) {
                if (el.type === "StaticBlock") {
                    const entries = [];
                    for (const s of el.body) { varNames(s, entries); declNames(s, entries, true); }
                    const saved = cur;
                    cur = newScope(cur, "block", uniqueSorted(entries));
                    statementList(el.body);
                    cur = saved;
                    continue;
                }
                if (el.computed) visitGeneric(el.key);
                const kn = keyName(el.key, el.computed);
                if (el.type === "MethodDefinition") {
                    let n;
                    if (el.kind === "constructor") n = cname || "(anonymous)";
                    else n = cname ? cname + "." + kn : kn;
                    visitFunction(el.value, n, el.key);
                } else if (el.type === "PropertyDefinition") {
                    if (el.value) expr(el.value, cname ? cname + "." + kn : kn);
                }
            }
        }

        // ---- statements and the generic walk
        function children(n) {
            const out = [];
            for (const k of Object.keys(n)) {
                if (k === "loc") continue;
                const v = n[k];
                if (v && typeof v === "object") {
                    if (Array.isArray(v)) { for (const x of v) if (x && typeof x.type === "string") out.push(x); }
                    else if (typeof v.type === "string") out.push(v);
                }
            }
            out.sort((a, b) => a.start - b.start);
            return out;
        }

        function visitGeneric(n) {
            if (!n) return;
            switch (n.type) {
                case "FunctionExpression": case "ArrowFunctionExpression": visitFunction(n, null, null); return;
                case "FunctionDeclaration": visitFunction(n, null, null); return;
                case "ClassExpression": case "ClassDeclaration": visitClass(n, null); return;
                case "VariableDeclarator":
                    visitGeneric(n.id);
                    expr(n.init, n.id.type === "Identifier" ? n.id.name : null);
                    return;
                case "AssignmentExpression": {
                    visitGeneric(n.left);
                    let hint = null;
                    if (n.left.type === "Identifier") hint = n.left.name;
                    else hint = memberName(n.left);
                    expr(n.right, hint);
                    return;
                }
                case "Property": {
                    if (n.computed) visitGeneric(n.key);
                    // in a pattern the value is a target/default; in an object literal a function value takes the key's name
                    const kn = keyName(n.key, n.computed);
                    if (n.value && n.value.type === "AssignmentPattern") visitGeneric(n.value);
                    else expr(n.value, kn === "[computed]" ? null : kn, n.method || n.kind !== "init" ? n.key : null);
                    return;
                }
                case "AssignmentPattern":
                    visitGeneric(n.left);
                    expr(n.right, n.left.type === "Identifier" ? n.left.name : null);
                    return;
                case "BlockStatement": case "IfStatement": case "ForStatement": case "ForInStatement": case "ForOfStatement":
                case "WhileStatement": case "DoWhileStatement": case "WithStatement": case "LabeledStatement":
                case "TryStatement": case "SwitchStatement": case "StaticBlock":
                    visitStatement(n);
                    return;
                default:
                    for (const c of children(n)) visitGeneric(c);
            }
        }

        function visitStatement(s) {
            switch (s.type) {
                case "BlockStatement": block(s); return;
                case "IfStatement":
                    visitGeneric(s.test);
                    subBody(s.consequent);
                    subBody(s.alternate);
                    return;
                case "ForStatement": case "ForInStatement": case "ForOfStatement": {
                    const head = s.type === "ForStatement" ? s.init : s.left;
                    const saved = cur;
                    if (head && head.type === "VariableDeclaration" && head.kind !== "var") {
                        const entries = [];
                        for (const d of head.declarations) patternNames(d.id, entries);
                        cur = newScope(cur, "block", uniqueSorted(entries));
                    }
                    if (s.type === "ForStatement") {
                        visitGeneric(s.init); visitGeneric(s.test); visitGeneric(s.update);
                    } else {
                        visitGeneric(s.left); visitGeneric(s.right);
                    }
                    subBody(s.body);
                    cur = saved;
                    return;
                }
                case "WhileStatement": visitGeneric(s.test); subBody(s.body); return;
                case "DoWhileStatement": subBody(s.body); visitGeneric(s.test); return;
                case "WithStatement": visitGeneric(s.object); subBody(s.body); return;
                case "LabeledStatement":
                    // never a hook between the label and its statement
                    if (s.body.type === "BlockStatement") block(s.body);
                    else visitStatement(s.body);
                    return;
                case "TryStatement": {
                    block(s.block);
                    if (s.handler) {
                        const h = s.handler;
                        const saved = cur;
                        if (h.param) {
                            if (h.param.type === "Identifier") {
                                insert(h.body.start + 1, " __fa_d.k(__fa_f, " + h.param.name + ");");
                            }
                            const entries = [];
                            patternNames(h.param, entries);
                            for (const e of listNames(h.body.body, true)) entries.push(e);
                            const names = [];
                            for (const e of entries) if (names.indexOf(e.name) < 0) names.push(e.name);
                            cur = newScope(cur, "catch", names);
                            visitGeneric(h.param);
                            statementList(h.body.body);
                        } else {
                            insert(h.body.start, "(__fa_k) ");
                            insert(h.body.start + 1, " __fa_d.k(__fa_f, __fa_k);");
                            block(h.body);
                        }
                        cur = saved;
                    }
                    if (s.finalizer) block(s.finalizer);
                    return;
                }
                case "SwitchStatement": {
                    visitGeneric(s.discriminant);
                    const stmts = [];
                    for (const c of s.cases) for (const x of c.consequent) stmts.push(x);
                    const names = uniqueSorted(listNames(stmts, true));
                    const saved = cur;
                    if (names.length) cur = newScope(cur, "block", names);
                    for (const c of s.cases) {
                        visitGeneric(c.test);
                        statementList(c.consequent);
                    }
                    cur = saved;
                    return;
                }
                case "ExportNamedDeclaration":
                    if (s.declaration) visitGeneric(s.declaration);
                    return;
                case "ExportDefaultDeclaration": {
                    const d = s.declaration;
                    if (d.type === "FunctionDeclaration") visitFunction(d, d.id ? null : "default", null);
                    else if (d.type === "ClassDeclaration") visitClass(d, d.id ? null : "default");
                    else expr(d, null);
                    return;
                }
                case "ExportAllDeclaration": case "ImportDeclaration": case "EmptyStatement": case "DebuggerStatement":
                case "BreakStatement": case "ContinueStatement":
                    return;
                default:
                    // ExpressionStatement, VariableDeclaration, ReturnStatement, ThrowStatement, ClassDeclaration, FunctionDeclaration...
                    visitGeneric(s);
            }
        }

        // ---- the module
        const moduleEntries = [];
        const imports = [];
        for (const s of ast.body) {
            if (s.type === "ImportDeclaration") {
                for (const sp of s.specifiers) imports.push({ name: sp.local.name, start: sp.local.start });
            } else {
                varNames(s, moduleEntries);
                declNames(s, moduleEntries, true);
            }
        }
        const importNames = [];
        for (const i of imports) if (importNames.indexOf(i.name) < 0) importNames.push(i.name);
        const topNames = uniqueSorted(moduleEntries).filter((n) => importNames.indexOf(n) < 0);
        newScope(-1, "module", importNames.concat(topNames));

        let prologueAt = 0;
        if (source.charCodeAt(0) === 0xfeff) prologueAt = 1;
        if (source.startsWith("#!", prologueAt)) {
            LINE_BREAK.lastIndex = prologueAt;
            const m = LINE_BREAK.exec(source);
            if (!m) return JSON.stringify({ code: source, info });  // only a hashbang: nothing to instrument
            prologueAt = m.index + m[0].length;
        }
        insert(prologueAt, "const __fa_d = globalThis.__fa_dbg, __fa_h = __fa_d.h, __fa_f = __fa_d.m(" + moduleId + ", " +
            CLOSURE + "); ");
        statementList(ast.body);

        // ---- apply
        ins.sort((a, b) => a.off - b.off || a.seq - b.seq);
        const parts = [];
        let last = 0;
        for (const it of ins) {
            parts.push(source.slice(last, it.off), it.text);
            last = it.off;
            const p = pos(it.off);
            info.shifts.push({ line: p.line, column: p.column, length: utf8len(it.text, 0, it.text.length) });
        }
        parts.push(source.slice(last));
        return JSON.stringify({ code: parts.join(""), info });
    }

    globalThis.__faInstrument = instrument;
})();
