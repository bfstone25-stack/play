/* IAA / IAP stubs. Live SDKs stay off. Grants happen locally. */
const Commerce = (() => {
  const SKUS = {
    "blindbox.099": { kind: "gacha", pulls: 1, stardust: 0 },
    "ammo.099": { kind: "tickets", tickets: 10 },
    "audio.099": { kind: "unlock", flag: "audio_pack" },
  };
  const unlocked = {};
  let rewardedGrants = 0;

  function rewarded(kind) {
    rewardedGrants += 1;
    if (kind === "ammo") Economy.addTickets(5);
    else if (kind === "double") Economy.grant(20);
    else if (kind === "revive") Economy.addTickets(1);
    else Economy.grant(10);
    return { ok: true, stub: true, kind, grants: rewardedGrants };
  }

  function purchase(sku) {
    const def = SKUS[sku];
    if (!def) return { ok: false, error: "unknown_sku" };
    if (def.kind === "tickets") Economy.addTickets(def.tickets);
    if (def.stardust) Economy.grant(def.stardust);
    if (def.kind === "unlock") unlocked[def.flag] = true;
    if (def.kind === "gacha") {
      /* caller runs Gacha.pull after paying StarDust or this stub */
      Economy.grant(Gacha.PULL_COST);
    }
    return { ok: true, stub: true, sku, def };
  }

  function hasUnlock(flag) {
    return !!unlocked[flag];
  }

  function snapshot() {
    return { rewardedGrants, unlocked: { ...unlocked } };
  }

  return { rewarded, purchase, hasUnlock, snapshot, SKUS };
})();
