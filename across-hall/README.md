# Across the Hall

Short first-person apartment horror in Godot 4.7. English is the first language.

You spawn on the 4th-floor landing. 401 is yours and shut. 402 is open. A tenant is only visible in peripheral vision.

## Play

Godot 4 will not run in Chrome unless the page is HTTPS (or localhost).
`http://100.x.x.x` on Tailscale is **not** a secure context.

```
godot --headless --path across-hall --export-release Web across-hall/build/web/index.html
python3 across-hall/scripts/serve_web.py --https --port 8443
```

Desktop: `godot --path across-hall` (needs a GPU window).

WASD move, mouse look, E interact, F flashlight, Shift walk faster, Esc free the mouse. After the ending, R restarts.

Loop (5 chapters):

1. Hall — flashlight. 401 locked, 402 open.
2. Apt 402 — vacancy notice signed with your name.
3. 402 bath — cassette + 401 key.
4. Apt 401 — unlock your own door. Calendar stuck on Feb 17. Clock at 02:17.
5. Overlap — plates swap. Play the cassette on the 401 deck. Ending: you are the door across the hall.

The neighbor lives in peripheral vision. Staring puts it behind you. Caught = reset to the hall, same 02:17.

## Full campaign

The paid/full build continues through four additional episodes:

1. **Episode II — The Unlisted Fifth Floor:** anchor an inspection tag through a reset and restore the basement button.
2. **Episode III — The Service Basement:** route LIFT, ARCHIVE, and HALL power to recover Management's key.
3. **Episode IV — Management:** file vacancy, noise, and duplicate complaints as RETURN, RETAIN, or REMOVE.
4. **Episode V — The Exit Directory:** recover three memories, choose OCCUPANT or DOOR, and move the clock to 02:18.

Export the Ubuntu build:

```
godot --headless --path across-hall --export-release "Linux Full" across-hall/build/full/across-the-hall.x86_64
```

The full build starts with Episode I. At its ending, press **N** for the next
floor. Progress is saved at episode boundaries; on a later launch, press **C**
during Episode I to continue the latest unlocked episode. At the final ending,
**R** clears campaign progress and starts again from Episode I.

The public Web preset excludes `scripts/full/*` and
`scenes/full_campaign.tscn`; its embed remains Episode I only.

The full build is first-person camera-only: no player body mesh. Hands can be
added later if needed; a full avatar is not required for this camera style.
