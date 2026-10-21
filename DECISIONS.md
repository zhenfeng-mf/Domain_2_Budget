# DECISIONS — choices to explain in review

Add new decisions with date, choice, alternative, and reason. If a choice changes, record the replacement below instead of silently changing history. These are design decisions, not claims that every planned screen is implemented.

| ID | Date | Choice | Alternative and reason |
| --- | --- | --- | --- |
| D-01 | 2026-09-08 | Rails 8/MySQL 9 with Minitest | Framework defaults keep setup small; RSpec adds no needed capability here. |
| D-02 | 2026-09-08 | Integer yen | Avoid float rounding for JPY. |
| D-03 | 2026-09-08 | `used_on` as a date | A datetime could move an expense into another month through timezone conversion. |
| D-04 | 2026-09-09 | Store `Budget.approved_total` | A read-time sum cannot be protected by a row-level DB `CHECK`. Cost: possible counter drift, detected with `approved_sum` in tests. |
| D-05 | 2026-09-09 | Lock expense, then budget; recheck the cap; keep a DB `CHECK` backstop | A check alone cannot serialize read-modify-write. A lock alone depends on every future write path remembering it. Cost: same-budget approvals serialize. This is the main presentation decision. |
| D-06 | 2026-09-08 | Tailwind through `tailwindcss-rails` | Styling can live beside ERB; cost is a separate CSS build/watch step. |
| D-07 | 2026-09-09 | Separate development and production Dockerfiles | Faster local iteration and smaller production image; cost is maintaining both. |
| D-08 | 2026-09-09 | Budget month is a date pinned to its first day | Sorts and indexes cleanly; DB `CHECK` protects the canonical month value. |
| D-09 | 2026-09-09 | Simple `has_secure_password` and session auth | Devise and Rails' full auth generator add flows outside this assignment. Password reset and lockout remain out of scope. Auth screens are **not installed yet**. |
| D-10 | 2026-09-09 | Teams exist in the schema; no team management UI | A company-wide budget would mix teams. Seeds create teams; `approver_id` is nullable during team/user bootstrap. |
| D-12 | 2026-09-09 | Build browser-visible vertical slices | Model-first work left the services unreachable. Every next slice should include its route, screen, authorization, and test. |
| D-13 | 2026-10-06 | Use eight remaining workdays × seven hours; freeze after Day 5 | The old 64-hour Day 2/Day 3 calendar no longer describes the restart. Required flow, deployment, and rehearsal take priority over optional features. |

## Replacements and cautions

- Earlier notes describe a budget as unique by month/category alone. Current schema scopes it to **team, month, category**.
- Earlier notes leave approved use as stored versus derived. It is **stored** in `Budget.approved_total`.
- The Day 2 implementation pack included auth and seed code examples. They were **not installed** in the repository; use the current state page and application files for implementation status.
- The optional feature has not been chosen; keep a 4–7 hour placeholder until the required flow is deployed and verified.
