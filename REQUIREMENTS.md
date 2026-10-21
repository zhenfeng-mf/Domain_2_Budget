# REQUIREMENTS — team budget and expense app

## Problem and users

Small teams manage budgets and expense approvals in chat and spreadsheets. An approver needs to see the **true remaining budget at the decision point** and be confident that approval cannot overspend it.

| User | Needs to do | Must be prevented from doing |
| --- | --- | --- |
| **Member (メンバー)** | Draft, edit/delete own draft, submit, and track own requests | Manage budgets, decide requests, or read/change another member's records |
| **Approver (承認者)** | Set budgets for assigned teams; see pending requests and remaining balance; approve or reject | Decide another team's request or approve their own request |

## Required browser flow

1. Register and log in as either role; log out.
2. Approver sets a budget for a team, month, and category.
3. Member creates an expense draft with usage date (利用日), category, integer-yen amount, and purpose; then submits it.
4. The team's approver sees the request **with remaining budget beside it**, approves or rejects once, and sees the result.
5. Both roles see budget amount, approved use, and remaining by month/category. Members see their own requests and states.

The value moment is a successful approval that restates the **new remaining amount**. Refusal must say how much was available.

## Business rules

| Rule | Chosen behavior |
| --- | --- |
| Budget identity | One per **team, month, category**. |
| Money | Integer yen; expense ≥ ¥1, budget ≥ ¥0, remaining never negative. |
| Month | Expense counts against the month of its usage date. `Budget.year_month` is the first day of that month. |
| States | 下書き → 申請済み → 承認済み or 却下. Decisions happen only once and only from 申請済み. |
| Editing | Member can edit/delete own draft. A submitted request may be corrected, but its usage date is frozen; approved/rejected requests are terminal. |
| Missing budget | Submission is blocked if its team/month/category has no budget. |
| Approver | May serve more than one team, but may decide only requests for teams assigned to them; cannot approve their own request. |
| Budget changes | No past-month budget creation; only future-month amounts can be adjusted; never lower below approved use. |

The submitted-edit, terminal-rejection, missing-budget, and per-team-approver rules resolve gaps in the original spec. They are recorded as project choices, not presented as explicit original requirements.

## Optional feature — placeholder

**TBD; estimate 4–7 hours.** Determine the user problem, feature, and acceptance check in Day 5 task 5.5, or defer it. Build it only if time remains after the required work. See [docs/tasks.md](docs/tasks.md).

## Outside this 56-hour build

Team management UI, password reset, email confirmation, invite system, multi-level approvals, and attachments. Teams and demo users come from seeds. The app still needs server-side session and role checks. Public signup that can choose “approver” is a known demo security limitation to decide before deployment.
