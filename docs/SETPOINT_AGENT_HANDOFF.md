# SetPoint AI — Agent Handoff (Index)

Use this as the **entry point** for a new agent. Do **not** re-scaffold the app; continue from the Flutter project at repo root.

**Repo:** https://github.com/e88040429-code/SportsAiAPP.git (`setpoint_ai`, org `com.setpoint`)

**Run:** `flutter run -d chrome`

## Which doc to load

| If you are working on… | Open this file only |
|------------------------|---------------------|
| Pose detection, Live Coach vision, Recap from pose, AI referee | [`SETPOINT_PHASE1_HANDOFF.md`](SETPOINT_PHASE1_HANDOFF.md) |
| Firebase, Flask API, real drill content/videos, testing/QA | [`SETPOINT_PHASE2_HANDOFF.md`](SETPOINT_PHASE2_HANDOFF.md) |

Do **not** attach both phase docs unless the task spans both phases.

## Phases at a glance

1. **Phase 1** (iters 0–9) — UI/nav mostly done; data still mock. **Next:** Iter **8.1–8.6** (`pose_detection`), then **Iter 9** (live AI referee MVP).
2. **Phase 2** (iters 10–15) — Real content via **Firebase + Flask** + testing-heavy hardening.

**Gate:** Do **not** start Phase 2 until **Iteration 8.6 is Done** and **Iteration 9 MVP is shipped** (unless the user redirects).

## Product (one paragraph)

SetPoint AI is a motion-analysis training app for **football, volleyball, and basketball**. Athletes use phone video + pose estimation for form tips. Ask AI uses Gemini (optional proxy). Phase 2 replaces mock catalogs with live drill videos, descriptions, and step breakdowns.
