# Across the Hall — episode plan

## Product position

The current game is **Episode I: The Fourth Floor**. Its five in-game chapters
are beats inside this episode, not five separately sold products.

Episode I remains free permanently. Updates may improve performance, clarity,
accessibility, atmosphere, and bug fixes, but must not remove its current
complete ending or put existing content behind payment.

## Implementation status

The Ubuntu full-build vertical slice now contains playable Episodes II–V:

- Episode II anchors one item through a floor reset.
- Episode III routes mutually exclusive basement circuits.
- Episode IV validates three complaint-stamp decisions.
- Episode V reuses the master plate at memory sockets and supports both final
  designations before the clock advances to 02:18.

The full campaign has automated progression coverage and a Linux export preset.
It is **not store-ready or uploaded**: external completion playtests, art/audio
polish, pacing, and paid-build packaging still gate the switch to Paid. The
public Web export explicitly excludes full-campaign scripts and scenes.

## Store model

Keep the existing **Across the Hall** page, URL, traffic, followers, ratings,
jam entry, devlogs, and tags. Use the same structure already proven by
**Tell**:

- Project payment mode: **Paid** once Episode II is ready.
- Embedded HTML upload: the continually improved Episode I, playable free.
- Full download upload: Episode I plus all released paid episodes, available
  after purchasing the project.

The split is by content, not merely by file format: the free embed ends with
Episode I; the paid download continues into Episode II and later episodes.
“Episode I remains free” means the browser version remains playable without a
purchase. The current downloadable Episode I zip can be retired or marked as a
demo when the paid full build launches.

Do not use individually priced files as pseudo-DLC. They behave as cumulative
payment tiers and later price changes can lock previous buyers out. Use the
project's base minimum price for the full build so purchasers retain ownership
when the price rises.

Recommended ladder:

| Store milestone | Free embedded slice | Paid full download | Minimum price |
| --- | --- | --- | --- |
| Now | Episode I | None; Episode I remains free/donate | Free |
| Episode II launch | Episode I | Episodes I + II | USD 2.99 |
| Episode III launch | Episode I | Episodes I + II + III | USD 5.99 |

Treat these as launch targets, not promises on the public page. Recheck price
against wishlists, follows, completion feedback, and play time before publishing
each milestone. Buyers at the Episode II price keep ownership and receive later
updates on this same project; that early-buyer benefit is intentional.

## Episode II — The Fifth Floor

### Hook

The elevator opens on a fifth floor that is absent from the directory. Every
door is 401. Behind each is the same apartment at a different point in the
night.

### Player loop

1. Carry one object through the elevator while the rest of the floor resets.
2. Use sound through doors to identify which version of the apartment is next.
3. Alter one past room to change another room in the present.
4. Avoid the tenant by controlling what is visible in mirrors, not by running.
5. Choose which version of 401 becomes real.

### Production boundary

- Reuse movement, interaction, inspect, note, audio synthesis, and peripheral
  tenant systems.
- Add one vertical traversal hub, three room-state variants, and a
  persistence/causality state machine.
- Keep one clear paid-episode ending. The full build contains Episode I and
  carries state into Episode II internally; it must also offer an Episode II
  start option for returning players.
- The free web build stays Episode I only. The paid full build targets
  downloadable Windows and Linux first; do not put the paid episodes in a
  publicly accessible web archive.

## Episode III — The Service Basement

The building's maintenance archive records every reset as a tenant complaint.
The player routes power between impossible floors, reconstructs the first
02:17 event, and decides whether to erase the building or become its caretaker.

Build this only after Episode II validates that players will pay for a longer
chapter. Reuse Episode II's state framework; add no second major simulation
system.

## Funnel

- Episode I ending and store page link to **GHOST CHANNEL** and **Tell** now.
- Episode I asks for an itch follow, not a purchase.
- When Episode II has a real trailer or playable vertical slice, the existing
  page changes from Free to Paid and the generic follow line becomes a clear
  **Buy the full game** call to action.
- Devlogs on the existing page announce each milestone to followers without
  rebuilding traffic on a new project.
- Do not call this a season pass. The purchase grants the full build available
  on the page and its future updates; only promise chapters that are actually
  scoped and in production.

## Release gate for Episode II

Before changing the existing page from Free to Paid:

- A vertical slice proves the carry-through-reset mechanic in Web export.
- At least five external players reach the slice ending without developer help.
- The page has a trailer, three real gameplay screenshots, controls, content
  disclosure, and a support/contact path.
- The embedded upload is verified to stop at Episode I, while the gated full
  download contains Episode II.
- Price, expected play time, supported download platforms, and the early-access
  update policy are stated plainly.
