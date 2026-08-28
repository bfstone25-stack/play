/* NULL//SHRINE — ECMG UI: boons, shrine album, sanctuary card */
const ECMG = (() => {
  function haptic(pattern) {
    try {
      if (navigator.vibrate) navigator.vibrate(pattern);
    } catch (e) {}
  }

  function applyTheme() {
    const th = RELICS.theme();
    const root = document.documentElement;
    root.dataset.theme = th.id;
    if (th.palette) {
      root.style.setProperty("--theme-bg", th.palette[0]);
      root.style.setProperty("--theme-a", th.palette[1]);
      root.style.setProperty("--theme-b", th.palette[2] || th.palette[1]);
    }
    const orb = RELICS.orb();
    if (typeof SFX !== "undefined" && SFX.setPack) {
      if (orb.audio === "bowl") SFX.setPack("bowl");
      else if (th.id === "theme_bamboo") SFX.setPack("bamboo");
      else SFX.setPack("crystal");
    }
  }

  function renderShrineList(tab) {
    const list = document.getElementById("shrineList");
    if (!list) return;
    list.innerHTML = "";
    const eq = RELICS.data.equipped;
    let items = [];
    if (tab === "orbs") items = RELICS.ORBS.map(o => ({ ...o, slot: "orb", active: eq.orb === o.id }));
    else if (tab === "sigils") items = RELICS.SIGILS.map(o => ({ ...o, slot: "sigil", active: eq.sigil === o.id }));
    else if (tab === "themes") items = RELICS.THEMES.map(o => ({ ...o, slot: "theme", active: eq.theme === o.id }));
    else {
      if (!RELICS.data.cards.length) {
        list.innerHTML = '<p class="shrine-empty">' + t("shrine.cards.empty") + "</p>";
        return;
      }
      RELICS.data.cards.forEach(card => {
        const el = document.createElement("button");
        el.type = "button";
        el.className = "relic-card";
        el.innerHTML = "<small>" + card.id + " · " + card.seed + "</small><b>" + card.line + "</b>";
        el.addEventListener("click", () => drawSanctuaryCard(card, true));
        list.appendChild(el);
      });
      return;
    }
    items.forEach(item => {
      const locked = !RELICS.isUnlocked(item.id);
      const el = document.createElement("button");
      el.type = "button";
      el.className = "relic-item" + (item.active ? " active" : "") + (locked ? " locked" : "");
      el.disabled = locked;
      el.innerHTML =
        "<b>" + t(item.nameKey) + "</b>" +
        "<small>" + (locked ? t("shrine.locked") : (item.active ? t("shrine.equipped") : t("shrine.equip"))) + "</small>";
      if (!locked) {
        el.addEventListener("click", () => {
          RELICS.equip(item.slot, item.id);
          applyTheme();
          if (SFX.click) SFX.click();
          renderShrineList(tab);
        });
      }
      list.appendChild(el);
    });
  }

  function openShrine() {
    const modal = document.getElementById("shrineModal");
    modal.hidden = false;
    modal.querySelectorAll(".tab").forEach(btn => {
      btn.onclick = () => {
        modal.querySelectorAll(".tab").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        renderShrineList(btn.dataset.tab);
      };
    });
    renderShrineList("orbs");
  }

  function closeShrine() {
    document.getElementById("shrineModal").hidden = true;
  }

  function openBoons(onPick) {
    const modal = document.getElementById("boonModal");
    const grid = document.getElementById("boonGrid");
    grid.innerHTML = "";
    const picks = RELICS.pickBoons(3);
    picks.forEach(boon => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "boon-card";
      btn.innerHTML = "<b>" + t(boon.nameKey) + "</b><span>" + t(boon.descKey) + "</span>";
      btn.addEventListener("click", () => {
        modal.hidden = true;
        if (SFX.boonSelect) SFX.boonSelect();
        haptic([12, 40, 18]);
        onPick(boon);
      });
      grid.appendChild(btn);
    });
    modal.hidden = false;
    if (SFX.breakthrough) SFX.breakthrough();
  }

  function drawSanctuaryCard(card, showModal) {
    const canvas = document.getElementById("sanctuaryCard");
    if (!canvas) return;
    const c = canvas.getContext("2d");
    const W = canvas.width, H = canvas.height;
    const th = RELICS.theme();
    const bg = th.palette[0] || "#07040c";
    const a = th.palette[1] || "#3dfff3";
    const b = th.palette[2] || "#ff2d6a";

    c.fillStyle = bg;
    c.fillRect(0, 0, W, H);
    const g = c.createLinearGradient(0, 0, W, H);
    g.addColorStop(0, a + "33");
    g.addColorStop(0.55, "transparent");
    g.addColorStop(1, b + "44");
    c.fillStyle = g;
    c.fillRect(0, 0, W, H);

    c.strokeStyle = a;
    c.globalAlpha = 0.35;
    c.lineWidth = 2;
    c.strokeRect(36, 36, W - 72, H - 72);
    c.globalAlpha = 1;
    c.strokeRect(48, 48, W - 96, H - 96);

    c.fillStyle = a;
    c.font = "600 18px Syne, sans-serif";
    c.fillText("NULL // SHRINE", 72, 110);
    c.fillStyle = "rgba(255,255,255,.55)";
    c.font = "14px Syne, sans-serif";
    c.fillText("CABINET 01 · DAILY SANCTUARY", 72, 138);

    c.fillStyle = "#fff";
    c.font = "700 42px Syne, sans-serif";
    c.fillText(card.id || "CARD", 72, 220);

    c.fillStyle = a;
    c.font = "600 22px Syne, sans-serif";
    c.fillText("SEED  " + (card.seed || "----"), 72, 280);
    c.fillStyle = b;
    c.fillText("RESONANCE  " + (card.resonance || "00"), 72, 320);

    c.fillStyle = "rgba(255,255,255,.92)";
    c.font = "500 28px 'Noto Serif SC', Georgia, serif";
    wrapText(c, card.line, 72, 420, W - 144, 40);

    c.fillStyle = "rgba(255,255,255,.35)";
    c.font = "12px Syne, sans-serif";
    c.fillText("blazeCore Play · Emotional Catharsis Micro-Game", 72, H - 72);

    if (showModal !== false) {
      document.getElementById("cardModal").hidden = false;
    }
  }

  function wrapText(c, text, x, y, maxW, lineH) {
    const chars = String(text).split("");
    let line = "";
    let yy = y;
    for (let i = 0; i < chars.length; i++) {
      const test = line + chars[i];
      if (c.measureText(test).width > maxW && line) {
        c.fillText(line, x, yy);
        line = chars[i];
        yy += lineH;
      } else line = test;
    }
    if (line) c.fillText(line, x, yy);
  }

  function buildCardFromRun(seed, resonance, vault) {
    const pct = Math.min(99, Math.round(40 + resonance * 8 + Math.min(vault, 40)));
    const apo = RELICS.aphorism(seed, pct, String(resonance).padStart(2, "0"));
    const card = {
      id: apo.id,
      seed: seed || "----",
      resonance: String(resonance).padStart(2, "0"),
      line: apo.line,
      at: Date.now(),
    };
    RELICS.addCard(card);
    return card;
  }

  async function downloadCard() {
    const canvas = document.getElementById("sanctuaryCard");
    const a = document.createElement("a");
    a.download = "null-shrine-sanctuary.png";
    a.href = canvas.toDataURL("image/png");
    a.click();
  }

  async function shareCardText(card) {
    const text = [
      "NULL//SHRINE · " + card.id,
      "SEED " + card.seed + " · RESONANCE " + card.resonance,
      card.line,
      "https://apps.blazecore.dev/null-shrine/",
    ].join("\n");
    try {
      if (navigator.share) await navigator.share({ text });
      else {
        await navigator.clipboard.writeText(text);
        return "copied";
      }
    } catch (e) {}
    return "ok";
  }

  function bindChrome() {
    const close = document.getElementById("shrineClose");
    if (close) close.addEventListener("click", closeShrine);
    document.getElementById("shrineModal")?.addEventListener("click", e => {
      if (e.target.id === "shrineModal") closeShrine();
    });
    document.getElementById("cardClose")?.addEventListener("click", () => {
      document.getElementById("cardModal").hidden = true;
    });
    document.getElementById("cardDownload")?.addEventListener("click", downloadCard);
    document.getElementById("cardShare")?.addEventListener("click", async () => {
      const last = RELICS.data.cards[0];
      if (last) await shareCardText(last);
    });
    document.getElementById("shrineBtn")?.addEventListener("click", openShrine);
    applyTheme();
  }

  return {
    haptic, applyTheme, openShrine, closeShrine, openBoons,
    drawSanctuaryCard, buildCardFromRun, downloadCard, shareCardText, bindChrome,
  };
})();
