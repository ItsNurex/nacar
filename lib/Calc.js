.pragma library

// Calculadora segura (sin eval): descenso recursivo.
// Soporta + - * / % ^, paréntesis, constantes (pi, e, tau), funciones
// (sqrt, cbrt, sin, cos, tan, asin, acos, atan, ln, log, log2, abs, round,
// floor, ceil, exp), factorial (!), porcentajes ("20% de 150") y
// conversión de unidades simples ("5 km a mi", "100 c a f").

var FUNCS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, exp: Math.exp,
    sin: function (x) { return Math.sin(x * Math.PI / 180) },
    cos: function (x) { return Math.cos(x * Math.PI / 180) },
    tan: function (x) { return Math.tan(x * Math.PI / 180) },
    asin: function (x) { return Math.asin(x) * 180 / Math.PI },
    acos: function (x) { return Math.acos(x) * 180 / Math.PI },
    atan: function (x) { return Math.atan(x) * 180 / Math.PI },
    ln: Math.log, log: Math.log10, log2: Math.log2,
    round: Math.round, floor: Math.floor, ceil: Math.ceil
};
var CONSTS = { pi: Math.PI, "π": Math.PI, e: Math.E, tau: 2 * Math.PI };

function tokenize(s) {
    var t = [], i = 0;
    while (i < s.length) {
        var c = s[i];
        if (c === " ") { i++; continue; }
        if (/[0-9.]/.test(c)) {
            var j = i;
            while (j < s.length && /[0-9._]/.test(s[j])) j++;
            if (j < s.length && /[eE]/.test(s[j]) && /[0-9+-]/.test(s[j + 1] || "")) {
                j += 2;
                while (j < s.length && /[0-9]/.test(s[j])) j++;
            }
            var n = parseFloat(s.slice(i, j).replace(/_/g, ""));
            if (isNaN(n)) throw "num";
            t.push({ k: "n", v: n }); i = j; continue;
        }
        if (/[a-zπ]/i.test(c)) {
            var k = i;
            while (k < s.length && /[a-z0-9π]/i.test(s[k])) k++;
            t.push({ k: "id", v: s.slice(i, k).toLowerCase() }); i = k; continue;
        }
        if ("+-*/%^()!×÷,".indexOf(c) >= 0) {
            t.push({ k: "op", v: c === "×" ? "*" : c === "÷" ? "/" : c }); i++; continue;
        }
        throw "char";
    }
    return t;
}

function parse(tokens) {
    var p = 0;
    function peek() { return tokens[p]; }
    function eat(v) { var x = tokens[p]; if (x && x.v === v) { p++; return true; } return false; }

    function expr() {
        var v = term();
        while (peek() && (peek().v === "+" || peek().v === "-")) {
            var op = tokens[p++].v; var r = term();
            v = op === "+" ? v + r : v - r;
        }
        return v;
    }
    function term() {
        var v = unary();
        while (peek()) {
            var x = peek();
            if (x.v === "*" || x.v === "/" || x.v === "%") {
                p++; var r = unary();
                v = x.v === "*" ? v * r : x.v === "/" ? v / r : v % r;
            } else if (x.k === "n" || x.k === "id" || x.v === "(") {
                v = v * unary(); // multiplicación implícita: 2pi, 3(4+1)
            } else break;
        }
        return v;
    }
    function unary() {
        if (eat("-")) return -unary();
        if (eat("+")) return unary();
        return power();
    }
    function power() {
        var b = postfix();
        if (eat("^")) return Math.pow(b, unary());
        return b;
    }
    function postfix() {
        var v = atom();
        while (peek() && peek().v === "!") {
            p++;
            if (v < 0 || v > 170 || v !== Math.floor(v)) throw "fact";
            var f = 1; for (var i = 2; i <= v; i++) f *= i; v = f;
        }
        return v;
    }
    function atom() {
        var x = tokens[p++];
        if (!x) throw "eof";
        if (x.k === "n") return x.v;
        if (x.v === "(") { var v = expr(); if (!eat(")")) throw "paren"; return v; }
        if (x.k === "id") {
            if (CONSTS.hasOwnProperty(x.v)) return CONSTS[x.v];
            if (FUNCS.hasOwnProperty(x.v)) {
                var arg;
                if (eat("(")) { arg = expr(); if (!eat(")")) throw "paren"; }
                else arg = unary();
                return FUNCS[x.v](arg);
            }
        }
        throw "tok";
    }
    var r = expr();
    if (p < tokens.length) throw "trail";
    return r;
}

// Unidades: factor a unidad base de su dimensión.
var UNITS = {
    // longitud (m)
    mm: ["l", 0.001], cm: ["l", 0.01], m: ["l", 1], km: ["l", 1000],
    in: ["l", 0.0254], ft: ["l", 0.3048], yd: ["l", 0.9144], mi: ["l", 1609.344],
    // masa (kg)
    g: ["w", 0.001], kg: ["w", 1], lb: ["w", 0.45359237], oz: ["w", 0.028349523125], t: ["w", 1000],
    // datos (B)
    b: ["d", 1], kb: ["d", 1e3], mb: ["d", 1e6], gb: ["d", 1e9], tb: ["d", 1e12],
    kib: ["d", 1024], mib: ["d", 1048576], gib: ["d", 1073741824], tib: ["d", 1099511627776],
    // tiempo (s)
    ms: ["s", 0.001], s: ["s", 1], min: ["s", 60], h: ["s", 3600], d: ["s", 86400], sem: ["s", 604800],
    // velocidad (m/s)
    kmh: ["v", 1 / 3.6], mph: ["v", 0.44704], ms2: ["v", 1],
    // volumen (l)
    ml: ["vol", 0.001], l: ["vol", 1], gal: ["vol", 3.785411784]
};
var TEMP = { c: true, f: true, k: true };

function toC(v, u) { return u === "c" ? v : u === "f" ? (v - 32) * 5 / 9 : v - 273.15; }
function fromC(v, u) { return u === "c" ? v : u === "f" ? v * 9 / 5 + 32 : v + 273.15; }

function fmt(n) {
    if (!isFinite(n)) return n > 0 ? "∞" : n < 0 ? "-∞" : "indefinido";
    var a = Math.abs(n);
    if (a !== 0 && (a >= 1e15 || a < 1e-6)) return n.toExponential(6).replace(/\.?0+e/, "e");
    var s = (Math.round(n * 1e10) / 1e10).toString();
    var parts = s.split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    return parts.join(",");
}

function tryUnits(q) {
    var m = q.match(/^\s*(-?[0-9.,]+)\s*([a-zº°]+)\s+(?:a|en|to|in|->)\s+([a-zº°]+)\s*$/i);
    if (!m) return null;
    var v = parseFloat(m[1].replace(",", "."));
    var a = m[2].toLowerCase().replace(/[º°]/g, ""), b = m[3].toLowerCase().replace(/[º°]/g, "");
    if (TEMP[a] && TEMP[b]) return { value: fmt(fromC(toC(v, a), b)) + " °" + b.toUpperCase(), raw: fromC(toC(v, a), b) };
    var ua = UNITS[a], ub = UNITS[b];
    if (!ua || !ub || ua[0] !== ub[0]) return null;
    var r = v * ua[1] / ub[1];
    return { value: fmt(r) + " " + b, raw: r };
}

function tryPercent(q) {
    var m = q.match(/^\s*([0-9.,]+)\s*%\s*(?:de|of)\s*([0-9.,]+)\s*$/i);
    if (!m) return null;
    var r = parseFloat(m[1].replace(",", ".")) / 100 * parseFloat(m[2].replace(",", "."));
    return { value: fmt(r), raw: r };
}

// Devuelve {value, raw} o null si la consulta no parece matemática.
function evaluate(q) {
    if (!q) return null;
    var u = tryUnits(q); if (u) return u;
    var pc = tryPercent(q); if (pc) return pc;
    var s = q.replace(/,/g, ".");
    if (!/[0-9π]/.test(s)) return null;
    // Evita tratar como cálculo algo que es solo un número o texto normal.
    if (/^\s*[0-9.]+\s*$/.test(s)) return null;
    try {
        var r = parse(tokenize(s));
        if (typeof r !== "number" || isNaN(r)) return null;
        return { value: fmt(r), raw: r };
    } catch (e) {
        return null;
    }
}
