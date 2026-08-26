function combinePhrases(parts) {
  return (parts || []).filter(Boolean).join("，");
}

function rantDamage(combo, catalog) {
  if (!combo) return 0;
  let dmg = 12 * combo.length;
  (catalog || []).forEach(p => {
    if (combo.indexOf(p.text) >= 0) dmg += p.power || 0;
  });
  return dmg;
}

function parseLoadout(ids, catalog) {
  const map = {};
  (catalog || []).forEach(p => { map[p.id] = p; });
  return (ids || []).map(id => map[id]).filter(Boolean);
}

function rantPattern(ids, catalog) {
  const load = parseLoadout(ids, catalog);
  if (!load.length) return "stream";
  const power = load.reduce((s, p) => s + (p.power || 0), 0);
  if (load.some(p => p.id === "legend") || power >= 120) return "burst";
  if (load.length >= 3 || power >= 50) return "spread";
  if (load.some(p => p.id === "teach")) return "wave";
  return "stream";
}

function rantShotPower(combo, catalog) {
  return Math.min(7, Math.max(2.2, rantDamage(combo, catalog) / 40));
}
