# Day 2 実装パック｜migrations · models · DB制約テスト · Slice 1 (auth)

<aside>
⚠️

**None of this code has been executed.** I have no access to your repo or a MySQL 9 instance, so everything below is written to be pasted and then proven by `bin/rails test` and the clean-clone script in §7. Treat any test that does not go red-then-green as unverified.

Day 2 · 2026-09-09 · Pattern B · decisions logged as D-04, D-05, D-07–D-10 in [DECISIONS](DECISIONS%20a0a1fc1436344f228d61fa060a99c047.md)

</aside>

## 0. Two schema blockers I had to resolve first

<aside>
🚧

**Blocker 1 — the budget has no scope.** REQUIREMENTS A-05 says a team has one approver and many members, and that an approver can serve several teams. That makes **the team the owner of a budget**. But DESIGN §4 and State §5 define I-02 as `unique (year_month, category_id)` — which means all teams in the company share one 2026-09 交通費 budget. That cannot be right.

**Resolved:** `budgets` carries `team_id`, and I-02 becomes `unique (team_id, year_month, category_id)`. No team CRUD UI — teams come from seeds. Logged as **D-10**.

</aside>

<aside>
🔁

**Blocker 2 — `users` ↔ `teams` is a NOT NULL cycle.** If `users.team_id` is `NOT NULL` and `teams.approver_id` is `NOT NULL`, neither row can ever be inserted first. MySQL has no deferrable constraints, so this is not solvable at the DB layer.

**Resolved:** `users.team_id` stays `NOT NULL`; `teams.approver_id` is nullable at the DB and enforced in the app (`validates :approver, presence: true, on: :update`), plus `Budget` refuses to be created for a team with no approver. Two-phase create in seeds. This is a genuinely good 30-second answer if a reviewer asks "why is this column nullable?" — logged in **D-10**.

</aside>

**Also flagged, no code change needed today:** A-01 allows editing a 申請済み expense, and your new rule freezes 利用日 once it leaves 下書き. Those two coexist, but editing a 申請済み expense can change its **category** — which repoints it at a different budget and can break A-03. So the A-03 budget-existence check must run on **every** save of a non-draft expense, not only at submit. That is I-10 below.

## 1. D-04 / D-05 — the decision, and the two-minute version

**Chosen: stored.** `budgets.approved_total` (integer yen), mutated only inside `ApproveExpense`, guarded by `CHECK (approved_total <= amount)`. Concurrency handled by `SELECT … FOR UPDATE` on the expense, then the budget, inside one transaction, with the sum re-checked after the lock.

|  | Stored — `approved_total`  • CHECK (chosen) | Derived — `SUM`  • `lock!` only (rejected) |
| --- | --- | --- |
| Where the guarantee lives | In MySQL. The row physically cannot exist in an overspent state. | In Ruby. Correct today; one future code path that approves without the lock breaks it silently. |
| Can a DB constraint express it? | Yes — once the total is one column on one row. | **No.** A `CHECK` cannot aggregate across rows. This is the whole argument. |
| Failure mode | Drift between the column and the truth. | Overspend under concurrency. |
| Why that failure mode is acceptable | 承認済み is terminal (A-02), so the counter only ever grows, and exactly one service writes it. A reconciliation test asserts `approved_total == SUM(承認済み)`. | It is not — overspending is the one thing this app exists to prevent. |
| Cost accepted | Denormalised column, a reconciliation story, and approvals for one budget serialise. | — |

<aside>
🎤

**The presentation script (say it in this order)**

1. The rule is "the sum of approved expenses must never exceed the budget". Two approvers clicking 承認 at the same moment both read the old sum, both pass validation, and the team overspends. A validation cannot stop it, because it reads outside the write.
2. My first instinct was to keep the total derived and take a row lock. That is correct — but the correctness lives in application code, so it is one careless future code path away from being wrong.
3. So I moved the guarantee down a layer. I store `approved_total` on the budget and add `CHECK (approved_total <= amount)`. Now MySQL itself refuses to be overspent — even from the Rails console, even from a migration.
4. The lock did not go away. It is what turns a raw constraint violation into a correct, serialised approval and a readable error message: lock the expense, lock the budget, re-check the sum, then write. Lock order is always expense → budget, so two concurrent approvals can never deadlock.
5. The price is a denormalised column that could drift. I bounded it: 承認済み is terminal, one service owns the write, and a test asserts the column equals the `SUM`. That is a tradeoff I can defend — the alternative traded away the only guarantee that mattered.

**Proof:** `test/models/concurrent_approval_test.rb` — two threads, two real connections, one ¥10,000 budget, two ¥6,000 expenses. Exactly one wins.

</aside>

## 2. Migrations (2.5h block, part 1)

Six migrations, in this order. Generate the files, then paste the bodies:

```bash
bin/rails generate migration CreateTeams
bin/rails generate migration CreateUsers
bin/rails generate migration AddApproverToTeams
bin/rails generate migration CreateCategories
bin/rails generate migration CreateBudgets
bin/rails generate migration CreateExpenses
```

```ruby
# db/migrate/xxxxxxxx_create_teams.rb
class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :teams, :name, unique: true
  end
end
```

```ruby
# db/migrate/xxxxxxxx_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :name,            null: false
      t.string  :email,           null: false
      t.string  :password_digest, null: false
      t.integer :role,            null: false, default: 0  # 0 member / 1 approver
      t.references :team, null: false, foreign_key: true    # I-06 ownership chain
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role BETWEEN 0 AND 1", name: "chk_users_role_in_enum"
  end
end
```

```ruby
# db/migrate/xxxxxxxx_add_approver_to_teams.rb
class AddApproverToTeams < ActiveRecord::Migration[8.1]
  def change
    # Deliberately nullable: users.team_id is NOT NULL, so a NOT NULL approver_id
    # would make the first insert of either table impossible, and MySQL has no
    # deferrable constraints. Presence is enforced in Team (on: :update) and by
    # Budget refusing a team with no approver. See D-10.
    add_reference :teams, :approver, null: true,
                  foreign_key: { to_table: :users }
  end
end
```

```ruby
# db/migrate/xxxxxxxx_create_categories.rb
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :categories, :name, unique: true
  end
end
```

```ruby
# db/migrate/xxxxxxxx_create_budgets.rb
class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :team,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.date    :year_month,     null: false  # always the 1st of the month (D-08)
      t.integer :amount,         null: false  # integer yen (D-02)
      t.integer :approved_total, null: false, default: 0  # D-04
      t.timestamps
    end

    # I-02 — one budget per (team, month, category)
    add_index :budgets, %i[team_id year_month category_id],
              unique: true, name: "idx_budgets_unique_team_month_category"

    # I-04 — budget is never negative and never below what is already approved
    add_check_constraint :budgets, "amount >= 0",
                         name: "chk_budgets_amount_non_negative"
    add_check_constraint :budgets, "approved_total >= 0",
                         name: "chk_budgets_approved_total_non_negative"
    # I-01 — the whole point of D-04: the DB itself refuses to be overspent
    add_check_constraint :budgets, "approved_total <= amount",
                         name: "chk_budgets_approved_total_within_amount"
    # D-08 — a month bucket can only ever be the 1st.
    # The column name MUST be backtick-quoted here. YEAR_MONTH is a reserved
    # word in MySQL (an INTERVAL unit), so the bare identifier is a syntax
    # error inside a raw CHECK expression. create_table and add_index quote
    # identifiers automatically; this hand-written string does not.
    # Verified against MySQL 9.0.1 on 2026-09-09.
    add_check_constraint :budgets, "DAY(`year_month`) = 1",
                         name: "chk_budgets_year_month_first_of_month"
  end
end
```

```ruby
# db/migrate/xxxxxxxx_create_expenses.rb
class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user,     null: false, foreign_key: true  # I-06
      t.references :category, null: false, foreign_key: true
      t.date    :used_on, null: false          # 利用日 is a calendar day (D-03)
      t.integer :amount,  null: false          # integer yen (D-02)
      t.string  :purpose, null: false, limit: 255
      t.integer :status,  null: false, default: 0  # 0 下書き 1 申請済み 2 承認済み 3 却下
      t.datetime :submitted_at
      t.datetime :decided_at
      t.references :decided_by, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    # I-03 — ≥ ¥1, enforced by the database, not only by numericality
    add_check_constraint :expenses, "amount >= 1",
                         name: "chk_expenses_amount_at_least_1_yen"
    # I-05 — no status outside the enum can ever be written
    add_check_constraint :expenses, "status BETWEEN 0 AND 3",
                         name: "chk_expenses_status_in_enum"
    add_check_constraint :expenses, "CHAR_LENGTH(purpose) >= 1",
                         name: "chk_expenses_purpose_present"

    add_index :expenses, %i[user_id status]                # 自分の申請一覧
    add_index :expenses, %i[category_id used_on status]     # 承認キュー・月次集計
  end
end
```

<aside>
🧾

**Why signed `int` and not `unsigned`?** An unsigned column makes a negative write blow up as a range error in the adapter, before it is ever a constraint violation — which makes the DB-layer test in §4 prove the wrong thing. Signed column + explicit `CHECK` means the test asserts the exact constraint by name. Worth one sentence in the presentation.

**What MySQL cannot express here.** I-08 (利用日 immutable after 下書き), I-09 (future-months-only adjustment) and I-10 (a matching budget must exist) all compare a row to its own previous value or to `now`, which a `CHECK` cannot do. They are app-layer + test, and §5 of the State page says so honestly. A `BEFORE UPDATE` trigger could push I-08 into the DB, but triggers are invisible to `schema.rb` and would force `schema_format = :sql` — not worth it inside 64h. Knowing *which* invariants the DB can hold is itself a good answer.

</aside>

## 3. Models & the approve service (2.5h block, part 2)

```ruby
# app/models/concerns/month_bucket.rb
# I-07 — the single month-bucketing method. Nothing else may call beginning_of_month.
module MonthBucket
  def self.for(date)
    raise ArgumentError, "date is required" if date.nil?
    date.to_date.beginning_of_month
  end

  def self.current
    self.for(Time.zone.today) # never Date.today
  end

  def self.label(date)
    self.for(date).strftime("%Y-%m")
  end
end
```

```ruby
# app/models/team.rb
class Team < ApplicationRecord
  belongs_to :approver, class_name: "User", optional: true
  has_many :members, class_name: "User", dependent: :restrict_with_error
  has_many :budgets, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  # nullable only for the duration of the bootstrap insert (D-10)
  validates :approver, presence: true, on: :update
  validate  :approver_must_have_approver_role

  private

  def approver_must_have_approver_role
    return if approver.nil?
    errors.add(:approver, "は承認者ロールである必要があります") unless approver.approver?
  end
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  belongs_to :team
  has_many :expenses, dependent: :restrict_with_error
  has_many :approving_teams, class_name: "Team", foreign_key: :approver_id,
           inverse_of: :approver, dependent: :restrict_with_error

  enum :role, { member: 0, approver: 1 }, validate: true

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  has_many :budgets,  dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
end
```

```ruby
# app/models/budget.rb
class Budget < ApplicationRecord
  belongs_to :team
  belongs_to :category

  validates :year_month, presence: true,
            uniqueness: { scope: %i[team_id category_id] }          # I-02 app layer
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :approved_total,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :year_month_must_be_first_of_month                        # D-08
  validate :amount_must_cover_approved_total                         # I-04
  validate :team_must_have_an_approver, on: :create                  # D-10
  validate :past_months_cannot_be_created, on: :create               # I-09
  validate :only_future_months_may_change_amount, on: :update        # I-09

  def self.for(team:, category:, on:)
    find_by(team: team, category: category, year_month: MonthBucket.for(on))
  end

  def remaining
    amount - approved_total
  end

  # Reconciliation: the truth D-04 promises to track.
  def approved_sum
    Expense.approved
           .where(category_id: category_id)
           .where(user_id: team.members.select(:id))
           .where(used_on: year_month..year_month.end_of_month)
           .sum(:amount)
  end

  private

  def year_month_must_be_first_of_month
    return if year_month.blank?
    return if year_month == MonthBucket.for(year_month)
    errors.add(:year_month, "は月初日で保存してください")
  end

  def amount_must_cover_approved_total
    return if amount.blank? || approved_total.blank?
    return if amount >= approved_total
    errors.add(:amount, "は承認済み合計 #{approved_total} 円を下回れません（I-04）")
  end

  def team_must_have_an_approver
    errors.add(:team, "に承認者が設定されていません") if team.present? && team.approver_id.nil?
  end

  def past_months_cannot_be_created
    return if year_month.blank?
    return if year_month >= MonthBucket.current
    errors.add(:year_month, "は過去月の予算を作成できません（I-09）")
  end

  def only_future_months_may_change_amount
    return unless amount_changed?          # approved_total updates are unaffected
    return if year_month.present? && year_month > MonthBucket.current
    errors.add(:year_month, "は翌月以降の予算のみ変更できます（I-09）")
  end
end
```

```ruby
# app/models/expense.rb
class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :decided_by, class_name: "User", optional: true

  enum :status, { draft: 0, submitted: 1, approved: 2, rejected: 3 }, validate: true

  scope :pending, -> { where(status: :submitted).order(:submitted_at) }

  validates :used_on, presence: true
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 1 } # I-03
  validates :purpose, presence: true, length: { maximum: 255 }
  validate :used_on_is_immutable_once_out_of_draft   # I-08 (your changed rule)
  validate :terminal_states_are_immutable            # I-11 protects approved_total
  validate :matching_budget_must_exist, if: :requires_budget?  # I-10 / A-03

  def year_month
    MonthBucket.for(used_on)
  end

  def budget
    return nil if used_on.blank? || category_id.blank?
    Budget.for(team: user.team, category: category, on: used_on)
  end

  def editable_by?(actor)
    # A-01: a member may still fix a 申請済み request; 承認済み/却下 are terminal (A-02)
    user_id == actor.id && (draft? || submitted?)
  end

  private

  def requires_budget?
    !draft? && used_on.present? && category_id.present? && user_id.present?
  end

  def matching_budget_must_exist
    return if budget.present?
    errors.add(:base,
      "#{MonthBucket.label(used_on)} の #{category&.name} に予算が未設定のため申請できません（A-03）")
  end

  def used_on_is_immutable_once_out_of_draft
    return if new_record? || !used_on_changed?
    return if status_was == "draft"   # a draft may still move months (A-06)
    errors.add(:used_on, "は申請後は変更できません（I-08）")
  end

  def terminal_states_are_immutable
    return if new_record?
    return unless status_was.in?(%w[approved rejected])
    return if (changed - %w[updated_at]).empty?
    errors.add(:base, "承認済み・却下の申請は変更できません（I-11 / A-02）")
  end
end
```

```ruby
# app/services/approve_expense.rb
# The only place in the codebase allowed to write budgets.approved_total (D-04).
class ApproveExpense
  class Refused < StandardError; end

  def self.call(expense_id:, approver:)
    new(expense_id: expense_id, approver: approver).call
  end

  def initialize(expense_id:, approver:)
    @expense_id = expense_id
    @approver = approver
  end

  # Lock order is ALWAYS expense -> budget. Every future path must keep this
  # order or concurrent approvals can deadlock instead of serialising.
  def call
    Expense.transaction do
      expense = Expense.lock.find(@expense_id)

      raise Refused, "承認者のみ承認できます" unless @approver.approver?
      raise Refused, "申請済みの申請のみ承認できます（I-05）" unless expense.submitted?
      raise Refused, "自分の申請は承認できません（A-04）" if expense.user_id == @approver.id

      budget = Budget.lock.find_by(
        team_id:     expense.user.team_id,
        category_id: expense.category_id,
        year_month:  expense.year_month
      )
      raise Refused, "対象月・カテゴリの予算がありません（A-03）" if budget.nil?

      # Re-read AFTER the lock. This is the line the race condition dies on.
      if budget.approved_total + expense.amount > budget.amount
        raise Refused, "残予算 #{budget.remaining} 円を超えるため承認できません（I-01）"
      end

      budget.update!(approved_total: budget.approved_total + expense.amount)
      expense.update!(status: :approved, decided_at: Time.current, decided_by: @approver)
      expense
    end
  end
end
```

```ruby
# app/services/reject_expense.rb
class RejectExpense
  class Refused < StandardError; end

  def self.call(expense_id:, approver:)
    Expense.transaction do
      expense = Expense.lock.find(expense_id)
      raise Refused, "承認者のみ操作できます" unless approver.approver?
      raise Refused, "申請済みの申請のみ却下できます（I-05）" unless expense.submitted?
      raise Refused, "自分の申請は操作できません（A-04）" if expense.user_id == approver.id
      expense.update!(status: :rejected, decided_at: Time.current, decided_by: approver)
      expense
    end
  end
end
```

## 4. Model tests that prove the DB refuses the write (1.5h)

<aside>
🎯

The point of this block: every test below **bypasses ActiveRecord validations** (`insert!`, `update_columns`) so the statement actually reaches MySQL. If you deleted the migration's `CHECK` and only kept the validation, each of these must fail. Run them that way once — a test you have seen go red is worth ten you haven't.

</aside>

```yaml
# test/fixtures/teams.yml
alpha:
  name: Alpha
  approver: hanako
```

```yaml
# test/fixtures/users.yml
taro:
  name: 太郎
  email: taro@example.com
  password_digest: <%= BCrypt::Password.create("password", cost: 4) %>
  role: member
  team: alpha

jiro:
  name: 次郎
  email: jiro@example.com
  password_digest: <%= BCrypt::Password.create("password", cost: 4) %>
  role: member
  team: alpha

hanako:
  name: 花子
  email: hanako@example.com
  password_digest: <%= BCrypt::Password.create("password", cost: 4) %>
  role: approver
  team: alpha
```

```yaml
# test/fixtures/categories.yml
travel:
  name: 交通費
books:
  name: 書籍費
```

```yaml
# test/fixtures/budgets.yml
current_travel:
  team: alpha
  category: travel
  year_month: <%= Time.zone.today.beginning_of_month.to_s %>
  amount: 100000
  approved_total: 30000

next_books:
  team: alpha
  category: books
  year_month: <%= Time.zone.today.next_month.beginning_of_month.to_s %>
  amount: 50000
  approved_total: 0
```

```yaml
# test/fixtures/expenses.yml
taro_draft:
  user: taro
  category: travel
  used_on: <%= Time.zone.today.to_s %>
  amount: 1200
  purpose: 顧客訪問の交通費
  status: draft

taro_submitted:
  user: taro
  category: travel
  used_on: <%= Time.zone.today.to_s %>
  amount: 5000
  purpose: 出張の交通費
  status: submitted
  submitted_at: <%= Time.current.to_fs(:db) %>  # to_s(:db) was removed in Rails 7

# This row EXISTS to back budgets(:current_travel).approved_total = 30000.
# Without it the fixture set starts in a state the app could never produce,
# and the D-04 reconciliation assertion in invariant_app_layer_test.rb fails
# (expected 35000, actual 5000). Any change to a budget fixture's
# approved_total must be matched by approved expense rows here.
taro_approved:
  user: taro
  category: travel
  used_on: <%= Time.zone.today.to_s %>
  amount: 30000
  purpose: 承認済みの交通費
  status: approved
  submitted_at: <%= 2.days.ago.to_fs(:db) %>
  decided_at: <%= 1.day.ago.to_fs(:db) %>
  decided_by: hanako
```

```ruby
# test/models/db_constraints_test.rb
require "test_helper"

# Every test here writes THROUGH the validations on purpose.
class DbConstraintsTest < ActiveSupport::TestCase
  # I-02 — unique index on (team_id, year_month, category_id)
  test "DB rejects a duplicate budget for the same team, month and category" do
    b = budgets(:current_travel)
    assert_raises ActiveRecord::RecordNotUnique do
      Budget.insert!({
        team_id: b.team_id, category_id: b.category_id, year_month: b.year_month,
        amount: 1, approved_total: 0,
        created_at: Time.current, updated_at: Time.current
      })
    end
  end

  # I-01 — chk_budgets_approved_total_within_amount
  test "DB rejects an approved_total above the budget amount" do
    b = budgets(:current_travel)
    error = assert_raises ActiveRecord::StatementInvalid do
      b.update_columns(approved_total: b.amount + 1)
    end
    assert_match "chk_budgets_approved_total_within_amount", error.message
  end

  # I-04 — lowering the cap under what is already approved
  test "DB rejects lowering a budget amount below its approved_total" do
    b = budgets(:current_travel) # approved_total 30_000
    assert_raises ActiveRecord::StatementInvalid do
      b.update_columns(amount: b.approved_total - 1)
    end
  end

  # I-04 — chk_budgets_amount_non_negative
  test "DB rejects a negative budget amount" do
    assert_raises ActiveRecord::StatementInvalid do
      budgets(:next_books).update_columns(amount: -1)
    end
  end

  # I-03 — chk_expenses_amount_at_least_1_yen
  test "DB rejects an expense amount of 0 yen" do
    error = assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(amount: 0)
    end
    assert_match "chk_expenses_amount_at_least_1_yen", error.message
  end

  test "DB rejects a negative expense amount" do
    assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(amount: -500)
    end
  end

  # I-05 — chk_expenses_status_in_enum
  test "DB rejects a status outside the state machine" do
    assert_raises ActiveRecord::StatementInvalid do
      expenses(:taro_draft).update_columns(status: 9)
    end
  end

  # I-06 — ownership can never be lost
  test "DB rejects an expense with no owner" do
    assert_raises ActiveRecord::NotNullViolation do
      expenses(:taro_draft).update_columns(user_id: nil)
    end
  end

  test "DB rejects an expense owned by a non-existent user" do
    assert_raises ActiveRecord::InvalidForeignKey do
      expenses(:taro_draft).update_columns(user_id: 999_999_999)
    end
  end

  # D-08 — a month bucket is always the 1st
  test "DB rejects a mid-month year_month" do
    assert_raises ActiveRecord::StatementInvalid do
      budgets(:next_books).update_columns(year_month: Time.zone.today.next_month.change(day: 15))
    end
  end
end
```

```ruby
# test/models/invariant_app_layer_test.rb
require "test_helper"

# The three invariants MySQL cannot express, and the two rules that changed
# from the spec.
class InvariantAppLayerTest < ActiveSupport::TestCase
  # I-08 — 利用日 is immutable once the expense leaves 下書き
  test "used_on can move while the expense is a draft" do
    e = expenses(:taro_draft)
    assert e.update(used_on: Time.zone.today - 3)
  end

  test "used_on cannot be changed once submitted" do
    e = expenses(:taro_submitted)
    assert_not e.update(used_on: Time.zone.today - 40)
    assert_includes e.errors[:used_on].join, "申請後"
  end

  # I-09 — budgets are adjustable for future months only
  test "a future month budget can be adjusted" do
    assert budgets(:next_books).update(amount: 60_000)
  end

  test "the current month budget cannot be adjusted" do
    assert_not budgets(:current_travel).update(amount: 200_000)
  end

  test "a past month budget cannot be created" do
    b = Budget.new(team: teams(:alpha), category: categories(:books),
                   year_month: MonthBucket.current - 1.month, amount: 1_000)
    assert_not b.valid?
  end

  # I-10 / A-03 — no submission without a matching budget
  test "an expense cannot be submitted when no budget exists for its month and category" do
    e = Expense.new(user: users(:taro), category: categories(:books),
                    used_on: Time.zone.today, amount: 1_000,
                    purpose: "予算のない月", status: :submitted)
    assert_not e.valid?
    assert_match "予算が未設定", e.errors.full_messages.join
  end

  test "changing the category of a submitted expense re-checks the budget" do
    e = expenses(:taro_submitted)
    assert_not e.update(category: categories(:books)) # no current-month books budget
  end

  # I-11 — terminal states protect the counter
  test "an approved expense cannot be edited" do
    e = expenses(:taro_submitted)
    ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    assert_not e.reload.update(amount: 1)
  end

  # A-04
  test "an approver cannot approve their own expense" do
    own = Expense.create!(user: users(:hanako), category: categories(:travel),
                          used_on: Time.zone.today, amount: 1_000,
                          purpose: "自分の申請", status: :submitted,
                          submitted_at: Time.current)
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: own.id, approver: users(:hanako))
    end
  end

  # I-05 — approve twice
  test "approve cannot run twice on the same request" do
    e = expenses(:taro_submitted)
    ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: e.id, approver: users(:hanako))
    end
  end

  # I-01 happy path + counter correctness
  test "approving increases approved_total and shrinks remaining" do
    budget = budgets(:current_travel)
    assert_difference -> { budget.reload.approved_total }, 5_000 do
      ApproveExpense.call(expense_id: expenses(:taro_submitted).id, approver: users(:hanako))
    end
    assert_equal budget.approved_total, budget.approved_sum, "counter must match the SUM (D-04)"
  end

  # I-01 refusal path
  test "an approval that would exceed the budget is refused" do
    budget = budgets(:current_travel) # 100_000 cap, 30_000 used
    big = Expense.create!(user: users(:jiro), category: categories(:travel),
                          used_on: Time.zone.today, amount: 80_000,
                          purpose: "高額", status: :submitted, submitted_at: Time.current)
    assert_raises ApproveExpense::Refused do
      ApproveExpense.call(expense_id: big.id, approver: users(:hanako))
    end
    assert_equal 30_000, budget.reload.approved_total
  end

  # I-07 — one bucketing method, and it uses the app timezone
  test "an expense is charged to the month of its used_on" do
    e = expenses(:taro_draft)
    e.used_on = Date.new(2026, 3, 31)
    assert_equal Date.new(2026, 3, 1), e.year_month
  end
end
```

```ruby
# test/models/concurrent_approval_test.rb
require "test_helper"

# The D-05 proof. Two real connections, so transactional tests must be off:
# each thread has to see the other thread's committed rows.
class ConcurrentApprovalTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @team     = Team.create!(name: "Race #{SecureRandom.hex(4)}")
    @approver = User.create!(name: "承認者", email: "race-a-#{SecureRandom.hex(4)}@example.com",
                             password: "password", role: :approver, team: @team)
    @team.update!(approver: @approver)
    @member   = User.create!(name: "申請者", email: "race-m-#{SecureRandom.hex(4)}@example.com",
                             password: "password", role: :member, team: @team)
    @category = Category.create!(name: "Race #{SecureRandom.hex(4)}")
    @budget   = Budget.create!(team: @team, category: @category,
                               year_month: MonthBucket.current, amount: 10_000)
    @first, @second = 2.times.map do |i|
      Expense.create!(user: @member, category: @category, used_on: Time.zone.today,
                      amount: 6_000, purpose: "race #{i}", status: :submitted,
                      submitted_at: Time.current)
    end
  end

  teardown do
    Expense.where(id: [@first.id, @second.id]).delete_all
    Budget.where(id: @budget.id).delete_all
    @team.update_columns(approver_id: nil)
    User.where(id: [@approver.id, @member.id]).delete_all
    Team.where(id: @team.id).delete_all
    Category.where(id: @category.id).delete_all
  end

  test "two simultaneous approvals can never overspend one budget" do
    gate = Concurrent::CyclicBarrier.new(2)
    outcomes = Queue.new

    [@first, @second].map { |expense|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.wait # both threads enter the transaction at the same moment
          begin
            ApproveExpense.call(expense_id: expense.id, approver: @approver)
            outcomes << :approved
          rescue ApproveExpense::Refused, ActiveRecord::StatementInvalid,
                 ActiveRecord::Deadlocked
            outcomes << :refused
          end
        end
      end
    }.each(&:join)

    results = Array.new(outcomes.size) { outcomes.pop }

    assert_equal 1, results.count(:approved), "exactly one approval may win"
    assert_equal 1, results.count(:refused),  "the second must be refused, not queued"

    @budget.reload
    assert_equal 6_000, @budget.approved_total
    assert_operator @budget.approved_total, :<=, @budget.amount, "I-01 must hold"
    assert_equal @budget.approved_sum, @budget.approved_total, "counter must not drift"
    assert_equal 1, Expense.approved.where(id: [@first.id, @second.id]).count
  end
end
```

<aside>
🧪

**Make this test earn its place.** Comment out the two `.lock` calls and re-run: it should go red with `approved_total == 12_000` — or, if the `CHECK` catches it, with a `StatementInvalid`. Screenshot both runs. That before/after pair *is* the D-05 slide.

</aside>

## 5. Slice 1 — signup / login / logout (1.5h)

**Auth approach: `has_secure_password` + bcrypt + `session[:user_id]`** (D-09). Rejected: Devise (a whole gem's semantics to explain for three actions) and Rails 8's `bin/rails generate authentication` (generates a `Session` model and password-reset mailers you do not need, and would collide with the `User` you just designed). REQUIREMENTS §7 already puts real authentication out of scope — the graded value is the budget invariant.

```ruby
# Gemfile — uncomment the line rails new already left for you
gem "bcrypt", "~> 3.1.7"
```

```bash
bundle install
docker compose build web   # the Gemfile changed, so the image must be rebuilt
```

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "sessions#new"

  get    "signup", to: "users#new",       as: :signup
  post   "signup", to: "users#create"
  get    "login",  to: "sessions#new",    as: :login
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "up", to: "rails/health#show", as: :rails_health_check
end
```

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
    before_action :require_sign_in
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_sign_in, **options
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in?
    current_user.present?
  end

  def require_sign_in
    redirect_to login_path, alert: "ログインしてください" unless signed_in?
  end

  def sign_in(user)
    reset_session # fixation guard: new session id, then store the user
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    reset_session
    @current_user = nil
  end
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
end
```

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to login_path, notice: "ログアウトしました"
  end
end
```

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in(@user)
      redirect_to root_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[name email password password_confirmation role team_id])
  end
end
```

<aside>
🩹

**Accepted debt, log it as B-02 today.** `role` is permitted from signup params, so anyone can self-register as 承認者. That is fine for a dummy-data demo and required by "register メンバー and 承認者", but say so out loud in the README and the presentation rather than letting a reviewer find it. The real fix (invite-only approver creation) belongs in §10 out of scope.

</aside>

```
<%# app/views/layouts/application.html.erb — body only %>
<body class="min-h-screen bg-slate-50 text-slate-900">
  <header class="flex items-center justify-between bg-white px-6 py-3 shadow-sm">
    <a href="<%= root_path %>" class="font-semibold">経費申請</a>
    <% if signed_in? %>
      <div class="flex items-center gap-4 text-sm">
        <span class="text-slate-600">
          <%= current_user.name %>（<%= current_user.approver? ? "承認者" : "メンバー" %>）
        </span>
        <%= button_to "ログアウト", logout_path, method: :delete,
              class: "rounded-md border px-3 py-1 hover:bg-slate-100" %>
      </div>
    <% end %>
  </header>

  <% if flash.any? %>
    <div class="mx-auto mt-4 max-w-xl space-y-2">
      <% flash.each do |type, message| %>
        <p class="rounded-md px-4 py-2 text-sm <%= type.to_s == "alert" ? "bg-red-50 text-red-700" : "bg-emerald-50 text-emerald-700" %>">
          <%= message %>
        </p>
      <% end %>
    </div>
  <% end %>

  <main class="mx-auto max-w-xl px-6 py-10"><%= yield %></main>
</body>
```

```
<%# app/views/sessions/new.html.erb %>
<h1 class="mb-6 text-2xl font-semibold">ログイン</h1>

<%= form_with url: login_path, class: "space-y-4 rounded-lg bg-white p-6 shadow-sm" do |f| %>
  <div>
    <%= f.label :email, "メールアドレス", class: "block text-sm font-medium" %>
    <%= f.email_field :email, required: true,
          class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <div>
    <%= f.label :password, "パスワード", class: "block text-sm font-medium" %>
    <%= f.password_field :password, required: true,
          class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <%= f.submit "ログイン",
        class: "w-full rounded-md bg-slate-900 px-4 py-2 text-white hover:bg-slate-700" %>
<% end %>

<p class="mt-4 text-sm text-slate-600">
  アカウントがない場合は <%= link_to "新規登録", signup_path, class: "underline" %>
</p>
```

```
<%# app/views/users/new.html.erb %>
<h1 class="mb-6 text-2xl font-semibold">新規登録</h1>

<%= form_with model: @user, url: signup_path,
      class: "space-y-4 rounded-lg bg-white p-6 shadow-sm" do |f| %>
  <% if @user.errors.any? %>
    <ul class="list-disc rounded-md bg-red-50 p-4 pl-8 text-sm text-red-700">
      <% @user.errors.full_messages.each do |message| %><li><%= message %></li><% end %>
    </ul>
  <% end %>

  <div>
    <%= f.label :name, "氏名", class: "block text-sm font-medium" %>
    <%= f.text_field :name, class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <div>
    <%= f.label :email, "メールアドレス", class: "block text-sm font-medium" %>
    <%= f.email_field :email, class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <div>
    <%= f.label :team_id, "所属チーム", class: "block text-sm font-medium" %>
    <%= f.collection_select :team_id, Team.order(:name), :id, :name, {},
          class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <div>
    <%= f.label :role, "ロール", class: "block text-sm font-medium" %>
    <%= f.select :role, User.roles.keys.map { |r| [r == "approver" ? "承認者" : "メンバー", r] },
          {}, class: "mt-1 w-full rounded-md border-slate-300" %>
  </div>
  <div class="grid grid-cols-2 gap-4">
    <div>
      <%= f.label :password, "パスワード", class: "block text-sm font-medium" %>
      <%= f.password_field :password, class: "mt-1 w-full rounded-md border-slate-300" %>
    </div>
    <div>
      <%= f.label :password_confirmation, "確認", class: "block text-sm font-medium" %>
      <%= f.password_field :password_confirmation,
            class: "mt-1 w-full rounded-md border-slate-300" %>
    </div>
  </div>
  <%= f.submit "登録",
        class: "w-full rounded-md bg-slate-900 px-4 py-2 text-white hover:bg-slate-700" %>
<% end %>
```

```ruby
# test/integration/authentication_flow_test.rb
require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "an unauthenticated visitor is sent to the login screen" do
    get root_path
    assert_redirected_to login_path
  end

  test "signup then logout then login again" do
    assert_difference -> { User.count }, 1 do
      post signup_path, params: { user: {
        name: "三郎", email: "Saburo@Example.com ", team_id: teams(:alpha).id,
        role: "member", password: "password", password_confirmation: "password"
      } }
    end
    assert_equal "saburo@example.com", User.last.email, "email is normalised"
    follow_redirect!
    assert_response :success

    delete logout_path
    assert_redirected_to login_path

    post login_path, params: { email: "saburo@example.com", password: "password" }
    assert_redirected_to root_path
  end

  test "a wrong password is rejected without revealing which field was wrong" do
    post login_path, params: { email: users(:taro).email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end
end
```

```ruby
# db/seeds.rb — dummy data only, idempotent
%w[交通費 書籍費 会議費].each { |name| Category.find_or_create_by!(name: name) }

team = Team.find_or_create_by!(name: "福岡開発チーム")

approver = User.find_or_initialize_by(email: "approver@example.com")
approver.update!(name: "承認 花子", role: :approver, team: team,
                 password: "password", password_confirmation: "password")
team.update!(approver: approver)

[["member1@example.com", "申請 太郎"], ["member2@example.com", "申請 次郎"]].each do |email, name|
  user = User.find_or_initialize_by(email: email)
  user.update!(name: name, role: :member, team: team,
               password: "password", password_confirmation: "password")
end

Category.find_each do |category|
  Budget.find_or_create_by!(team: team, category: category,
                            year_month: MonthBucket.current) do |budget|
    budget.amount = 100_000
  end
end

puts "demo accounts: approver@example.com / member1@example.com / member2@example.com (password: password)"
```

## 6. Order to run it in

```bash
docker compose up -d
docker compose exec web bin/rails db:create db:migrate
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails test
docker compose exec web bin/rails db:migrate:redo   # proves every migration is reversible
```

## 7. Clean-clone verification (30 min)

```bash
#!/usr/bin/env bash
# script/verify_clean_clone.sh — run from the repo root
set -euo pipefail

REPO_URL="${1:-$(git config --get remote.origin.url)}"
WORKDIR="$(mktemp -d)"

echo "==> cloning into $WORKDIR"
git clone --depth 1 "$REPO_URL" "$WORKDIR/app"
cd "$WORKDIR/app"

# 1. nothing outside the repo may be required
test ! -f .env || echo "WARNING: .env is committed"

echo "==> docker compose up --build"
docker compose up --build -d

echo "==> waiting for :3000"
for i in $(seq 1 60); do
  if curl -fsS -o /dev/null http://localhost:3000/up; then break; fi
  sleep 2
  [ "$i" -eq 60 ] && { docker compose logs --tail 100; exit 1; }
done

docker compose exec -T web bin/rails db:prepare db:seed

# 2. the login screen renders
curl -fsS http://localhost:3000/login | grep -q "ログイン" \
  && echo "OK: login screen renders"

# 3. Tailwind is actually built and served (not just referenced)
CSS_PATH=$(curl -fsS http://localhost:3000/login \
  | grep -o '/assets/tailwind/tailwind[^"]*\.css' | head -1)
test -n "$CSS_PATH" || { echo "FAIL: no Tailwind stylesheet in the HTML"; exit 1; }
curl -fsS "http://localhost:3000${CSS_PATH}" | grep -q -- '--tw-\|\.rounded-md' \
  && echo "OK: Tailwind CSS served from ${CSS_PATH}"

# 4. the suite passes inside the container
docker compose exec -T web bin/rails test

echo "==> tearing down"
docker compose down -v
rm -rf "$WORKDIR"
echo "CLEAN CLONE VERIFIED"
```

<aside>
🔍

**Why grep the CSS file and not just the `NOTION_MARKDOWN_ESCAPED_LT_SENTINELlink&gt;` tag.** The most common Docker failure with `tailwindcss-rails` is an image that ships the HTML reference but never ran `rails tailwindcss:build`, so the page loads unstyled and the stylesheet 404s. Asserting the served file contains a real utility class is what makes this check meaningful — and it is exactly the failure that would embarrass you on Day 8 in the deployed environment.

If the CSS path differs in your setup, print it once with `curl -s http://localhost:3000/login | grep -o 'href="[^"]*css[^"]*"'` and adjust the pattern.

</aside>

## 8. The manager conversation about Q-11 (do this today)

Q-11 is the only item that can consume calendar time you do not control, so it needs to be asked today rather than discovered on Day 7. Keep it to five minutes and bring a proposal, not a question.

**What to say**

1. The assignment requires a publicly deployed app. I am on Day 2 of 8 and I want to make the hosting decision before the Day 6 feature freeze, so deployment is not the thing that breaks the deadline.
2. The app is a Rails 8 + MySQL 9 container, dummy data only, no real personal or company data.
3. My default plan, unless you tell me otherwise, is a free tier on Render or Fly.io with a managed MySQL-compatible database, paid for by nobody and torn down after the presentation.

**What I need answers to**

- Is there a company-provided place I am expected to deploy to, or is an external free tier acceptable?
- If external: whose account and billing does it go under, and is there an approval or security-review step? How long does that take?
- Is a public URL required, or is a screen recording plus a locally reproducible `docker compose up` acceptable as a fallback?
- Any constraint on where dummy data may live (region, VPN, SSO)?

**How to close it**

> "If I do not hear back by end of Day 4, I will proceed with the free tier under my own account and note it as a decision I can reverse."
> 

That sentence converts a blocker into a dated decision, which is exactly what R-01 in State §9 asks for. Record the outcome as **D-11** whichever way it goes — including "we decided to wait", because a deferral with a date is a decision.

## 9. What is still unverified after today

| Item | Why it matters | How to close it |
| --- | --- | --- |
| Every code block on this page | Written, never executed | §6, then §7 |
| `CHECK` constraint error messages | The tests `assert_match` on constraint names; MySQL 9 wording may differ | Run once, paste the real message, adjust the assertion |
| `Concurrent::CyclicBarrier` availability | It ships with `concurrent-ruby` via Active Support, but confirm rather than assume | First run of the concurrency test |
| Fixture loading with the `users` ↔ `teams` cycle | Rails disables FK checks while loading fixtures, so this should work | First run of any fixture-using test |
| `db:migrate:redo` reversibility | `add_check_constraint` is reversible, but prove it | §6 last line |
| **Fixture consistency with `approved_total`** | RESOLVED 2026-09-09. First green run left 1 failure: `budgets(:current_travel).approved_total` was 30000 with no approved expense rows behind it, so the D-04 reconciliation assertion failed (expected 35000, actual 5000). The assertion was right; the fixture was impossible. Added `expenses(:taro_approved)` | Standing rule: every yen in a budget fixture's `approved_total` needs matching 承認済み expense rows |
| **Deprecated APIs in pasted code** | RESOLVED 2026-09-09. `Time.current.to_s(:db)` in the expenses fixture raised `ArgumentError: wrong number of arguments (given 1, expected 0)` on Rails 8.1 — `to_s(format)` was removed in Rails 7, replaced by `to_fs` | Fixed. Watch for the same class of error in `params.expect` and keyword `enum` on the next run |
| **The `year_month` "1st of month" CHECK** | RESOLVED 2026-09-09. Failed on MySQL 9.0.1 as both `DAYOFMONTH(year_month)` and `EXTRACT(DAY FROM year_month)` — error 1064 pointing at the identifier, not the function. Cause: `YEAR_MONTH` is a MySQL reserved word (INTERVAL unit). Fix: backtick-quote the column inside the CHECK string | Rule: any raw SQL string in a migration that names `year_month` must backtick it. Applies to future CHECKs and any `where("...")` raw fragments |
| Tailwind in the production image | Dev works via `bin/dev`; the prod image needs its own CSS build step | §7 check 3, and again after the Day 8 deploy |