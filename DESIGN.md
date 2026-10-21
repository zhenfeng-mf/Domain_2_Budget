# DESIGN — the rules behind the flow

## Data model

| Model | Purpose | Important fields |
| --- | --- | --- |
| `Team` | Owns budgets; points to its approver | `name`, `approver_id` |
| `User` | Member or approver in one team | `team_id`, `role`, `password_digest` |
| `Category` | Shared expense category | `name` |
| `Budget` | Cap for one team/month/category | `year_month`, `amount`, `approved_total` |
| `Expense` | Member's claim against a budget | `used_on`, `amount`, `purpose`, `status`, decision fields |

Money is integer yen. `used_on` is a date; `MonthBucket.for` determines its budget month. The unique budget index is `(team_id, year_month, category_id)`. `Team.approver_id` is temporarily nullable so a team and its approver can be created without an impossible foreign-key insertion cycle.

## State changes

| From | Action | To | Guard |
| --- | --- | --- | --- |
| — | Member creates | 下書き | Own record |
| 下書き | Member submits | 申請済み | Matching team/month/category budget exists |
| 申請済み | Assigned approver approves | 承認済み | Enough remaining budget; not own request |
| 申請済み | Assigned approver rejects | 却下 | Not own request |
| 承認済み / 却下 | Any edit or second decision | — | Refused: terminal |

A member may correct a submitted request, but cannot change its usage date. Category changes require a matching budget. Server-side controllers must scope member records to their owner and approver records to assigned teams.

## Budget cap — the key design

`Budget.approved_total` stores approved spending. `ApproveExpense` locks the expense **then** the budget, checks the current remaining amount, and updates the budget and expense in one transaction. MySQL also enforces `approved_total <= amount`. Two approvals against one budget therefore serialize; the database check is a backstop. `Budget#approved_sum` checks for counter drift in tests. Preserve expense → budget lock order in every future write path.

**Known gap:** the current decision services check the approver role and self-approval, but do not yet check whether the user is the expense team's assigned approver. Add this before creating approval/rejection routes.

## Invariants and proof

| Invariant | Current enforcement | Next proof or UI work |
| --- | --- | --- |
| Approved use never exceeds budget | Locked transaction + DB `CHECK` | Keep two-thread test; add exact-cap and one-yen-over browser cases |
| One budget per team/month/category | Validation + unique index | Exercise duplicate error in budget form |
| Positive integer expense; nonnegative budget | Validation + DB checks | Show useful form errors |
| Decisions only once from submitted | Service state guards + status DB check | Add controller and browser tests |
| Usage month and submitted-date immutability | `MonthBucket` + model validation | Add month-boundary and submitted-edit tests |
| Owner and assigned-team access | `Expense#editable_by?` partly exists | Enforce in controllers and decision services; test foreign IDs |
| Approved/rejected records stay unchanged | Model validation | Keep service and direct-edit tests |

A database `CHECK` cannot enforce owner permissions, previous-row values, or existence of a matching budget across tables. Those require application checks and request tests.
