# Eight-day end-to-end plan — team budget and expense app

**Time available:** eight remaining workdays × seven focused hours = **56 hours**. Count workdays from the next work session; the old Day 2/Day 3 labels are historical. The [current status](status.md) records what is true now.

**Detailed checklist:** [task checklist](tasks.md)

## The result to build

An approver sets a team budget. A member drafts and submits an expense. The team's approver sees the remaining budget beside the request, approves or rejects it, and both users see the result. An approval that would overspend is refused, including when two approvals run concurrently.

## Daily plan

| Day | Seven-hour allocation | End-of-day check |
| --- | --- | --- |
| **1 — Restart and auth** | 1h start Docker and rerun tests; 1h minimal idempotent seeds; 1.5h session handling; 2h login/logout; 1.5h signup and browser check | A member and approver can enter and leave the app. Record baseline failures. |
| **2 — Budgets** | 0.5h role-aware home; 1.5h budget list; 2h create form; 1.5h edit rules; 1.5h summary | Approver sets a budget; both roles see amount, approved use, and remaining. |
| **3 — Member flow** | 1h My requests; 2h draft creation; 1.5h own-draft edit/delete; 2h submit and missing-budget error; 0.5h browser walkthrough | Member submits a request and sees its status. |
| **4 — Approver flow** | 1h submitted-request edit rule; 1h team ownership checks in both decision services; 2h pending queue with remaining budget; 2h approve action; 1h reject action | Complete budget → request → decision flow works in a browser. |
| **5 — Prove and freeze** | 1.5h authorization tests; 2h full-flow test; 1.5h cap, duplicate-decision and month-boundary tests; 0.5h demo seeds; 0.5h determine optional feature; 1h fix highest-risk failure | Required flow and critical tests pass. Optional feature chosen or deferred. **Feature freeze.** |
| **6 — Deploy** | 1h settle hosting/configuration; 3h deploy; 1h private-browser smoke test; 2h deployment fixes or contingency | Public URL runs the core loop with demo data. |
| **7 — Handoff** | 2h fresh-clone setup check; 1.5h root README; 1h verify design/decisions; 1h verify testing rationale; 1h cross-check documentation; 0.5h verify instructions | A reviewer can run and understand the repo without help. |
| **8 — Present** | 2h UX/error-message polish; 2h presentation; 1.5h timed demo rehearsal; 1.5h contingency | Show the normal flow and blocked overspend, then explain the design. |

## Checkpoints within the build

Each item should end with a browser check or a focused test. Do not move to the next checkpoint with a known broken required path.

1. **Enter:** seed a team, approver, member, and categories; implement signup, login, logout, and a role-aware home page. Seed twice to prove idempotence.
2. **Budget:** approver lists, creates, and edits team budgets. Members cannot manage them. Both roles can read the team summary.
3. **Request:** member lists only their own expenses; creates, edits, and deletes own drafts; submits a draft. A missing matching budget blocks submission. Submitted edits obey the frozen usage-date rule.
4. **Decision:** restrict both services and the queue to the assigned team approver. Show remaining budget beside each pending request. Approve/reject once; show the updated state and remaining amount.
5. **Proof:** test the full flow, foreign IDs, cross-team access, exact cap, one yen over, duplicate decisions, and month boundaries. Keep the existing two-thread concurrency test.
6. **Handoff:** realistic demo seeds, fresh-clone setup, public URL, root README, design/testing/AI notes, and a rehearsed presentation.

## Priorities if time slips

Finish the required flow before polishing. If Day 4 ends without a working approval loop, use Day 5 to complete it. Preserve deployment, fresh-clone verification, and rehearsal time. Choose or defer the optional feature on Day 5; implement it only if time permits after the required flow is deployed and verified.

## Optional feature — placeholder

**Feature: TBD. Estimate: 4–7 hours.** Day 5 includes a 30-minute task to choose its user problem, scope, and acceptance check, or defer it. Implementation time is **not included** in the 56-hour daily allocation. Add it only if enough time is saved without reducing deployment, documentation, or rehearsal time.

## Submission check

- [ ] Required member and approver flows work, including empty/error/success states.
- [ ] Business rules have app-layer checks, database constraints where possible, and focused tests.
- [ ] Demo data, setup instructions, root README, and public URL are verified from a fresh browser or checkout.
- [ ] `DESIGN.md`, `DECISIONS.md`, `TESTING.md`, and `AI_USAGE.md` in the repo explain choices and evidence.
- [ ] No new paid plan, metered API key, or billing-enabled cloud project is needed; only dummy data is used.
