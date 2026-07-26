# SetPoint AI — Future Roadmap (Agent Handoff)

Use this document as the starting context for the next agent. Do **not** re-scaffold the app; continue from the existing Flutter project at repo root.

---

## Product summary

**SetPoint AI** is an AI-powered motion analysis platform for discipline-specific sports training. Launch sports: **football, volleyball, basketball**. Athletes record drills/game clips on a phone; pose estimation compares them to coach-built reference libraries and returns tips on form, balance, symmetry, timing, and sport-specific metrics.

**Future goal (later):** live AI referee for hard in-game calls, reusing the same vision stack.

UI mockups were volleyball-first (SetPoint orange `#FF7F32`); product is multi-sport — keep volleyball content as default mock data until Iteration 7 (sport switcher).

Display name may change later; branding strings live in `lib/core/constants/app_strings.dart`.

**Repo:** [https://github.com/e88040429-code/SportsAiAPP.git](https://github.com/e88040429-code/SportsAiAPP.git) (Flutter at root, package `setpoint_ai`, org `com.setpoint`)

**Run (dev has no mobile SDKs yet):**

```bash
flutter run -d chrome
```

Platforms enabled: Android, iOS, **web**. Prefer Chrome for local UI work.

---



## What is already done


| Iteration        | Status | What shipped                                                                                               |
| ---------------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| **0 Foundation** | Done   | `.gitignore`, Flutter scaffold, theme, `go_router` 5-tab shell, packages `google_fonts` + `go_router`, web |
| **1 Home UI**    | Done   | Scrollable Home dashboard with mock data matching mockup                                                   |


**Home includes:** greeting + avatar, metric cards (Form/Drills/This Week), Today's Session → `/coach`, Common Skills → `/library/drill/:id`, Continue Learning with progress bars.

**Still placeholders:** Library, Drill Detail, Coach, Recap, Rehab.

### Key paths

```
lib/
  main.dart, app.dart
  core/theme/app_colors.dart, app_theme.dart
  core/router/app_router.dart          # StatefulShellRoute tabs
  core/constants/app_strings.dart
  features/home/                       # full UI + mock data
  features/library|coach|recap|rehab/  # placeholders
```



### Theme tokens

- Primary `#FF7F32`, background `#F8F8F8`, surface white, coach dark `#121212`
- Card radius ~20–24px; Inter via `google_fonts`



### Navigation

Tabs: Home | Library | Coach | Recap | Rehab  
Drill detail: `/library/drill/:drillId` (pushed on root navigator)

### Packages in use

`google_fonts`, `go_router`, `camera`. Pose overlay is still a **fake painted skeleton** (`FakeSkeletonOverlay` / `PoseSkeletonPainter`). Defer `google_mlkit_pose_detection` until Iteration 8.

### Conventions for new work

- Feature folders under `lib/features/<feature>/` with `data/` + `widgets/`
- Mock Dart models first; no backend yet
- Small iterations: one screen (or one vertical slice) per PR-sized chunk
- Preserve mockup visual language; no purple/generic AI aesthetic drift
- Verify with `flutter analyze` + `flutter test`; run on Chrome
- Do not edit plan files unless asked; commit/push only when asked

---



## Original UI mockup map (target screens)

```mermaid
flowchart TB
  Home --> Library
  Library --> DrillDetail
  Home --> LiveCoach
  LiveCoach --> Recap
  Home --> Rehab
```



1. **Home** — done
2. **Pose Library** — search, Training/Rehab toggle, category chips, skill list
3. **Drill Detail** — video placeholder, coach row, key positions timeline
4. **Live Coach** — dark camera HUD, fake skeleton, live metrics (camera later)
5. **Session Recap** — score ring, You vs Coach, joint angles, rep chart
6. **Rehab Hub** — readiness, program card, exercise checklist

---



## Ordered future roadmap

Work in this order unless the user redirects. Each row is one small iteration.

| Iter | Focus | Deliverable | New packages (only when needed) |
|------|--------|-------------|----------------------------------|
| **2** | Pose Library UI | Search, Training/Rehab toggle, chips, core skills list + mock data; tap → drill detail | none |
| **3** | Drill Detail UI | Video placeholder, coach row, key positions list; wired from Library/Home | none (video later) |
| **4** | Live Coach shell | Dark HUD, fake 17-point skeleton overlay, cue bubble, metrics bar, record button UI | `camera` (live preview) |
| **5** | Session Recap UI | Score circle, You vs Coach frames, joint angle rows, rep bar chart | `fl_chart` or custom bars |
| **6** | Rehab Hub UI | Readiness card, body highlight placeholders, active program, today's exercises checklist | none |
| **7** | Multi-sport switcher | Football / volleyball / basketball selector; shared drill models; Home/Library filter by sport | none |
| **8** | Video + pose pipeline | See sub-iterations **8.1–8.6** below | `google_mlkit_pose_detection` (+ commons); mobile first |
| **9+** | Live AI referee | Real-time hard-call assist on field/court — same vision stack, new product mode | TBD after Iter 8 |

---

## Iteration 8 — Fake skeleton → real pose detection

**Current state:** Live camera via `CoachCameraPreview`; overlay is `FakeSkeletonOverlay` / `PoseSkeletonPainter` with hardcoded joints; cues/metrics from `CoachMockData`.

**Guiding order:** Detect → draw on body → metrics/cues → compare to reference → recap. Do not jump to coaching tips until the skeleton tracks the athlete correctly.

**Platform note:** ML Kit is **Android/iOS only**, not Chrome. Keep fake skeleton (or a clear “pose tracking requires mobile” message) on web. Prefer a device/emulator for 8.1+.

### 8.1 — Add ML Kit and pose service shell
- Add `google_mlkit_pose_detection` (and `google_mlkit_commons` as needed).
- Create a small pose service API under something like `lib/features/coach/pose/` (e.g. `PoseDetectorService`) that can start/stop and emit landmarks.
- Gate real detection behind mobile (`!kIsWeb` / platform checks); web keeps fake overlay.
- **Done when:** package resolves on Android/iOS; app still runs on Chrome without crashing.

### 8.2 — Stream camera frames into the detector
- From existing `CameraController` in `CoachCameraPreview`, enable `startImageStream(...)`.
- Convert each `CameraImage` → ML Kit `InputImage` (rotation, front-camera mirroring, format).
- Throttle processing (e.g. every Nth frame or ~15–30 FPS) so UI stays smooth.
- **Done when:** detector receives frames on a physical device/emulator with no sustained frame drops / OOM.

### 8.3 — Normalize landmarks into painter format
- Map ML Kit landmarks (+ confidence) to the same 17-joint + bone list `PoseSkeletonPainter` already uses.
- Convert image coords → overlay coords (preview aspect ratio / letterboxing / front-cam flip).
- Introduce a shared model (e.g. `PoseFrame` with `List<Offset>` or normalized joints) so painter and metrics share one source of truth.
- **Done when:** unit-testable mapping exists; sample landmarks paint in the correct places on a still test image or fixed frame.

### 8.4 — Replace fake overlay with live skeleton
- In `coach_screen.dart`, swap `FakeSkeletonOverlay()` for a widget fed by live `PoseFrame`s.
- Keep `PoseSkeletonPainter` drawing logic; stop using hardcoded `_normalizedJoints` for the live path.
- Optionally hide overlay or show last-good pose when confidence is low.
- **Done when:** on-device, skeleton visibly tracks the athlete in Live Coach (not a static fake pose).

### 8.5 — Derive coaching cues and metrics from pose
- From landmarks, compute joint angles (elbow, knee, etc.), symmetry, timing/rep heuristics.
- Drive `CueBubble` and `CoachMetricsBar` from those values instead of `CoachMockData`.
- Later in this slice or as follow-up: compare live pose to Library reference poses (“You vs Coach” inputs).
- **Done when:** cues/metrics update while moving; mock constants are no longer the live source on mobile.

### 8.6 — Wire recording → Session Recap
- On stop record, persist clip (and/or sampled pose frames) from the session.
- Navigate to Recap with real form score, joint angles, and optional You vs Coach frames (not mock-only).
- **Done when:** a recorded Coach session produces a Recap populated from that session’s pose data.

### Explicit non-goals until later
- Backend / auth / cloud pose storage
- Full sport-rule AI referee (that is **Iter 9+**, reusing this vision stack)
- Perfect web parity for ML Kit (use fallback UI on Chrome)

