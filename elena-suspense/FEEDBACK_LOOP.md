# Community feedback loop (Elena)

Closed loop for F95 / itch comments without arguing in-thread.

```
[Forum scrape] -> [Tier1 triage] -> [Actionable backlog] -> [Script/art patch] -> [Rebuild/publish]
```

## Commands

```bash
# Scrape lives in watch/state; for replies use a saved JSON then:
python3 tools/f95zone/feedback_triage.py \
  --in /opt/cursor/artifacts/f95_elena_replies_only.json \
  --out ~/.local/share/f95zone/elena_feedback_triage.json
```

## Tier rules

- **Noise / ideological:** AI-hate slogans, "shitty business", purity tests. Log only. Do not debate.
- **Actionable:** plot holes, unreadable UI/banner, bugs, broken saves, hollow overview copy.
- **Public reply style:** one bottom-of-thread thanks to everyone; never pile-on individuals.

## Current backlog from first Games thread

| Signal | Source | Status |
| --- | --- | --- |
| Vault "getaway" plot hole | Jack Mehoff 61 | Fixed in script + OP overview |
| Banner title too small | Jnx | Cover text enlarged for v0.1.1 |
| Overview AI cadence / em dashes | glitterjizzz | Overview rewritten |
| AI tag / disclosure | vall6269 | Thread already has AI-CG; disclosure clarified in OP |
| Thanks | rKnight | Included in community thanks reply |
