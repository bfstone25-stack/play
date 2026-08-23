/* Exponential merit. Clicker numbers live here, not in the canvas. */
const Merit = (() => {
  let merit = 0;
  let clicks = 0;
  let level = 1;
  let auto = 0;

  function click() {
    clicks += 1;
    const gain = Math.floor(Math.pow(1.18, level - 1));
    merit += gain;
    return gain;
  }

  function tick(dt) {
    if (auto <= 0) return 0;
    const gain = Math.floor(auto * dt * Math.pow(1.08, level - 1));
    merit += gain;
    return gain;
  }

  function upgradeCost() {
    return Math.floor(20 * Math.pow(1.35, level - 1));
  }

  function tryUpgrade() {
    const cost = upgradeCost();
    if (merit < cost) return false;
    merit -= cost;
    level += 1;
    if (level % 3 === 0) auto += 1;
    return true;
  }

  function snapshot() {
    return { merit, clicks, level, auto, upgradeCost: upgradeCost() };
  }

  function load(data) {
    if (!data) return snapshot();
    merit = Math.max(0, Math.floor(data.merit) || 0);
    clicks = Math.max(0, Math.floor(data.clicks) || 0);
    level = Math.max(1, Math.floor(data.level) || 1);
    auto = Math.max(0, Math.floor(data.auto) || 0);
    return snapshot();
  }

  return { click, tick, tryUpgrade, snapshot, load, upgradeCost };
})();
