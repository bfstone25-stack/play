# itch.io page kit — Across the Hall

Public URL after create: `https://bfstone25-stack.itch.io/across-the-hall`

Itch has **no write API** for new pages or descriptions. API key + butler can **push builds** only after the page exists. Paste the blocks into **Create new game** / **Edit game**, then this agent can butler-push `html5`.

---

## Fields (listings — this is the traffic hook)

**Title:** Across the Hall

**Short description (keep under ~140 chars):**
The clock will not leave 02:17. 401 is locked. 402 is open. The vacancy form is signed with your name.

**Classification:** Games  
**Kind of project:** HTML  
**Release status:** Released (or In development if you prefer)  
**Price:** Free  
**Genre:** Horror  
**Tags:** `horror` `psychological-horror` `3d` `first-person` `short` `godot` `walking-simulator` `atmospheric` `ai-generated`

**Embed:** 1280 × 720, fullscreen on. Shared files: this file will be played in the browser. Embed `index.html`.

**Visibility:** Public (jam browse + homepage “new” both need this).

**Generative AI disclosure:** Code + text (Cursor / coding agents). Graphics: no diffusion pack — procedural Godot meshes/lights. Audio: synthesized in-engine.

---

## Details (paste into the description editor — HTML view if you have it)

```html
<p><em>A short first-person apartment horror.</em></p>

<p>You live in <strong>401</strong>. The deadbolt is on from the inside.<br>
<strong>402</strong> has been empty for three months, they say.<br>
The vacancy notice is in your handwriting. Steadier than yours is now.</p>

<p>The hallway clock is stuck at <strong>02:17</strong>.<br>
Not broken. Waiting.</p>

<hr>

<h2>The night</h2>
<ol>
<li>The fourth-floor hall. Take the flashlight. Do not stare into the corners.</li>
<li>402 — a signed vacancy, slippers that fit, a deck that is already turning.</li>
<li>The bathroom tap is still running. The cassette is still warm.</li>
<li>401 opens with a key labeled HOME. The calendar never left February 17.</li>
<li>The plates swap. Play the tape in the room that is yours.</li>
</ol>

<p>Someone lives in peripheral vision. Looking straight at them puts them behind you.<br>
If they catch you, you are back at the start of the same night.</p>

<h2>Controls</h2>
<p>WASD move · mouse look · E / click interact · F flashlight · Shift walk faster · Esc free the mouse · R restart after the ending</p>
<p>Desktop or laptop browser. Chrome / Firefox. Mouse strongly recommended — phones will cook themselves on this build.</p>

<h2>About ten minutes</h2>
<p>English throughout. No jump-scare timer, no inventory tetris. One floor, two doors, one clock that will not move.</p>

<h2>Jam note</h2>
<p>Built around a stuck time of night, not a time machine. If you found this from Themed Horror Game Jam #25 or from a jam page that is not this game, you can still play it here — the door is open either way.</p>

<h2>AI disclosure</h2>
<p>Code, design, and copy written with Cursor / cloud coding agents. 3D is procedural Godot meshes and lights (no third-party AI image pack in the build). Audio is synthesized in-engine. Disclose as <strong>code + text</strong>.</p>
```

---

## Cover line (optional, for the image alt / tweet)

Two doors. One name on both. 02:17 forever.

---

## After you click Save once

Tell the agent the page exists. Then:

```
butler push build/web bfstone25-stack/across-the-hall:html5
```

On Edit game: tick **This file will be played in the browser**, Kind = HTML, 1280×720, public.
