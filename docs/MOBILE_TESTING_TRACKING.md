# Mobile testing — issue tracking

Use **GitHub Issues** on `raghvsc/navodayan-mobile`.

## For testers

1. Open https://github.com/raghvsc/navodayan-mobile/issues/new/choose
2. Choose **Mobile bug** (or **Testing feedback** for ideas)
3. Fill device, OS, build, steps, expected vs actual
4. Attach a screenshot if you can
5. For crash / cannot login, set severity to **Blocker**

## Labels

| Label | Meaning |
| --- | --- |
| `android` / `ios` | Platform |
| `crash` / `ui` / `auth` / `data` / `perf` | Type |
| `blocker` / `high` / `medium` / `low` | Priority |
| `needs-repro` | New / not confirmed yet |
| `confirmed` | Reproduced |
| `in-progress` | Being fixed |
| `ready-to-retest` | Fix available — tester should verify |
| `feedback` | Suggestion, not a bug |

## Weekly flow

1. Tester files issue same day
2. Triage: add platform + type labels; set priority
3. Fix → `in-progress` → `ready-to-retest`
4. Tester retests → close, or comment and reopen if still broken

## Project board (optional)

Create a GitHub Project with columns: **Triage → Todo → In progress → Ready to retest → Done**.
