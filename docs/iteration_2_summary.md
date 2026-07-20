# SetPoint AI — Iteration Summary (Palette + Pose Library)

Summary of work completed in this session, covering the brand color refresh and **Iteration 2: Pose Library UI**.

---

## Scope

| Area | Status |
|------|--------|
| Color palette refresh | Done |
| Dart SDK constraint fix | Done |
| Iteration 2 — Pose Library UI | Done |
| Drill Detail (Iter 3) | Still a stub — not in this iteration |

---

## 1. Color palette

Replaced the previous SetPoint orange / light gray / near-black theme with the new coastal palette. Layout and behavior were left unchanged; only colors were updated.

### Palette constants (`lib/core/theme/app_colors.dart`)

| Hex | Name / role |
|-----|-------------|
| `#001219` | Darkest navy — deep backgrounds, Coach HUD (`coachDark`) |
| `#005F73` | Dark teal |
| `#0A9396` | Mid teal — primary actions / active states (`action`) |
| `#94D2BD` | Light teal — chips / subtle highlights (`highlight`) |
| `#E9D8A6` | Warm sand — scaffold background (`background`) |
| `#EE9B00` | Amber — metric accents (`accent`) |
| `#CA6702` | Burnt orange — primary brand (`primary`, replaces `#FF7F32`) |
| `#BB3E03` | Deep orange — buttons / CTAs (`cta`) |
| `#AE2012` | Dark red — warnings |
| `#9B2226` | Darkest red — errors |

### Theme application (`lib/core/theme/app_theme.dart`)

- Scaffold / AppBar background → warm sand
- Navigation selected state → mid teal (`action`)
- Elevated / filled buttons and FAB → deep orange (`cta`)
- Cards / surfaces → white

### Other color touchpoints

- Home mock skill accents and session card gradient now use `AppColors`
- Metric card icons use amber
- `web/manifest.json` `theme_color` / `background_color` updated to match

---

## 2. Dart SDK constraint

Local Flutter ships **Dart 3.12.0**. `pubspec.yaml` required `^3.12.2`, which blocked `flutter pub get` / `flutter analyze`.

**Fix:** `environment.sdk` lowered to `^3.12.0`. Analyze and tests resolve successfully on the current SDK.

---

## 3. Iteration 2 — Pose Library UI

Built the Library tab to mirror Home patterns: feature folder with `data/` + `widgets/`, mock Dart models, volleyball-first content, same visual language and palette.

### Files added / updated

```
lib/features/library/
  library_screen.dart              # full screen (replaced placeholder)
  drill_detail_screen.dart         # unchanged stub
  data/
    library_mock_data.dart         # models + Training/Rehab mock drills
  widgets/
    library_search_bar.dart
    library_mode_toggle.dart       # Training | Rehab segmented control
    category_chips_row.dart
    featured_drill_card.dart
    drill_list.dart                # "Core Skills" list
test/widget_test.dart              # Library section + navigation coverage
```

### Screen behavior

1. **Search** — filters drills by title / subtitle
2. **Training / Rehab toggle** — switches mode; resets category to All; swaps category chips
3. **Category chips** — Training: All, Spike, Serve, Set, Dig, Block · Rehab: All, Shoulder, Knee, Ankle, Core
4. **Featured drill** — shown when not searching / when category matches; tap navigates to detail
5. **Core Skills list** — filtered scrollable drills; tap → `/library/drill/:drillId`

### Navigation

Existing `go_router` route is used (no router changes needed):

- Library tab: `/library`
- Drill detail (root navigator push): `/library/drill/:drillId`

### Verification

```bash
flutter analyze
flutter test
```

Both pass. Widget tests cover Home regression, Library section titles (search, toggle, chips, featured, Core Skills), and drill → detail navigation.

---

## How to run

```bash
flutter run -d chrome
```

Open the **Library** tab to review the new Pose Library UI.

---

## Explicitly out of scope (this iteration)

- Drill Detail UI (Iteration 3)
- Live Coach / Recap / Rehab full UIs
- Real camera, ML, or backend
- Multi-sport switcher (Iteration 7)
- Docker / disk cleanup (environment issue only; not product work)

---

## Suggested next iteration (from handoff)

**Iteration 3 — Drill Detail UI:** video placeholder, coach row, key positions list; wire from Library / Home. Keep mock-data-first; no new packages yet.
