# Task-by-task plan

**Use this with the [eight-day overview](plan.md).** One row is one small, reviewable task. Tick it only after its “Done when” check passes. The times add to seven focused hours per day; revise them after Day 1 if the baseline is broken. Tasks are in dependency order within each day.

## Day 1 — restart and authentication (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 1.1 Start Docker and prepare the database | 0.5h | MySQL and Rails start; `/up` responds. |
| [ ] 1.2 Run the existing test suite and record failures | 0.5h | Current pass/fail count is known; any environment problem is identified. |
| [ ] 1.3 Add minimal idempotent seeds | 1h | One team, its approver, one member, and categories exist; `db:seed` runs twice without duplicates. |
| [ ] 1.4 Add session helpers and private-route protection | 1.5h | Anonymous access redirects to login; a signed-in user is recognized in a focused test. |
| [ ] 1.5 Add login/logout routes, actions, and screen | 2h | A seeded user logs in and out; the session ends on logout. |
| [ ] 1.6 Add signup form and action | 1.5h | A member registers into an existing team; invalid input shows errors; login → logout → login works in a browser. |

## Day 2 — budgets (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 2.1 Add a role-aware home page | 0.5h | Member sees My requests; approver sees Budgets and Pending requests. |
| [ ] 2.2 Add an approver budget list | 1.5h | List shows only assigned teams and each budget's month, category, amount, approved use, and remaining. |
| [ ] 2.3 Add budget creation | 2h | Assigned approver can create a team/month/category budget; a member and a duplicate are refused with clear errors. |
| [ ] 2.4 Add budget editing | 1.5h | Future-month amount can change; current/past edits and amounts below approved use are refused. |
| [ ] 2.5 Add read-only budget summary | 1.5h | Both roles see their team's month/category amount, approved use, and remaining. |

## Day 3 — member requests (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 3.1 Add My requests | 1h | Member sees only their requests and each current status; a foreign ID is not readable. |
| [ ] 3.2 Add draft creation | 2h | Member saves usage date, category, integer-yen amount, and purpose; invalid values show errors. |
| [ ] 3.3 Add own-draft edit and delete | 1.5h | Owner can edit/delete drafts; another member cannot; terminal records are protected. |
| [ ] 3.4 Add a separate submit action | 2h | Draft becomes submitted once; missing matching team/month/category budget blocks it with a useful message. |
| [ ] 3.5 Walk through the member flow in a browser | 0.5h | Create → edit → submit → status display works without console commands. |

## Day 4 — approver decisions (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 4.1 Implement submitted-request corrections | 1h | Owner may change allowed fields; usage date stays fixed; category change rechecks the budget. |
| [ ] 4.2 Enforce assigned-team ownership in both decision services | 1h | An approver from another team cannot approve or reject, even by calling a service directly. |
| [ ] 4.3 Add the pending queue | 2h | Only assigned teams' submitted requests appear, with remaining budget beside each. |
| [ ] 4.4 Add approve action and result | 2h | Approval updates request and budget; success restates new remaining; overspend explains available amount. |
| [ ] 4.5 Add reject action and result | 1h | Rejection is visible to both users and does not increase approved use. |

## Day 5 — prove the flow and freeze features (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 5.1 Test authorization through request URLs | 1.5h | Anonymous users, members, foreign owners, and unassigned approvers are denied. |
| [ ] 5.2 Test the full happy path | 2h | Budget → draft → submit → approve → updated remaining passes as one integration/browser test. |
| [ ] 5.3 Test money, state, and date boundaries | 1.5h | Exact cap succeeds; one yen over, second decision, and wrong-month attribution fail correctly. |
| [ ] 5.4 Expand demo seeds | 0.5h | Demo accounts have requests in each state and a nearly exhausted budget; seeds remain idempotent. |
| [ ] 5.5 Determine the optional feature | 0.5h | Choose a user problem, feature, and acceptance check within the 4–7h estimate, or explicitly defer it. Do not implement it yet. |
| [ ] 5.6 Fix the highest-risk failure and freeze features | 1h | Required flow and critical suite pass; remaining defects are recorded and ranked. |

## Day 6 — public deployment (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 6.1 Confirm an allowed hosting option and configuration | 1h | Hosting, account ownership, MySQL, and cost limits are settled. Raise this question earlier if a manager must decide. |
| [ ] 6.2 Deploy the app and database | 3h | Public app boots and migrations complete. |
| [ ] 6.3 Smoke-test in a private browser | 1h | Demo login, budget view, submission, approval/refusal, and CSS work without local browser state. |
| [ ] 6.4 Fix deployment problems | 2h | Public demo is reliable; record URL and any remaining limitation. |

## Day 7 — reproducibility and documentation (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 7.1 Verify a clean clone | 2h | Documented Docker commands start, seed, serve CSS, and pass tests from a fresh checkout. |
| [ ] 7.2 Finish root README | 1.5h | Setup, run/test commands, demo accounts, screenshots, URL, and known limits are present. |
| [ ] 7.3 Verify root design and decisions notes | 1h | Data model, state flow, cap tradeoff, and team authorization are explained. |
| [ ] 7.4 Verify root testing rationale | 1h | Most important risks are tied to specific tests and remaining gaps. |
| [ ] 7.5 Cross-check documentation | 1h | README, requirements, design, decisions, and testing notes match the finished app; leave `AI_USAGE.md` untouched. |
| [ ] 7.6 Follow the README once | 0.5h | Commands and links match the actual repository and deployed app. |

## Day 8 — product pass and presentation (7h)

| Task | Time | Done when |
| --- | ---: | --- |
| [ ] 8.1 Polish trust-critical UI | 2h | Yen/date formatting, empty states, errors, and approval confirmation are clear on desktop and phone width. |
| [ ] 8.2 Prepare the presentation | 2h | Slides cover problem, live flow, data model, cap decision, tests, limits, and AI use. |
| [ ] 8.3 Rehearse the live demo | 1.5h | Timed run shows success and blocked overspend; backup screenshots are ready. |
| [ ] 8.4 Use contingency for the highest-risk remaining issue | 1.5h | Deployment, setup, or demo blocker is fixed; otherwise rehearse Q&A. |

**Priority rule:** if Day 4 ends without the complete decision loop, use Day 5 to finish it. Keep the optional feature as a placeholder until the required flow is deployed and verified.

## Optional feature — placeholder (4–7h)

| Task | Estimate | Done when |
| --- | ---: | --- |
| [ ] Implement optional feature: **TBD** | 4–7h | Use the scope and acceptance check chosen in task 5.5, only if time remains after required work. |

This implementation placeholder is outside the 56-hour required plan. Decide whether there is room for it after the core flow, deployment, and clean-clone check are working.
