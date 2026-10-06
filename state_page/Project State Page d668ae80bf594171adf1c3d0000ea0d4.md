# Project State Page

<aside>
📘

**How to use this page**

This is the single source of truth for the assignment project. Update it at the **end of every work session**, not later.

When starting a new AI chat, paste this: *"Read my 課題プロジェクト 現状ページ and help me with X."*

Domain decided: **Pattern B — チーム予算・経費申請アプリ**. The tables below are pre-seeded with this domain's shape; fill in the blanks as you go.

Process reference: [インターン課題 End-to-End 進行フロー（チーム予算・経費申請アプリ）](https://app.notion.com/p/End-to-End-bbb16aac2d5649908b4f852ec7456253?pvs=21) · Requirements: [福岡拠点インターンシップ開発課題｜概要・目的・詳細](https://app.notion.com/p/3cded78da730804ca038f26326a24747?pvs=21)

</aside>

| Status | In progress — Day 2 of 8 |
| --- | --- |
| Phase | Phase 3 — schema, models and DB-constraint tests running green in Docker. Slice 1 (auth) not started — moved to Day 3 |
| Pattern | **B** — チーム予算・経費申請アプリ |
| Day | **Day 2 of 8** · 8h per day · **~64h total budget** |
| Hours used | ~16 / 64 (Day 2 closing) |
| Health | On track — D-04 / D-05 decided (stored `approved_total`  • row lock + `CHECK`). **Schema migrated and 24 tests green** in Docker against MySQL 9.0.1, including all 10 DB-constraint tests and the two-thread concurrency test. Slice 1 (auth) and the clean-clone script move to Day 3 |
| Feature freeze | **End of Day 6 (~48h in)** — no new features after this, only hardening, docs, and rehearsal |
| Calendar dates | *TBD — 8 working days × 8h, not necessarily consecutive; tracking by work-day, not calendar date* |
| Repo | https://github.com/zhenfeng-mf/Domain_2_Budget |
| Deployed URL | *URL* |

## 📐 Page anatomy — what each section is for

A project state page answers, in under two minutes of reading: **where am I, what did I decide, what is true right now, and what is next.** It is written for a reader with zero memory — which is both an AI chat starting fresh, and you at 11pm in week 4.

| § | Section | Purpose | Update frequency |
| --- | --- | --- | --- |
| — | Header status table | Phase, days remaining, one-line health, key URLs | Every session |
| 1 | What I'm building | 3 sentences: domain, actors, core value loop | Once (re-check daily while scope is still moving) |
| 2 | Current state | What works, what is half-built, what is untouched | Every session |
| 3 | Stack & versions | Rails/MySQL versions, key gems, hosting | When it changes |
| 4 | Data model | Models, key columns, relationships, states | When it changes |
| 5 | Invariants & enforcement | Rule → app layer → DB layer → test | When it changes |
| 6 | Decision log | Date, decision, rejected alternative, why | Append-only, immediately |
| 7 | Reversed decisions | What is explicitly no longer true | Append when you reverse something |
| 8 | Open questions | Unresolved, each with a decide-by date | Every session |
| 9 | Known bugs & debt | Including ones you choose to live with | Every session |
| 10 | Out of scope | With reasons — a graded deliverable | As decided |
| 11 | AI usage notes | Raw material for `AI_USAGE.md` | Append as it happens |
| 12 | Next 3 actions | Concrete and small | Rewrite every session |
| 13 | Session log | Date + one line | Append every session |

<aside>
🚨

**The two sections people skip and shouldn't**

- **§7 Reversed decisions** — without it, stale facts win. An old note or old chat will confidently tell you something you already changed.
- **§10 Out of scope** — directly graded, and impossible to reconstruct honestly in week 4.
</aside>

**Two structural rules that keep this page trustworthy**

1. §6 is **append-only**. Never edit an old decision; record the reversal in §7 instead. The history of your thinking is the presentation material.
2. §4 must **always match the code**. If it disagrees with the repo, this page is the thing to fix — immediately.

**Session close ritual (2 minutes)**

- [ ]  Update §2 state markers
- [ ]  Append any decisions to §6 / reversals to §7
- [ ]  Append any AI usage to §11
- [ ]  Rewrite §12 Next 3
- [ ]  Append one line to §13

## 1. What I'm building (Update every day)

> *Three sentences max. Domain, actors, core value loop.*
> 
- **Domain / pattern:**
- **Actors and what each wants:**
- **Core value loop (one sentence):**

## 2. Current state (Update every session)

Legend: ✅ done · 🚧 in progress · ⬜ not started

| Slice / area | State | Note |
| --- | --- | --- |
| `rails new` untouched first commit | ✅ | `rails new . -d mysql` — command recorded in the commit message |
| Docker Compose + MySQL 9 | ✅ | `docker compose up -d` boots db / web / css. Every rails command runs as `docker compose exec web bin/rails …`; the host has no MySQL. Gemfile changes need `docker compose build web` — `exec … bundle install` fails because the runtime image has no compiler. `script/verify_clean_clone.sh` still unexecuted — Day 3 |
| Migrations: teams / users / categories / budgets / expenses | ✅ | **All six ran green** (schema version `2026_09_09_053850`). `schema.rb` verified: 5 tables, **9 CHECK constraints**, 7 FKs, unique `(team_id, year_month, category_id)`, `teams.approver_id` nullable. `db:migrate:redo` not yet run |
| Models (5) | ✅ | generated with `bin/rails generate model … --skip-migration`, bodies pasted from the pack. All load; `MonthBucket`, enums, and every validation exercised by the suite |
| `ApproveExpense` / `RejectExpense` | 🚧 | **written ahead of their slice** — no route reaches them yet. Wired up in slices 6–7 on Day 4 (D-12) |
| DB-constraint tests (validations bypassed) | ✅ | **10 / 10 green.** MySQL refuses all nine constraint violations with validations bypassed via `insert!` / `update_columns`. The `assert_match` constraint-name assertions matched MySQL 9's real wording with no adjustment |
| Seed data | 🚧 | idempotent `db/seeds.rb` with three demo accounts written; not yet run (needs the auth slice to be worth logging into) — Day 3 |
| CI (tests + lint) | ⬜ | Day 3 |
| **Slice 1** — signup / login / logout | ⬜ | **Day 3, first task.** Code exists in pack §5 but is **not installed**: no routes, controllers or views in the repo. `bcrypt` 3.1.22 is installed and `User#has_secure_password` already works (fixtures hash passwords) |
| **Slice 2** — approver sets a budget (month + category) | ⬜ | Day 3 · I-09 (future months only) lives on this form |
| **Slice 3** — member creates an expense draft | ⬜ | Day 3 |
| **Slice 4** — member submits the draft → 申請済み | ⬜ | Day 3 · I-10 (no budget → no submission) and I-08 (利用日 freezes) live here |
| **Slice 5** — approver pending queue, remaining budget shown | ⬜ | **Day 4** · won-or-lost slice |
| **Slice 6** — approver approves → remaining updates | ⬜ | **Day 4** · wires up the already-written `ApproveExpense`; the value loop closes here |
| **Slice 7** — approver rejects | ⬜ | Day 5 |
| **Slice 8** — budget summary (budget / used / remaining) | ⬜ | Day 5 · required feature, not a stretch goal |
| **Slice 9** — member views own requests + states | ⬜ | Day 5 |
| **Budget cap enforcement + concurrency test** | ✅ | **Green.** Two threads, two connections, one ¥10,000 budget, two ¥6,000 approvals — exactly one wins. `Concurrent::CyclicBarrier` is available as assumed. The red-then-green proof (drop `.lock`, then also drop the CHECK) is still to capture — Day 4 with slice 6 |
| Authorization tests | ⬜ | Day 3, with the first controller slice |
| Deploy | ⬜ |  |
| README + demo accounts | ⬜ |  |
| `AI_USAGE.md` | ⬜ |  |
| Presentation deck | ⬜ |  |

## 3. Stack & versions (Update when it changes)

| Item | Choice | Why |
| --- | --- | --- |
| Ruby / Rails | **Ruby 3.2 / Rails 8.1** | required. Migrations are `ActiveRecord::Migration[8.1]`. Note: `to_s(:db)` was removed in Rails 7 — use `to_fs(:db)` |
| DB | **MySQL 9.0.1** | required. `YEAR_MONTH` is a reserved word (an INTERVAL unit), so any raw SQL naming `year_month` must backtick-quote it |
| Test framework | Minitest | Rails default, no extra gem — lowest setup cost in a 64h budget |
| CSS | **Tailwind** via `tailwindcss-rails` | utility classes stay next to the ERB, so no parallel stylesheet to keep consistent as screens are added — see D-06. Added after the first commit, so run locally with `bin/dev` |
| Auth approach | `has_secure_password`  • bcrypt, `session[:user_id]` | ~60 lines, no gem semantics to explain, and REQUIREMENTS §7 already puts real auth out of scope — see D-09. Rails 8's `authentication` generator rejected (brings its own Session model + reset mailers) |
| Container | Docker Compose |  |
| Hosting | *TBD* | blocked on manager discussion — see Q-11 |
| Key gems | `tailwindcss-rails` ~> 4.6, `bcrypt` 3.1.22 | that is the whole list on purpose — no Devise, no RSpec, no state-machine gem |

## 4. Data model — current truth (Update when it changes)

<aside>
⚠️

This section must always reflect the code. If it disagrees with the repo, fix this page immediately — stale model notes are the main cause of wrong AI answers and wrong presentation slides.

</aside>

| Model | Key columns | Relationships | States |
| --- | --- | --- | --- |
| `Team` | `name`, `approver_id` (nullable at DB, see D-10) | belongs_to approver (User), has_many members, budgets | — |
| `User` | `name`, `email`, `password_digest`, `role` (member / approver), `team_id` | belongs_to team, has_many expenses | — |
| `Category` | `name` | has_many budgets, expenses | — |
| `Budget` | `team_id`, `year_month` (date, always the 1st), `amount` (int yen), `approved_total` (int yen) | belongs_to team, category | — |
| `Expense` | `used_on` (date), `amount` (int yen), `purpose`, `status`, `submitted_at`, `decided_at`, `decided_by_id` | belongs_to user, category | 下書き / 申請済み / 承認済み / 却下 |

**Two schema changes from what this section said yesterday** — both from A-05: a budget is owned by a **team**, so I-02 is now `unique (team_id, year_month, category_id)`; and `teams.approver_id` is nullable at the DB because a mutual `NOT NULL` pair with `users.team_id` can never be inserted and MySQL has no deferrable constraints. Full code: [Day 2 実装パック｜migrations · models · DB制約テスト · Slice 1 (auth)](https://app.notion.com/p/Day-2-migrations-models-DB-Slice-1-auth-93c3c13d82d7475183b32464bf7b5966?pvs=21)

**The capped resource → claim shape**

|  | Capped resource (approver) | Claim (member) | Cap rule |
| --- | --- | --- | --- |
| Mine | `Budget`, one per (month, category) | `Expense` | sum of 承認済み amounts ≤ budget amount |

<aside>
🔑

**Approved used amount — stored or derived?** Decide and record here, because it determines the concurrency approach in §5.

Choice: **stored** — cached `approved_total` column on `Budget`, written only by `ApproveExpense`, with `CHECK (approved_total <= amount)` as the backstop and `FOR UPDATE` locks (expense → budget) making the read-modify-write safe. Rejected: `SUM` on read, because a `CHECK` cannot aggregate across rows, so the guarantee would live only in Ruby. See D-04 / D-05.

</aside>

## 5. Invariants & enforcement (Update when it changes)

The most important table on this page. It becomes a presentation slide directly.

| # | Rule that must always hold | App layer | DB layer | Test |
| --- | --- | --- | --- | --- |
| I-01 | **Approved total ≤ budget amount** | `ApproveExpense`: one transaction, lock expense then budget, re-read the total, refuse | `approved_total` counter + `CHECK (approved_total <= amount)` — D-04 / D-05 | ✅ green |
| I-02 | One budget per (**team**, month, category) | uniqueness scoped to team + category; rescue unique violation | unique index on `(team_id, year_month, category_id)` | ✅ green |
| I-03 | Expense amount is an integer ≥ 1 | numericality validation | signed int + `CHECK (amount >= 1)` | ✅ green |
| I-04 | Budget never lowered below approved total | validation against `approved_total` | `CHECK (amount >= 0)` and `CHECK (approved_total <= amount)` | ✅ green |
| I-05 | Approve/reject only from 申請済み, only once | state guard inside the locked transaction | enum + `CHECK (status BETWEEN 0 AND 3)` | ✅ green |
| I-06 | Member edits/deletes only own 下書き (may still fix 申請済み — A-01) | `Expense#editable_by?`  • controller policy | `user_id` FK NOT NULL | 🚧 model part written |
| I-07 | Expense charged to the month of its 利用日 | single method `MonthBucket.for`, built on `Time.zone.today` | `date` column + a CHECK that the day-of-month is 1 (the column name must be backtick-quoted in the raw SQL — reserved word) | ✅ green |
| I-08 | **利用日 is immutable once the expense leaves 下書き** | validation on `used_on_changed?` unless `status_was` is draft | *not expressible — a `CHECK` cannot see the previous value* | ✅ green |
| I-09 | **Budgets are adjustable for future months only**; no past-month budget can be created | validation on `amount_changed?` vs `MonthBucket.current` | *not expressible — a `CHECK` cannot reference "now"* | ✅ green |
| I-10 | A non-draft expense always has a matching (team, month, category) budget — A-03 | validation on every non-draft save, so re-categorising a 申請済み expense re-checks it | *not expressible across rows* | ✅ green |
| I-11 | 承認済み / 却下 are immutable — this is what bounds `approved_total` drift | validation refusing changes when `status_was` is terminal | enum column | ✅ green |

## 6. Decision log (Append immediately, never edit)

Append-only. Never edit an old entry — add a reversal in §7 instead.

| ID | Date | Decision | Rejected alternative | Why / tradeoff |
| --- | --- | --- | --- | --- |
| D-01 | 2026-09-08 | `rails new . -d mysql` — Rails 8 + MySQL, Minitest, Rails 8 default asset pipeline, generated in-place | RSpec; `--css=tailwind` at init; separate app subdirectory | Framework defaults minimize setup and maintenance cost against a 64h budget, and "I used the default because it was sufficient" is a defensible answer. CSS deliberately left open so it can be added only if the UI needs it. |
| D-06 | 2026-09-08 | Tailwind via `tailwindcss-rails` | plain CSS; Bootstrap | Utility classes stay next to the ERB, so there is no parallel stylesheet to keep consistent as screens grow. Cost: an extra build step, so `bin/dev` locally and a CSS build in the production image |
| D-07 | 2026-09-09 | Two Dockerfiles: generated multi-stage `Dockerfile` for production, `Dockerfile.dev` for compose | one single-stage image for both | Dev image optimises for iteration (volume mount, CSS watcher); prod image optimises for size and runs non-root. Cost: two files to keep in sync |

*Full decision log with D-02–D-05 lives in* [DECISIONS](https://app.notion.com/p/DECISIONS-a0a1fc1436344f228d61fa060a99c047?pvs=21) *— that page is canonical.*

<aside>
🎤

Mark entries that are strong presentation material. You need **one** decision you can talk about for two minutes with a real tradeoff — usually the concurrency one.

</aside>

## 7. ⚠️ Reversed decisions — no longer true (Append when you reverse something)

Anything here overrides older notes, older chats, and older commits.

| Reversed | Date reversed | Now | Watch out for |
| --- | --- | --- | --- |
| I-02 as "one budget per (month, category)" | 2026-09-09 | One budget per **(team, month, category)** — the unique index includes `team_id` (D-10) | Any older note, chat or slide that shows the two-column unique index, and any query that finds a budget without scoping by team |
| "Approved used amount — stored or derived, TBD" | 2026-09-09 | **Stored**: `approved_total` on `Budget` (D-04), with the lock retained (D-05) | Any chat that suggests computing the used amount with a `SUM` at read time; `Budget#approved_sum` exists only as a reconciliation check, never as the display value |
| The Day 2 build order — all models, services and model tests first, screens afterwards | 2026-09-09 | **Vertical slices** (D-12): no logic is written unless a route and screen exercise it the same session | Any plan that schedules "finish the validations" or "finish the services" as a standalone task. Every remaining task belongs to a numbered slice below |

## 8. Open questions (Update every session)

Every question gets a decide-by date. An open question with no deadline becomes a week-4 emergency.

| # | Question | Options | Decide by | Resolved as |
| --- | --- | --- | --- | --- |
| Q-01 | Is the approved used amount stored or derived? | `SUM` on read / cached `approved_total` column | Day 2 | ✅ **Stored** — D-04 |
| Q-02 | How is the budget cap enforced under concurrency? | `budget.lock!`  • re-check sum / counter + `CHECK` constraint | Day 2 | ✅ **Both**: lock (expense → budget) + `CHECK` — D-05 |
| Q-03 | Can a member edit a 申請済み expense, or only withdraw it to 下書き? | edit allowed / withdraw only | Day 2 | ✅ Edit allowed (A-01), except 利用日 which is frozen (I-08), and re-categorising re-checks A-03 (I-10) |
| Q-04 | Is 却下 terminal, or can it be edited and resubmitted? | terminal / resubmittable | Day 2 | ✅ Terminal (A-02) — enforced as I-11 |
| Q-05 | What happens if no budget exists for an expense's month + category? | block submission / allow, warn approver | Day 2 | ✅ Block submission (A-03) — enforced as I-10 |
| Q-06 | Can an approver approve their own expense? | blocked / allowed | Day 2 | ✅ Blocked (A-04) — guard in `ApproveExpense` |
| Q-07 | One approver globally, or per team? Single team or many? | single global approver / per-team | Day 2 | ✅ Per team; one approver may serve many teams (A-05). `Team` is in the schema, no CRUD UI — D-10 |
| Q-08 | Denormalize a `year_month` column, or derive the month from `used_on`? | derive / denormalize for indexing | Day 3 | ✅ Both: `Budget` stores `year_month` as a date pinned to the 1st; `Expense` derives its bucket via `MonthBucket.for` — D-08 |
| Q-09 | What if a draft's 利用日 is changed to a different month before submitting? | re-attribute silently / warn | Day 3 | ✅ Re-attribute silently while 下書き; frozen after submission (A-06 / I-08) |
| Q-10 | Test framework and CSS approach | Minitest / RSpec · Tailwind / plain CSS | Day 2 | ✅ Minitest (D-01) + Tailwind via `tailwindcss-rails` (D-06) |
| Q-11 | **Where and how to deploy publicly** — hosting choice, account/billing ownership, whether a company-provided option exists | Render / Fly.io / Railway / company-provided | **Blocked — needs manager discussion** (raise on Day 2, decide before Day 6 ends) |  |

## 9. Known bugs & accepted debt (Update every session)

| ID | Issue | Severity | Decision |
| --- | --- | --- | --- |
| B-01 |  | must fix / living with it |  |
| B-02 | `role` is accepted from signup params, so anyone can self-register as 承認者 | living with it | The spec requires registering both roles and the data is dummy-only. Stated in the README and in §10 rather than hidden; the real fix is invite-only approver creation |
| B-03 | `approved_total` is denormalised, so a future write path that skips `ApproveExpense` could desync it | living with it | Bounded by I-11 (terminal states immutable) and by `CHECK (approved_total <= amount)`; `Budget#approved_sum`  • a reconciliation assertion in the tests is the detection mechanism |
| R-01 | Deployment is a required deliverable but the hosting decision is deferred. Risk: no slack left if it turns out to be slow to arrange. | must fix | Raise with manager in Week 1 even though deploy work happens later; keep the app container-portable so hosting choice stays swappable |

> Being able to name the worst remaining bug, and why you chose to live with it, is a stronger answer than pretending there are none.
> 

## 10. Deliberately out of scope (Update as decided)

A graded deliverable — reviewers ask what you chose *not* to build and why.

| Not building | Why not | What I built instead |
| --- | --- | --- |
| Team management UI (create / rename teams, move members) | A-05 needs teams to *exist* so a budget has an owner, but managing them is not in the required feature list and would cost UI time the invariant work needs | `Team` in the schema from migration one (D-10), teams created in `db/seeds.rb` |
| Password reset, account lockout, rate limiting, email confirmation | REQUIREMENTS §7 puts real authentication out of scope; the graded value is the budget invariant | `has_secure_password`  • session cookie, one integration test covering signup → logout → login (D-09) |
| Invite-only approver creation | Would need an invitation flow; the spec explicitly asks to register both roles | Role is chosen at signup, and the risk is stated openly as B-02 |
| Withdrawing a 申請済み expense back to 下書き | A-01 lets members edit in place instead, so a withdraw transition would add a fourth edge to the state machine for no new capability | Edit-in-place on 申請済み, with 利用日 frozen (I-08) and the budget re-checked (I-10) |
| A background job to reconcile `approved_total` | Detection matters, continuous repair does not at this scale | `Budget#approved_sum` plus a reconciliation assertion in the test suite |

## 11. AI usage running notes (Append as it happens)

Collect these as they happen; they become `AI_USAGE.md`.

| Date | Tool | Purpose | Verified / corrected / rejected | How I validated it |
| --- | --- | --- | --- | --- |
| 2026-09-09 | Notion AI | Argue D-04 both ways (stored vs derived approved total) and draft the D-05 concurrency approach | **Verified, then extended** — I took the stored option, but kept the row lock the AI initially treated as the discarded alternative, because the constraint alone cannot serialise a read-modify-write | Reasoning checked against the failure I can actually reproduce: the two-thread approval test. Not accepted until that test goes red with the locks removed and green with them |
| 2026-09-09 | Notion AI | Draft the six migrations, five models, `ApproveExpense`, and the DB-constraint tests | **Verified by execution — and it contained four real errors I had to find and fix**: (1) migrations written as `Migration[8.0]` when the generator produces `[8.1]`; (2) `DAYOFMONTH(year_month)` inside a CHECK, which MySQL rejects because `YEAR_MONTH` is a reserved word; (3) `Time.current.to_s(:db)` in a fixture, removed in Rails 7; (4) a budget fixture with `approved_total: 30000` and no approved expense rows behind it | Ran it. 24 tests green against MySQL 9.0.1. Each error was diagnosed from the actual message rather than by re-prompting — e.g. MySQL error 1064 pointed at the *identifier*, not the function, which is what identified the reserved word. Error (4) was caught by my own D-04 reconciliation assertion, which is the exact drift the assertion exists to detect (B-03) |
| 2026-09-09 | Notion AI | Review my own doc pages for contradictions before coding | **Accepted — it caught two real ones**: I-02's unique index contradicted A-05 (budgets had no team scope), and a mutual `NOT NULL` between `users.team_id` and `teams.approver_id` is uninsertable in MySQL | Traced both by hand: wrote out the insert order for the FK cycle, and re-read A-05 against the index definition. Fixed in the schema and logged as D-10 |
| 2026-09-09 | Notion AI | Suggested `unsigned int` for money columns | **Rejected** | An unsigned column raises an adapter range error before the `CHECK` is ever evaluated, which would make the DB-constraint test pass for the wrong reason. Kept signed `int`  • a named `CHECK` so the test asserts the constraint by name |

<aside>
⭐

The **rejected** rows are the highest-value ones. Aim for at least three by the end.

</aside>

## 12. Next 3 actions (Rewrite every session)

<aside>
🧱

**The rule, from here to the freeze (D-12):** no business logic gets written unless a route and a screen exercise it in the same session. If a task cannot be demoed in a browser at the end of the day, it is not a task — it belongs to a slice.

</aside>

**Day 3 — the next three actions**

- [ ]  **Slice 1 — signup / login / logout (~1.5h).** Install pack §5: routes, the `Authentication` concern, Sessions/Users controllers, layout + two views, integration test. Then `db:seed` and actually sign up / log out / log in in a browser. Day 2 proved the schema; **nothing above the model layer has run yet**. Also run `db:migrate:redo` and `script/verify_clean_clone.sh` once here
- [ ]  **Slice 2 — approver sets a budget.** Route, controller, form, index; I-09 (future months only) enforced on this form, plus the authorization test that a member cannot reach it
- [ ]  **Slices 3 + 4 — member drafts an expense, then submits it.** Status visibly becomes 申請済み; I-10 blocks submission when no budget exists, I-08 freezes 利用日 after submission

**Days 4–6 — slice ladder**

| Day | Slices | Why in this order |
| --- | --- | --- |
| **Day 4** | Slice 5 (pending queue with remaining budget beside each row) + **Slice 6 (approve)**, then prove the concurrency test red → green | These two are where the assignment is won or lost. `ApproveExpense` already exists, so this is wiring and proving rather than designing |
| **Day 5** | Slices 7, 8, 9 (reject, budget summary, my requests), then the Phase 5 self-attack list including IDOR | The summary is a required feature, so it must not drift past the freeze. Attacking the app is what turns holes into talking points |
| **Day 6** | One extra done properly — **差し戻し** — then **feature freeze** | A middle option between approve and reject is a real approver need and adds one state transition, not a new subsystem |

*Days 7–8 stay as planned: deploy, README + demo accounts,* `AI_USAGE.md`*,* `TESTING.md`*, deck and rehearsal. Q-11 must be closed before Day 6 ends.*

## 13. Session log (Append every session)

One line per session. Cheap to write, invaluable in week 4.

| Date | What happened | Page updated |
| --- | --- | --- |
| 2026-09-08 | Phase 0: built the evaluation map (16 criteria → evidence) and the required-deliverables checklist. Switched planning from calendar days to an hours budget. Seeded open questions. Ran `rails new . -d mysql` and committed the untouched output as the first commit. Added Tailwind (D-06), wrote the six doc pages, and set up Docker Compose + the dev/prod Dockerfile split (D-07). | ✅ |
| 2026-09-09 | Re-based the plan on **8 working days × 8h** (same ~64h total, finer granularity). Feature freeze moved to end of Day 6. Started filling REQUIREMENTS §6 ambiguities. | ✅ |
| 2026-09-09 | **Day 2 — course correction.** Caught that Day 2 went model-first: services, the concurrency test and I-08 / I-10 / I-11 were written with no route reaching them, so the app is only demoable as far as login. Re-cut Days 3–6 into numbered vertical slices and logged it as D-12; the rule is now that no logic is written without a screen using it the same session. Kept the migrations, DB constraints and the auth slice, which are Phase 2/3 and Phase 4 slice 1. | ✅ |
| 2026-09-09 | **Day 2 — first execution.** Ran everything in Docker for the first time. Six migrations green; `schema.rb` verified with all 9 CHECK constraints and 7 FKs; **24 tests green**, including 10 DB-constraint tests (validations bypassed) and the two-thread concurrency test. Fixed four bugs found only by running the code: `Migration[8.0]` vs `[8.1]`, `DAYOFMONTH(year_month)` in a CHECK (`YEAR_MONTH` is a MySQL reserved word — needs backticks), `to_s(:db)` removed in Rails 7, and a fixture whose `approved_total` had no approved expenses behind it. Added `bcrypt` and learned that Gemfile changes need `docker compose build`, not `exec bundle install`. **Slice 1 (auth) not started** — pack §5 onward, plus the clean-clone script and the Q-11 manager conversation, all move to Day 3. | ✅ |
| 2026-09-09 | **Day 2 planning.** Resolved Q-01 / Q-02 → D-04 (stored `approved_total`) and D-05 (lock + `CHECK`), and logged D-07–D-10. Found and fixed two contradictions between A-05 and I-02 (budgets had no team scope) and the `users` ↔ `teams` `NOT NULL` cycle. Wrote six migrations, five models, the approve/reject services, 10 DB-constraint tests, the two-thread concurrency test, the auth slice, seeds and the clean-clone script — all in [Day 2 実装パック｜migrations · models · DB制約テスト · Slice 1 (auth)](https://app.notion.com/p/Day-2-migrations-models-DB-Slice-1-auth-93c3c13d82d7475183b32464bf7b5966?pvs=21). Added I-08–I-11 for the two changed rules. **Nothing executed yet** — first job on Day 3. Q-11 hosting question prepared for the manager. | ✅ |