# Project State Page

**Purpose:** the short, current answer to “what exists, what is next, and what could block us?” Update this page at the end of each work session. The [eight-day plan](plan.md) sets the schedule; this page records progress.

**Last inspected:** 2026-10-06, from repository files. No tests were rerun in that inspection. The last recorded Docker run on 2026-09-09 reported 24 passing tests, including the DB constraints and concurrent approval test.

| Item | Current position |
| --- | --- |
| Product | Team budget and expense request app (Pattern B) |
| Time remaining | Approximately **8 workdays × 7 focused hours = 56 hours**; Day 1 begins at the next work session |
| Core promise | Show the approver the true remaining budget and prevent overspending |
| Working browser flow | **None yet.** `config/routes.rb` exposes only `/up`; no auth, budget, expense, or decision screen is installed |
| Completed foundation | Rails 8/MySQL 9/Docker Compose/Tailwind setup; five domain models; six migrations with constraints; approval/rejection services; model and DB tests |
| Immediate goal | Confirm the baseline, then seed a team and implement signup/login/logout |
| Feature freeze | End of new Day 5, after the required flow and critical tests |
| Deployment | No public URL; hosting choice still open |

## What is in the repo

- **Implemented:** schema for teams, users, categories, budgets, and expenses; `MonthBucket`; integer-yen rules; expense state validations; stored `budgets.approved_total`; locked approval transaction; rejection service; fixtures and model/constraint/concurrency tests.
- **Planned but absent:** routes and screens, authentication actions, real seed data, integration tests, clean-clone script, public deployment, and final reviewer-facing documentation. `app/controllers/concerns/authentication.rb` is empty; the root documentation now contains planning drafts that need verification as the app is built.
- **Historical verification:** September 9 report says six migrations and 24 tests passed in Docker. Day 1 will confirm this on the present checkout.

**Daily task checklist:** [task checklist](tasks.md)

## Next three actions

1. Start Docker, prepare the database, run the current tests, and record any failures. Check `/up`.
2. Add minimal idempotent demo seeds: one team, its approver, one member, and categories. A signup form needs an existing team.
3. Install session handling and the signup/login/logout routes, screens, and a browser-level test. Finish with an actual login → logout → login walkthrough.

## Risks to resolve

| Risk | Next action |
| --- | --- |
| `ApproveExpense` and `RejectExpense` check the approver role but not whether that user is the expense team's assigned approver | Add the check in both services and cross-team tests before exposing decision routes (Day 4). |
| Signup that accepts an approver role from any user would grant decision powers | Decide the demo registration policy before public deployment; record its limitation clearly. |
| `approved_total` could drift if a future path changes approved expenses without the approval service | Keep one write path and the reconciliation assertion (`Budget#approved_sum`). |
| Hosting and cost approval are unresolved | Resolve the allowed hosting option before Day 6; use only permitted resources and dummy data. |
| The previous plan said seeds and auth code were written, but they exist only in an old planning page | Use repository files as the source of truth; update this page after each session. |

## Decisions worth explaining

- Budget and expense are separate: cap versus claim.
- Money is integer yen; usage date determines the budget month.
- Each budget is unique per **team, month, category**.
- Approved use is stored on the budget. Approval locks the expense, then the budget, updates both in one transaction, and relies on a database `CHECK` as a backstop.
- Approved and rejected expenses are terminal; submitted expenses may be corrected except for their usage date.

See [Design](../DESIGN.md) and [Decisions](../DECISIONS.md) for the reasoning.

## Session log

| Date | Result |
| --- | --- |
| 2026-09-08 to 2026-09-09 | Project planned; Rails/Docker foundation, schema, models, services, and model tests added. Last recorded Docker run: 24 tests passing. |
| 2026-10-06 | Resumed by inspecting the repo. Replaced the old 64-hour schedule with an eight-day, 56-hour plan. No application code or tests changed in this documentation pass. |

**Session close:** update the current position, next three actions, risks, and one session-log row. Record new design choices in DECISIONS. Leave `AI_USAGE.md` unchanged.
