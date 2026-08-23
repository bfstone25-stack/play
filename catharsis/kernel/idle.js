const IDLE = { CAP_HOURS: 8 };

function idleRate(level, buildings) {
  let r = 1 + Math.max(0, (level || 1) - 1) * 0.85;
  (buildings || []).forEach(b => { r += (b.count || 0) * (b.rate || 0); });
  return r;
}

function upgradeCost(level) {
  return Math.floor(15 * Math.pow(1.4, Math.max(0, (level || 1) - 1)));
}

function offlineSeconds(lastTs, nowTs, capHours) {
  const cap = (capHours == null ? IDLE.CAP_HOURS : capHours) * 3600;
  if (!lastTs || !nowTs) return 0;
  if (nowTs < lastTs) return 0;
  const dt = (nowTs - lastTs) / 1000;
  if (dt < 0) return 0;
  return Math.min(cap, dt);
}

function offlineEarn(lastTs, nowTs, rate, capHours) {
  const sec = offlineSeconds(lastTs, nowTs, capHours);
  return Math.floor(sec * Math.max(0, rate || 0));
}
