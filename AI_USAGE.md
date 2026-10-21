# AI_USAGE — suggestions and verification

Use dummy data only. Record tool, purpose, what was accepted or rejected, and how the result was checked. Keep adding verified examples here before submission.

| Date | Tool | Work | Verification or correction |
| --- | --- | --- | --- |
| 2026-09-08 | Notion AI | Mapped the assignment's evaluation criteria and planned deliverables | Rechecked the map against the original assignment. |
| 2026-09-09 | Notion AI | Compared stored and derived approved totals and proposed concurrency handling | Chose a stored total **and kept a row lock**; the check constraint cannot serialize a read-modify-write. Verified with a two-thread test. |
| 2026-09-09 | Notion AI | Drafted migrations, models, and DB tests | Running in Docker exposed four corrections: Rails migration version 8.1; quoting MySQL's `year_month` identifier; replacing removed `to_s(:db)`; and matching fixture `approved_total` to approved expense rows. |
| 2026-09-09 | Notion AI | Reviewed design notes for contradictions | Fixed the budget unique key to include `team_id` and avoided a mutual non-null team/user foreign-key insertion cycle. |
| 2026-09-09 | Notion AI | Suggested unsigned integer money columns | Rejected: adapter range checks could hide whether the named DB `CHECK` was actually exercised. Kept signed integers plus checks. |

## How to validate future AI work

- Review each diff and be able to explain it.
- Run the relevant test and browser path; add a test when a business rule changes.
- Check version-specific claims against official documentation.
- Reproduce a failure before accepting an explanation or fix.
- Log a rejected suggestion with the reason and the alternative chosen.
