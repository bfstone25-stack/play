/* SILVERTONGUE: AFTER HOURS — card battle client.
 *
 * Talks only to /cards/*. Never /say: there is no model behind this game. The hand, the
 * momentum bar and the portrait's expression are all driven by what the server's engine
 * returned for the card that was played. Plates are shown through the parent's cg.js and
 * recorded in Gate's cg_* namespace, exactly as the parent does.
 *
 * No popups, no redirects, ever. The only navigation is the in-page catalogue board
 * (play/_shared/board.js), offered at the end of a run the way the parent offers it.
 */
"use strict";
const API = window.SILVERTONGUE_CARDS_API || "";
const ICON = {warmth:"☕", respect:"🤝", direct_request:"🗣️", empathy:"💧", accountability:"⚖️", exchange:"🔁",
              craft:"🎨", precision:"🎯", evidence:"📎", safety:"🛡️", authority:"📜", calm_action:"🌙",
              cooperation:"🫱", riddle:"❓", specific_praise:"✨", constraints:"🔒", arithmetic:"➕",
              equivalence:"＝", contradiction:"⚡", concrete_example:"🍎",
              threat:"⚡", bribe:"💰", insult:"🗯️", entitlement:"👑"};
const PHASE_LABEL = {guarded:"GUARDED", engaged:"ENGAGED", wavering:"WAVERING", breakthrough:"BREAKTHROUGH"};
let S = null, D = null, SCEN = null, busy = false, lastEnergy = null, energyTimer = null;
/* the e2e driver reads the duel through window.D */
Object.defineProperty(window,"D",{get:()=>D});Object.defineProperty(window,"S",{get:()=>S});

function pid(){let p=localStorage.getItem("stc_pid");if(!p){p=Math.random().toString(36).slice(2)+Date.now().toString(36);localStorage.setItem("stc_pid",p);}return p;}
function track(name,value={}){try{if(window.TEL)TEL.ev(name,{scenario:D?D.scenario:"",...value});}catch(e){}}
function $(id){return document.getElementById(id);}
function esc(s){return String(s==null?"":s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));}
function toast(t){const el=$("toast");el.textContent=t;el.style.display="block";clearTimeout(el._t);el._t=setTimeout(()=>el.style.display="none",2200);}
async function api(path,body){const opt=body?{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({pid:pid(),...body}),credentials:"include"}:{credentials:"include"};
  const url=API+path+(body?"":(path.includes("?")?"&":"?")+"pid="+encodeURIComponent(pid()));
  const r=await fetch(url,opt);return r.json();}

/* ---------- wallet ---------- */
function renderWallet(eco){if(!eco)return;lastEnergy=eco.energy;$("gold").textContent=eco.gold;
  $("energyN").textContent=eco.energy.energy;$("energyPool").textContent=eco.energy.pool;
  $("energyBar").style.width=Math.round(100*eco.energy.energy/eco.energy.pool)+"%";
  $("dailyTag").textContent=eco.daily_available?"DAILY DUEL FREE":"";
  const p=eco.pity;if($("pity"))$("pity").textContent=`PULLS ${p.pulls} · EPIC PITY IN ${p.epic_pity_in} · CREDITS ${p.pull_credits}`;
  if($("pull1"))$("pull1").textContent=`1 PULL · ${eco.pull_price[1]}`;if($("pull10"))$("pull10").textContent=`10 PULL · ${eco.pull_price[10]}`;
  tickEnergy();}
function tickEnergy(){clearInterval(energyTimer);let left=lastEnergy?lastEnergy.next_in_s:0;
  const show=()=>{$("energyNext").textContent=(lastEnergy&&lastEnergy.energy<lastEnergy.pool)?`+1 in ${Math.floor(left/60)}:${String(left%60).padStart(2,"0")}`:"";};show();
  energyTimer=setInterval(()=>{if(left>0){left--;show();}else{clearInterval(energyTimer);refresh();}},1000);}

/* ---------- screens ---------- */
function go(name){document.querySelectorAll(".screen").forEach(s=>s.classList.toggle("on",s.id===name));$("duel").classList.toggle("on",name==="duel");
  document.querySelectorAll(".topActions .iconbtn").forEach(b=>b.classList.toggle("on",b.id==="nav-"+name));
  if(name==="home")refresh();if(name==="affection")renderAffection();if(name==="deck")loadDeck();if(name==="gacha")refresh();track("screen",{screen:name});}

async function refresh(){S=await api("/cards/state");if(S.error){toast(S.error);return;}renderWallet(S.economy);renderRoster();
  if(S.duel&&!D){D=S.duel;SCEN=S.scenarios.find(x=>x.id===D.scenario);enterDuel({en:"(She is still waiting.)"});}}

function chips(needs,evidence,harms){const ev=new Set(evidence||[]);let h="";
  (needs.paths[0]||[]).forEach(s=>h+=`<span class="chip ${ev.has(s)?"lit":""}" title="${s}">${ICON[s]||"•"} ${s}</span>`);
  (needs.help||[]).forEach(s=>h+=`<span class="chip help ${ev.has(s)?"lit":""}" title="support: ${s}">＋ ${ICON[s]||"•"} ${s}</span>`);
  (harms||[]).forEach(s=>h+=`<span class="chip harm">${ICON[s]||"⚠"} ${s} — closed</span>`);return h;}

function renderRoster(){const r=$("roster");r.innerHTML="";S.scenarios.forEach(sc=>{const aff=S.affection[sc.who]||{wins:0};const isDaily=S.daily.scenario===sc.id;
  const div=document.createElement("div");div.className="who"+(isDaily?" daily":"");
  div.innerHTML=`${isDaily?'<div class="dailytag">TODAY · FREE · ×2 AFFECTION</div>':""}<img src="ref/${sc.who}.png" alt="${esc(sc.name)}"><div class="meta"><div class="nm">${esc(sc.name)}</div><div class="role">${esc(sc.character)}</div><div class="aff">♥ ${aff.wins} ${"★".repeat(sc.stars)}</div><div class="needs">${chips(sc.needs,[],[])}</div></div><div class="go"><button class="btn" data-s="${sc.id}">DUEL · 3⚡</button>${isDaily?`<button class="btn free" data-daily="1" ${S.daily.available?"":"disabled"}>${S.daily.available?"DAILY · FREE":"DAILY DONE"}</button>`:""}</div>`;
  div.querySelector("[data-s]").onclick=()=>startDuel(sc.id,false);const dbtn=div.querySelector("[data-daily]");if(dbtn)dbtn.onclick=()=>startDuel(sc.id,true);r.appendChild(div);});}

/* ---------- duel ---------- */
async function startDuel(scenario,daily){if(busy)return;busy=true;const difficulty=$("difficulty").value;
  const r=await api("/cards/start",{scenario,difficulty,daily});busy=false;if(r.error){toast(r.error);renderWallet(r.economy);return;}
  D=r.duel;SCEN=r.scen;renderWallet(r.economy);track(r.resumed?"duel_resumed":"duel_started",{difficulty,daily});enterDuel({en:r.opening});}
function enterDuel(open){go("duel");$("goal").textContent=SCEN.goal;$("brief").textContent=SCEN.story;$("portrait").src="ref/"+SCEN.who+".png";
  $("banner").className="";$("banner").innerHTML="";toggleWild(false);bubble(SCEN.name,open.en,"");renderDuel();}
function bubble(who,text,cls){$("bubWho").textContent=who;$("bubText").textContent=text;$("bubble").className=cls||"";}
function renderDuel(){if(!D)return;$("stage").className="ph-"+(D.harms&&D.harms.length&&!D.won?"lost":D.phase);$("phaseTag").textContent=(D.harms&&D.harms.length?"CLOSED · ":"")+PHASE_LABEL[D.phase];
  $("mbar").style.width=Math.round(D.momentum*100)+"%";$("needs").innerHTML=chips(D.needs,D.evidence,D.harms);
  $("turnsN").textContent=`${D.turns}/${D.max_turns}`;$("turnPips").innerHTML=Array.from({length:D.max_turns},(_,i)=>`<i class="pip ${i<D.turns?"used":""}"></i>`).join("");
  $("nervePips").innerHTML=Array.from({length:D.nerve_cap},(_,i)=>`<i class="pip nerve ${i<D.nerve?"on":""}"></i>`).join("");$("deckLeft").textContent=`DECK ${D.deck_left}`;
  const h=$("hand");h.innerHTML="";D.hand.forEach(c=>{h.appendChild(cardEl(c,D.nerve,()=>playCard(c.id)));});
  if(D.wild_left>0){const w=document.createElement("div");w.className="card wild"+(D.nerve<2?" dis":"");w.innerHTML=`<div class="rar">WILD · once</div><div class="line">Say it in your own words.</div><div class="sig"><span class="chip">the engine reads it</span></div><div class="cost">${2}◈</div>`;if(D.nerve>=2)w.onclick=()=>toggleWild(true);h.appendChild(w);}}
function cardEl(c,nerve,onclick){const el=document.createElement("div");const dis=nerve!=null&&c.cost>nerve;el.className=`card ${c.rarity} ${c.kind==="coercion"?"coercion":""} ${dis?"dis":""}`;
  let sig=c.signals.map(s=>`<span class="chip">${ICON[s]||"•"} ${s}</span>`).join("");
  let body=c.kind==="coercion"?`<div class="big">${esc(c.face)}</div><div class="line">${esc(c.line)}</div><div class="fine">${esc(c.small_print||"")}</div>`:`<div class="line">“${esc(c.line)}”</div><div class="sig">${sig}</div>`;
  el.innerHTML=`<div class="rar">${c.rarity.toUpperCase()} · ${esc(c.character)}</div>${body}<div class="cost">${c.cost}◈</div>`;if(onclick&&!dis)el.onclick=onclick;return el;}
function toggleWild(on){$("wildBar").classList.toggle("on",!!on);if(on){$("wildInp").value="";setTimeout(()=>$("wildInp").focus(),0);}}
$("wildInp").addEventListener("keydown",e=>{if(e.key==="Enter")playWild();});
async function playWild(){const text=$("wildInp").value.trim();if(!text)return;toggleWild(false);await play("wild",text);}
async function playCard(id){await play(id,"");}
async function play(card,text){if(busy||!D||D.over)return;busy=true;const line=card==="wild"?text:(D.hand.find(c=>c.id===card)||{}).line;bubble("You",line,"player");
  const r=await api("/cards/play",{card,text});busy=false;if(r.error){toast(r.error);if(r.duel){D=r.duel;renderDuel();}return;}
  D=r.duel;renderWallet(r.economy);track("card_played",{card,kind:r.read.kind,phase:r.read.phase_after,turns:r.read.turns});
  setTimeout(()=>{bubble(SCEN.name,r.reply,r.read.harms.length?"gray":"");renderDuel();if(r.end)setTimeout(()=>endDuel(r),900);},420);}
function endDuel(r){const e=r.end,b=$("banner");b.className="on";const won=e.won;
  track(won?"duel_won":"duel_lost",{turns:e.turns,harmed:e.harmed,daily:e.daily});
  let h=`<h2 style="color:${won?"#f0cd88":"#b0684e"}">${won?"PERSUADED":e.harmed?"CLOSED":"OUT OF WORDS"}</h2><div style="color:#c9b48f">${won?`in ${e.turns} card${e.turns>1?"s":""}`:e.harmed?"Coercion. She kept talking; nothing opened.":"The turns ran out."}</div>`;
  if(won){const rw=e.reward;h+=`<div class="reward"><div style="color:#e0a94e;font:700 11px monospace;letter-spacing:1px;align-self:center">♥ ${rw.affection} (+${rw.affection_gain}) · ◆ +${rw.gold} · DROP →</div></div><div class="reward" id="dropSlot"></div>`;}
  h+=`<div class="beat">${esc(e.beat)}</div>`;
  if(won&&e.daily){h+=`<div id="pct" style="color:#7ac67a;font:700 11px monospace;letter-spacing:1px"></div>`;}
  h+=`<div style="display:flex;gap:8px;margin-top:8px"><button class="btn" onclick="leaveDuel()">BACK</button>${won?'<button class="btn q" onclick="go(\'affection\')">AFFECTION</button>':""}</div>`;
  b.innerHTML=h;if(won){$("dropSlot").appendChild(cardEl(e.reward.drop,null,null));
    const keys=e.reward.cg_unlocked||[];if(keys.length&&window.CG){const caps={};keys.forEach(k=>caps[k]=SCEN[k.slice(0,3)+"_caption"]||"");setTimeout(()=>CG.grant(keys,caps),600);}
    if(e.daily)api("/cards/daily").then(d=>{if(d.percentile!=null)$("pct").textContent=`你已经打败了 ${d.percentile}% 的玩家 · You have beaten ${d.percentile}% of players today.`;});}
  // End of a run: the board, offered the way the parent offers it. In the page, never a popup.
  if(window.BOARD&&BOARD.offerMore)setTimeout(()=>{try{BOARD.offerMore("adult");}catch(err){}},1200);}
function leaveDuel(){D=null;$("banner").className="";go("home");}

/* ---------- gacha ---------- */
async function pull(n){if(busy)return;busy=true;const r=await api("/cards/pull",{n});busy=false;if(r.error){toast(r.error);renderWallet(r.economy);return;}
  renderWallet(r.economy);track("gacha_pull",{n,paid:r.paid});const out=$("pullOut");out.innerHTML="";r.cards.forEach((c,i)=>{const el=cardEl(c,null,null);el.style.animationDelay=(i*70)+"ms";if(c.pity)el.querySelector(".rar").textContent+=" · PITY";out.appendChild(el);});}
async function devGold(){const r=await api("/cards/dev/gold",{amount:1000});if(r.error){toast(r.error);return;}toast("+1000 gold (dev)");refresh();}

/* ---------- affection ---------- */
async function renderAffection(){const r=await api("/cards/affection");if(r.error)return;const list=$("affList");list.innerHTML="";
  Object.entries(r.affection).forEach(([who,a])=>{const row=document.createElement("div");row.className="affrow";
    let lad="";a.ladder.forEach(s=>{if(s.placeholder){lad+=`<div class="slot ph">tier 4 · at ${s.at} wins<br>Blaze's own scene<br>(placeholder)</div>`;}
      else if(s.earned){if(window.Gate&&Gate.unlock)Gate.unlock("cg_"+s.key);lad+=`<div class="slot earned" data-k="${s.key}"><img src="${window.CG?CG.src(s.key):""}" alt="${s.key}"></div>`;}
      else lad+=`<div class="slot">tier ${s.tier}<br>at ${s.at} wins</div>`;});
    row.innerHTML=`<img src="ref/${who}.png" alt="${esc(a.name)}"><div><div class="nm" style="font:800 1em Georgia,serif">${esc(a.name)} <span style="color:#e0a94e;font:700 10px monospace;letter-spacing:1px;margin-left:6px">♥ ${a.wins}</span></div><div class="ladder">${lad}</div></div>`;
    row.querySelectorAll(".slot.earned").forEach(el=>el.onclick=()=>{const sc=S&&S.scenarios.find(x=>x.who===who);CG.show(el.dataset.k,sc?sc[el.dataset.k.slice(0,3)+"_caption"]:"");});list.appendChild(row);});}

/* ---------- deck ---------- */
let DECK=[],COLL=[];
async function loadDeck(){const sel=$("deckScen");if(!sel.options.length&&S){S.scenarios.forEach(s=>{const o=document.createElement("option");o.value=s.id;o.textContent=s.name+" · "+s.id;sel.appendChild(o);});sel.onchange=loadDeck;}
  const r=await api("/cards/deck?scenario="+encodeURIComponent(sel.value||"closing_time"));if(r.error)return;COLL=r.collection;DECK=r.deck.slice();$("deckSub").textContent=`Pick up to ${r.deck_size}. Copies count. The wild card is always in the deck and never counts.`;renderColl(r.deck_size);}
function renderColl(size){const g=$("coll");g.innerHTML="";const count={};DECK.forEach(i=>count[i]=(count[i]||0)+1);
  COLL.forEach(c=>{const el=cardEl(c,null,null);const inDeck=count[c.id]||0;if(inDeck)el.classList.add("in");el.innerHTML+=`<div class="n">${inDeck}/${c.n} in deck</div>`;
    el.onclick=()=>{if(inDeck<c.n&&DECK.length<size)DECK.push(c.id);else if(inDeck){DECK.splice(DECK.indexOf(c.id),1);}renderColl(size);};g.appendChild(el);});
  $("deckCount").textContent=`${DECK.length}/${size}`;}
async function saveDeck(){const r=await api("/cards/deck",{scenario:$("deckScen").value,deck:DECK});toast(r.ok?"Deck saved":(r.error||"failed"));}
async function autoDeck(){DECK=[];const r=await api("/cards/deck?auto=1&scenario="+encodeURIComponent($("deckScen").value));DECK=r.deck.slice();renderColl(r.deck_size);}

refresh();
