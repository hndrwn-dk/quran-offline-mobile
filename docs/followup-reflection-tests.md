# Follow-up: reflection unit tests (distribution + provider flake)

Status: **documented only — do not fix in the 1.0.5+46 release**.

Independent of Play Console Tasks 1–3 (edge-to-edge, bitmap downsampling, R8).
These failures made `bash scripts/qo.sh submit` abort at `flutter test`; the
release AAB was still built with sync + verify + `verify_aab_assets.py` (738
assets OK). They are **not** a blocker for internal testing of `1.0.5+46`.

## Evidence (pre-existing since `9e76468`)

Worktree probe at commit `9e76468` (bitmap-era baseline before native edge-to-edge
experiments):

| Test | At `9e76468` | At `1fe1034` (release tip) |
|------|--------------|----------------------------|
| `test/reflection_distribution_test.dart` | Fail: `pagiShare ≈ 0.06575` vs expected 0.10–0.25 | Same failure; reflection blobs **identical** to `9e76468` |
| `test/reflection_provider_test.dart` (`empty weekly still keeps matching calendar entries`) | Flaky (pass/fail) | Flaky (~4/10 fails in one probe); same code as `9e76468` |

No reflection selector/provider/test file changes between `9e76468` and
`1fe1034`.

## Item A — `reflection_distribution_test` threshold

**Symptom:** Morning simulation (`hour: 7`) over 365 days of 2026 yields
`pagi_syukur` share ~6.6%, below the assert `inInclusiveRange(0.10, 0.25)`.

**What the test measures:** Pure Dart loop via `resolveReflectionPick` with
in-test fixtures (`calendarCatalog` + 19 `week_*` entries), fixed
`seedSalt: 'test-salt'`. Output reports `reproducible: true` — not seed drift.

**Why ~6.6% is expected under current rules (do not “fix the app” for this):**

- Higher tiers (Ramadan / Friday / Saturday, etc.) beat ambient `pagi_syukur`.
- On remaining mornings, `pagi_syukur` (ambient, weight 3) competes with 19
  always-eligible `week_*` ambient entries (weight 1 each).

**Follow-up:** Recalibrate the threshold (or fixture expectations) in the test
so they match tier priority + weekly competition. **Not** an app logic change
unless product intent for morning share explicitly changes.

## Item B — `reflection_provider_test` flake

**Symptom:** On Friday `DateTime(2026, 8, 21, 8)` with calendar override
`jumat_kahf` and empty weekly (fallbacks injected), assert sometimes gets
`fallback_ikhlas` / `fallback_asr` / `fallback_fatihah` instead of `jumat_kahf`.

**Likely mechanism (test harness, not release regression):** With a single
weekday primary, the picker borrows ambient fallbacks to fill the pool, then
RNG can pick borrowed (~30% path). Install salt / SharedPreferences across
tests make the seed non-deterministic between runs.

**Follow-up:** Mock or fix the seed (and prefs isolation) in test setup so the
Friday calendar case is reproducible. Do not change production picker behavior
solely to silence this flake unless product requires strict calendar wins.

## Out of scope for this note

- Edge-to-edge inset work on `feat/edge-to-edge-insets` (separate review).
- Uploading / promoting the AAB (operator-driven in Play Console).
