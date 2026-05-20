# Bake-off harness

One-off tool that runs the same set of photos through **Gemini 3.5 Flash** (multimodal) and **Plant.id /identification**, then scores them against a ground-truth manifest. The result decides whether the production blueprint locks in **Path A** (Gemini-primary) or **Path B** (Plant.id keeps species ID).

This folder is **temporary**. Delete it after the verdict is recorded in `.claude/launch-prep/10-production-blueprint.md` §6.1.

---

## Setup

### 1. Build the photo set

Pick **20 photos**:

- **10 common houseplants** — Monstera, snake plant, pothos, peace lily, aloe, rubber plant, ZZ plant, spider plant, fiddle leaf fig, jade plant. Anything Plant.id should reliably nail.
- **10 cultivars or hybrids** — specific rose varieties (Peace Rose, Double Delight, Iceberg), named orchid hybrids (Phalaenopsis amabilis, Dendrobium nobile), variegated houseplants (Thai Constellation Monstera, Pink Princess Philodendron), specific echeveria / calathea / sansevieria cultivars.

Source options:
- Your own plant photos
- Public-domain garden photography (Wikipedia, Pixabay, Unsplash)
- The original `Verdant/.../curious_collectibles-flower-5227732.jpg` works as one of the 20

Photos should be **clearly identifiable** — well-lit, in focus, the cultivar's distinguishing features visible.

### 2. Create the photo folder

Anywhere outside the repo (the repo's git won't track it, but keeping it out avoids accidents):

```
~/verdant-bakeoff/
├── manifest.json
├── common/
│   ├── monstera_deliciosa.jpg
│   ├── snake_plant.jpg
│   └── ...
└── cultivars/
    ├── peace_rose.jpg
    ├── double_delight_rose.jpg
    └── ...
```

Copy `manifest.example.json` to `manifest.json` in that folder. Edit it so each entry matches a real file you placed in the folder, with accurate `expected_species` and `expected_common` truth values.

### 3. Configure the test scheme

In Xcode:
1. **Product → Scheme → Edit Scheme…**
2. Select **Test** in the left sidebar
3. Open the **Arguments** tab
4. Under **Environment Variables**, add:

| Name | Value |
|---|---|
| `VERDANT_BAKEOFF_DIR` | `/Users/<you>/verdant-bakeoff` |
| `VERDANT_GEMINI_API_KEY` | `<your Gemini API key>` |
| `VERDANT_PLANT_ID_API_KEY` | `<your Plant.id API key>` |

5. Close the scheme editor.

### 4. Run

Open `BakeoffHarness.swift`. Click the diamond next to `runBakeoff`. The console will print:

```
🌱 Bake-off — 20 photos

  [1/20] → common/monstera_deliciosa.jpg (common)
  [2/20] → common/snake_plant.jpg (common)
  ...

## Bake-off detail
| # | File | Category | Truth | Gemini | Plant.id | G | P |
| 1 | monstera_deliciosa.jpg | common | Monstera deliciosa | Monstera deliciosa | Monstera deliciosa | ✅ | ✅ |
...

## Summary
| Set | Gemini 3.5 Flash | Plant.id |
| Common (10) | 9/10 (90%) | 10/10 (100%) |
| Cultivar (10) | 6/10 (60%) | 9/10 (90%) |

## Verdict
⚠️ Path B required — Gemini 3.5 Flash hit only 60% on cultivars (< 90% threshold).
```

### 5. Record the verdict

Copy the verdict block into `.claude/launch-prep/10-production-blueprint.md` under §6.1 ("Bake-off result"). Then delete this `VerdantTests/Bakeoff/` directory and commit:

```
git rm -r Verdant/VerdantTests/Bakeoff/
git commit -m "chore: remove bake-off harness, verdict recorded in blueprint §6.1"
```

---

## Scoring rules

A guess matches if the haystack `plant_name + scientific_name + common_names` contains either the `expected_species` or `expected_common` from the manifest (case-insensitive substring match).

- For **common** photos, the model just needs to get the species right. "Monstera" guess vs "Monstera deliciosa" truth → match.
- For **cultivar** photos, the model needs to name the cultivar. "Rose" guess vs "Peace Rose" truth → **fail**. "Rosa Peace" vs "Peace Rose" → match.

Pass threshold for Path A: Gemini hits ≥ 90% on the cultivar set.

---

## Why a separate URLSession (not the production services)

The harness deliberately makes its own HTTP calls instead of using `GeminiService` and `PlantIdService` for two reasons:

1. The current `GeminiService.generateTreatment` is text-only — we'd have to refactor it to be multimodal first, which is exactly what the bake-off is supposed to gate.
2. The bake-off is throwaway code. Keeping it self-contained means it can be deleted in one commit with zero impact on production code.

The harness mirrors the blueprint's intended multimodal request shape (§3.2 Gemini config, §3.3 image optimization) so the test reflects how production will actually call Gemini.
