.pragma library

// Coincidencia difusa con puntuación (estilo fzf, simplificada).
// Ignora tildes y mayúsculas. Premia inicios de palabra y letras seguidas.

function fold(s) {
    return (s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

// Devuelve {score, pos:[índices]} o null.
function match(query, text) {
    var q = fold(query).replace(/\s+/g, "");
    var t = fold(text);
    if (!q.length) return { score: 0, pos: [] };
    var direct = t.indexOf(q);
    if (direct >= 0) {
        var pos = [];
        for (var k = 0; k < q.length; k++) pos.push(direct + k);
        var boundary = direct === 0 || /[\s\-_.]/.test(t[direct - 1]);
        return { score: 100 + q.length * 10 + (direct === 0 ? 60 : boundary ? 30 : 0) - direct, pos: pos };
    }
    var score = 0, ti = 0, prev = -2, positions = [];
    for (var qi = 0; qi < q.length; qi++) {
        var c = q[qi], found = -1;
        for (var j = ti; j < t.length; j++) {
            if (t[j] === c) { found = j; break; }
        }
        if (found < 0) return null;
        var s = 1;
        if (found === prev + 1) s += 8;
        if (found === 0 || /[\s\-_.]/.test(t[found - 1])) s += 10;
        s -= Math.min(found - ti, 6) * 0.5;
        score += s;
        positions.push(found);
        prev = found; ti = found + 1;
    }
    return { score: score, pos: positions };
}

function escapeHtml(s) {
    return (s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Texto enriquecido con las letras coincidentes resaltadas.
function highlight(text, pos, color) {
    if (!pos || !pos.length) return escapeHtml(text);
    var set = {}; for (var i = 0; i < pos.length; i++) set[pos[i]] = true;
    var out = "", open = false;
    for (var j = 0; j < text.length; j++) {
        var hit = !!set[j];
        if (hit && !open) { out += "<b><font color='" + color + "'>"; open = true; }
        if (!hit && open) { out += "</font></b>"; open = false; }
        out += escapeHtml(text[j]);
    }
    if (open) out += "</font></b>";
    return out;
}
